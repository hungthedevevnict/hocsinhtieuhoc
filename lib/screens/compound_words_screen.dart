import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/app_data.dart';
import '../data/custom_words_store.dart';
import '../services/ai_key_store.dart';
import '../services/ai_vision_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';
import '../widgets/mic_check.dart';
import 'add_compound_word_screen.dart';

class CompoundWordsScreen extends StatefulWidget {
  const CompoundWordsScreen({super.key});

  @override
  State<CompoundWordsScreen> createState() => _CompoundWordsScreenState();
}

class _CompoundWordsScreenState extends State<CompoundWordsScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  List<CompoundWord> _custom = [];
  bool _busy = false;

  static const Color _teal = AppColors.compound;
  static const Color _tealDark = Color(0xFF00949E);

  List<CompoundWord> get _all => [...compoundWords, ..._custom];
  bool _isCustom(int i) => i >= compoundWords.length;

  @override
  void initState() {
    super.initState();
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final words = await CustomWordsStore.instance.load();
    if (mounted) setState(() => _custom = words);
  }

  @override
  void dispose() {
    _controller.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  CompoundWord get _word => _all[_index.clamp(0, _all.length - 1)];

  void _spellWhole() {
    final parts = <String>[];
    for (final s in _word.syllables) {
      parts.addAll(s.spellParts);
    }
    parts.add(_word.word);
    TtsService.instance.speakSequence(parts, gap: const Duration(milliseconds: 260));
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _all.length) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _openAddScreen() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCompoundWordScreen()),
    );
    if (added == true) await _loadCustom();
  }

  Future<void> _deleteCustom(int allIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá từ này?'),
        content: Text('Bỏ "${_all[allIndex].word}" khỏi danh sách nhé?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed != true) return;
    await CustomWordsStore.instance.removeAt(allIndex - compoundWords.length);
    await _loadCustom();
    if (mounted) setState(() => _index = _index.clamp(0, _all.length - 1));
  }

  Future<void> _pickPhotoAndExtract() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? file;
    try {
      file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      _showMessage('Không mở được camera/thư viện ảnh.');
      return;
    }
    if (file == null) return;

    final apiKey = await AiKeyStore.instance.getKey();
    if (apiKey == null) {
      final entered = await _askApiKey();
      if (entered != true) return;
    }

    final bytes = await file.readAsBytes();
    await _extractAndSave(bytes);
  }

  Future<bool?> _askApiKey() async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nhập ShopAIKey'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dán API key (dạng sk-...) để dùng tính năng chụp ảnh nhận diện từ. Key chỉ lưu trên máy bạn.'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'sk-...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isNotEmpty),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result == true && ctrl.text.trim().isNotEmpty) {
      await AiKeyStore.instance.setKey(ctrl.text.trim());
      return true;
    }
    return false;
  }

  Future<void> _extractAndSave(Uint8List bytes) async {
    setState(() => _busy = true);
    try {
      final words = await AiVisionService.instance.extractCompoundWords(bytes);
      if (words.isEmpty) {
        _showMessage('AI không tìm được từ phù hợp trong ảnh này. Thử ảnh rõ hơn nhé!');
      } else {
        await CustomWordsStore.instance.addAll(words);
        await _loadCustom();
        _showMessage('🎉 Đã thêm ${words.length} từ mới: ${words.map((w) => w.word).join(', ')}');
        setState(() => _index = _all.length - 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.hasClients) {
            _controller.jumpToPage(_index);
          }
        });
      }
    } on AiVisionException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Có lỗi khi gọi AI: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, maxLines: 6),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_all.isEmpty) {
      return const KidScaffold(
        color: _teal,
        title: 'Từ Ghép',
        body: Center(child: CircularProgressIndicator(color: _tealDark)),
      );
    }
    return Stack(
      children: [
        KidScaffold(
          color: _teal,
          title: 'Từ Ghép',
          actions: [
            KidAppBarAction(Icons.add_rounded, _openAddScreen),
            KidAppBarAction(Icons.camera_alt_rounded, _pickPhotoAndExtract),
          ],
          body: Column(
            children: [
              Text(
                '${_index + 1} / ${_all.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink.withValues(alpha: 0.55),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _all.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    TtsService.instance.speak(_all[i].word);
                  },
                  itemBuilder: (_, i) => _WordCard(
                    word: _all[i],
                    isCustom: _isCustom(i),
                    onDelete: () => _deleteCustom(i),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    KidButton(
                      label: 'Trước',
                      icon: Icons.chevron_left_rounded,
                      color: _index == 0 ? Colors.grey.shade400 : AppColors.tones,
                      fontSize: 16,
                      onTap: () => _go(-1),
                    ),
                    KidButton(
                      label: 'Đánh vần',
                      icon: Icons.hearing_rounded,
                      color: _tealDark,
                      fontSize: 18,
                      onTap: _spellWhole,
                    ),
                    KidButton(
                      label: 'Sau',
                      icon: Icons.chevron_right_rounded,
                      color: _index == _all.length - 1
                          ? Colors.grey.shade400
                          : AppColors.tones,
                      fontSize: 16,
                      onTap: () => _go(1),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: MicCheck(target: _word.word, color: AppColors.sunny, size: 58),
              ),
            ],
          ),
        ),
        if (_busy)
          Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Đang nhờ AI đọc ảnh...',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WordCard extends StatelessWidget {
  final CompoundWord word;
  final bool isCustom;
  final VoidCallback onDelete;
  const _WordCard({
    required this.word,
    required this.isCustom,
    required this.onDelete,
  });

  static const Color _tealDark = Color(0xFF00949E);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(word.emoji, style: const TextStyle(fontSize: 76)),
              if (isCustom) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.letters.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: AppColors.letters, size: 22),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < word.syllables.length; i++) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('+',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.black26)),
                  ),
                _SyllableChip(spec: word.syllables[i]),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5DDEEA), _tealDark],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: _tealDark.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  word.syllables.map((s) => s.spellParts.join(' - ')).join('  ·  '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyllableChip extends StatelessWidget {
  final SyllableSpec spec;
  const _SyllableChip({required this.spec});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TtsService.instance.speakSequence(spec.spellParts),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.compound, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          spec.syllable,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: AppColors.compound,
          ),
        ),
      ),
    );
  }
}
