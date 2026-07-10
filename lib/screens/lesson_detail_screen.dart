import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../data/lesson_store.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';
import 'lesson_review_screen.dart';

/// Xem lại 1 bài đã lưu: đánh vần từng từ, nghe, đọc theo, xoá từ nếu cần.
class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  late List<CompoundWord> _words;

  static const Color _teal = AppColors.compound;
  static const Color _tealDark = Color(0xFF00949E);

  @override
  void initState() {
    super.initState();
    _words = List<CompoundWord>.from(widget.lesson.words);
  }

  @override
  void dispose() {
    _controller.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  CompoundWord get _word => _words[_index.clamp(0, _words.length - 1)];

  void _spellWhole() {
    final parts = <String>[];
    for (final s in _word.syllables) {
      parts.addAll(s.spellParts);
    }
    parts.add(_word.word);
    TtsService.instance.speakSequence(parts, gap: const Duration(milliseconds: 260));
  }

  void _openReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonReviewScreen(
          lessonId: widget.lesson.id,
          title: widget.lesson.title,
          words: _words,
        ),
      ),
    );
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0) return;
    if (next >= _words.length) {
      // Đọc hết bài rồi — tự chuyển sang Kiểm tra.
      if (delta > 0) _openReview();
      return;
    }
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _deleteWord(int i) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá từ này?'),
        content: Text('Bỏ "${_words[i].word}" khỏi bài nhé?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (confirmed != true) return;
    await LessonsStore.instance.removeWord(widget.lesson.id, i);
    setState(() {
      _words.removeAt(i);
      _index = _index.clamp(0, _words.isEmpty ? 0 : _words.length - 1);
    });
    if (_words.isEmpty && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return KidScaffold(
        color: _teal,
        title: widget.lesson.title,
        body: Center(
          child: Text(
            widget.lesson.letter.isNotEmpty
                ? 'Bài chữ ${widget.lesson.letter} chưa có từ nào.\nBấm ➕ ở Bài Học để gõ thêm từ nhé.'
                : 'Bài này chưa có từ nào.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return KidScaffold(
      color: _teal,
      title: widget.lesson.title,
      actions: [
        KidAppBarAction(Icons.grid_view_rounded, _openReview),
      ],
      body: Column(
        children: [
          Text(
            '${_index + 1} / ${_words.length}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink.withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _words.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                TtsService.instance.speak(_words[i].word);
              },
              itemBuilder: (_, i) => _WordCard(
                word: _words[i],
                onDelete: () => _deleteWord(i),
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
                  label: _index == _words.length - 1 ? 'Kiểm tra' : 'Sau',
                  icon: _index == _words.length - 1
                      ? Icons.fact_check_rounded
                      : Icons.chevron_right_rounded,
                  color: AppColors.tones,
                  fontSize: 16,
                  onTap: () => _go(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final CompoundWord word;
  final VoidCallback onDelete;
  const _WordCard({required this.word, required this.onDelete});

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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.letters.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_rounded, color: AppColors.letters, size: 22),
                ),
              ),
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
                            fontSize: 30, fontWeight: FontWeight.w900, color: Colors.black26)),
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
