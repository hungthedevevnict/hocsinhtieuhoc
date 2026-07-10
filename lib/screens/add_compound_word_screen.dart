import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../data/lesson_store.dart';
import '../data/syllable_parser.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';

/// Cho bố mẹ gõ tay nhiều từ ghép, mỗi dòng 1 từ (2 tiếng), đặt tên cho cả
/// bài rồi lưu 1 lần. Vd gõ:
///   bờ đê
///   cá rô 🐟
///   ba mẹ
class AddCompoundWordScreen extends StatefulWidget {
  /// Nội dung có sẵn để điền vào ô nhập từ (vd chữ AI vừa đọc từ ảnh),
  /// bố mẹ xem lại, sửa/thêm rồi mới lưu — không tự lưu ngầm.
  final String? initialText;
  final String? initialTitle;
  const AddCompoundWordScreen({super.key, this.initialText, this.initialTitle});

  @override
  State<AddCompoundWordScreen> createState() => _AddCompoundWordScreenState();
}

class _AddCompoundWordScreenState extends State<AddCompoundWordScreen> {
  late final TextEditingController _wordsCtrl;
  late final TextEditingController _titleCtrl;
  bool _saving = false;
  String? _lessonId; // set sau lần lưu đầu tiên, để lần lưu sau cộng vào cùng bài

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _wordsCtrl = TextEditingController(text: widget.initialText ?? '');
    _titleCtrl = TextEditingController(
      text: widget.initialTitle ?? 'Bài ${now.day}/${now.month}',
    );
  }

  @override
  void dispose() {
    _wordsCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lines = _wordsCtrl.text.split('\n');
    final goodWords = <CompoundWord>[];
    final failedLines = <String>[];
    final remainingLines = <String>[];

    for (final line in lines) {
      final result = parseCompoundWordLine(line);
      if (result.word != null) {
        goodWords.add(result.word!);
      } else if (result.error != null) {
        failedLines.add(line.trim());
        remainingLines.add(line);
      }
      // dòng trống: bỏ qua, không giữ lại trong ô nhập.
    }

    if (goodWords.isEmpty && failedLines.isEmpty) {
      _showMessage('Gõ ít nhất 1 từ nhé, mỗi dòng 2 tiếng (vd: bờ đê).');
      return;
    }

    setState(() => _saving = true);
    if (goodWords.isNotEmpty) {
      if (_lessonId == null) {
        final lesson = await LessonsStore.instance.addLesson(_titleCtrl.text, goodWords);
        _lessonId = lesson.id;
      } else {
        await LessonsStore.instance.appendWords(_lessonId!, goodWords);
      }
    }
    setState(() {
      _saving = false;
      _wordsCtrl.text = remainingLines.join('\n');
    });

    if (!mounted) return;

    if (failedLines.isEmpty) {
      Navigator.of(context).pop(true);
    } else {
      _showMessage(
        '${goodWords.isNotEmpty ? "Đã lưu ${goodWords.length} từ vào bài. " : ""}'
        'Còn ${failedLines.length} dòng chưa hiểu, sửa lại rồi bấm Lưu tiếp nhé.',
      );
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      color: AppColors.compound,
      title: 'Thêm Từ Ghép',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              enabled: _lessonId == null,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                labelText: 'Tên bài',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mỗi dòng gõ 1 từ, đủ 2 tiếng cách nhau bằng dấu cách. '
              'Thêm emoji ở cuối dòng cũng được (không bắt buộc).',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.compound.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'bờ đê\ncá rô 🐟\nba mẹ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.compound,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: _wordsCtrl,
                autofocus: widget.initialText == null,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'bờ đê\ncá rô\nba mẹ\n...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: Center(
                child: KidButton(
                  label: _saving ? 'Đang lưu...' : 'Lưu bài này',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.words,
                  onTap: _saving ? () {} : _save,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
