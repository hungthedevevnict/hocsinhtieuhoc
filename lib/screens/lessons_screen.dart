import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/lesson_store.dart';
import '../services/ai_key_store.dart';
import '../services/ai_vision_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';
import 'add_compound_word_screen.dart';
import 'lesson_detail_screen.dart';

/// Danh sách các bài đã lưu (gõ tay hoặc chụp ảnh AI đọc). Bấm vào 1 bài
/// để mở lại và luyện đánh vần từ ghép trong bài đó.
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  List<Lesson>? _lessons; // null = đang tải
  bool _busy = false;

  static const Color _teal = AppColors.compound;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessons = await LessonsStore.instance.load();
    if (mounted) setState(() => _lessons = lessons);
  }

  Future<void> _openAddScreen() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddCompoundWordScreen()),
    );
    if (added == true) await _load();
  }

  Future<void> _openLesson(Lesson lesson) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
    );
    await _load(); // cập nhật lại nếu có từ bị xoá trong bài
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá bài này?'),
        content: Text('Bỏ "${lesson.title}" (${lesson.words.length} từ) khỏi danh sách nhé?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed != true) return;
    await LessonsStore.instance.removeLesson(lesson.id);
    await _load();
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
      file = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    } catch (_) {
      _showMessage('Không mở được camera/thư viện ảnh.');
      return;
    }
    if (file == null) return;

    final apiKey = await AiKeyStore.instance.getKey();
    if (apiKey == null) {
      _showMessage('Chưa có API key. Dán key vào file secrets.env rồi build lại app nhé.');
      return;
    }

    final bytes = await file.readAsBytes();
    await _extractAndReview(bytes);
  }

  /// AI chỉ đọc chữ thô trong ảnh, KHÔNG tự lưu — mở màn gõ tay đã điền sẵn
  /// để bố mẹ xem lại, sửa/thêm rồi mới đặt tên bài và lưu.
  Future<void> _extractAndReview(Uint8List bytes) async {
    setState(() => _busy = true);
    List<String> lines = const [];
    try {
      lines = await AiVisionService.instance.extractWordLines(bytes);
    } on AiVisionException catch (e) {
      _showMessage(e.message);
      return;
    } catch (e) {
      _showMessage('Có lỗi khi gọi AI: $e');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (lines.isEmpty) {
      _showMessage('AI không đọc được chữ nào trong ảnh này. Thử ảnh rõ hơn nhé!');
      return;
    }
    if (!mounted) return;

    final now = DateTime.now();
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddCompoundWordScreen(
          initialTitle: 'Bài chụp ${now.day}/${now.month}',
          initialText: lines.join('\n'),
        ),
      ),
    );
    if (added == true) await _load();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg, maxLines: 6),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _lessons;
    return Stack(
      children: [
        KidScaffold(
          color: _teal,
          title: 'Từ Ghép',
          actions: [
            KidAppBarAction(Icons.add_rounded, _openAddScreen),
            // Chụp ảnh AI chỉ có trên bản điện thoại (web bị chặn CORS + không kèm key).
            if (!kIsWeb) KidAppBarAction(Icons.camera_alt_rounded, _pickPhotoAndExtract),
          ],
          body: lessons == null
              ? const Center(child: CircularProgressIndicator(color: _teal))
              : lessons.isEmpty
                  ? _EmptyState(onAdd: _openAddScreen, onPhoto: _pickPhotoAndExtract)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: lessons.length,
                      itemBuilder: (_, i) => _LessonCard(
                        lesson: lessons[i],
                        onTap: () => _openLesson(lessons[i]),
                        onDelete: () => _deleteLesson(lessons[i]),
                      ),
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
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onPhoto;
  const _EmptyState({required this.onAdd, required this.onPhoto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📚', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? 'Chưa có bài nào.\nBấm ➕ để gõ thêm từ ghép nhé.'
                  : 'Chưa có bài nào.\nBấm ➕ để gõ tay, hoặc 📷 để chụp ảnh bài học.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KidButton(label: 'Gõ tay', icon: Icons.edit_rounded, color: AppColors.blending, onTap: onAdd),
                if (!kIsWeb) ...[
                  const SizedBox(width: 14),
                  KidButton(label: 'Chụp ảnh', icon: Icons.camera_alt_rounded, color: AppColors.sunny, onTap: onPhoto),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _LessonCard({required this.lesson, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final preview = lesson.words.take(4).map((w) => w.emoji).join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.compound,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lesson.words.length} từ  ·  ${lesson.createdAt.day}/${lesson.createdAt.month}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink.withValues(alpha: 0.5),
                        ),
                      ),
                      if (preview.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(preview, style: const TextStyle(fontSize: 22)),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.letters.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_rounded, color: AppColors.letters, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
