import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';

class LettersScreen extends StatefulWidget {
  const LettersScreen({super.key});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  Color get _color => AppColors.tileColors[_index % AppColors.tileColors.length];

  @override
  void initState() {
    super.initState();
    // Đọc chữ đầu tiên sau khi mở màn hình.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak(alphabet[0]));
  }

  @override
  void dispose() {
    _controller.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  void _speak(LetterItem item) {
    // Đọc chậm, tách rõ: âm chữ cái ... nghỉ ... từ ví dụ ... nghỉ ... từ ghép.
    TtsService.instance.speakSequence(
      [item.sound, item.exampleWord, item.compoundWord],
      rate: 0.32,
      gap: const Duration(milliseconds: 650),
    );
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= alphabet.length) return;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  /// Nhảy thẳng tới 1 chữ (không lướt qua từng chữ ở giữa).
  void _jumpTo(int index) {
    _controller.jumpToPage(index);
    setState(() => _index = index);
    _speak(alphabet[index]);
  }

  Future<void> _openPicker() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LetterPickerSheet(currentIndex: _index),
    );
    if (picked != null) _jumpTo(picked);
  }

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      color: AppColors.letters,
      title: 'Học Chữ Cái',
      actions: [
        KidAppBarAction(Icons.grid_view_rounded, _openPicker),
      ],
      body: Column(
        children: [
          Text(
            '${_index + 1} / ${alphabet.length}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: alphabet.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _speak(alphabet[i]);
              },
              itemBuilder: (_, i) => _LetterCard(
                item: alphabet[i],
                color: AppColors.tileColors[i % AppColors.tileColors.length],
                onTapLetter: () => _speak(alphabet[i]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                KidButton(
                  label: 'Trước',
                  icon: Icons.chevron_left_rounded,
                  color: _index == 0
                      ? Colors.grey.shade400
                      : AppColors.sunny,
                  onTap: () => _go(-1),
                ),
                KidButton(
                  label: 'Nghe',
                  icon: Icons.volume_up_rounded,
                  color: _color,
                  onTap: () => _speak(alphabet[_index]),
                ),
                KidButton(
                  label: 'Sau',
                  icon: Icons.chevron_right_rounded,
                  color: _index == alphabet.length - 1
                      ? Colors.grey.shade400
                      : AppColors.sunny,
                  onTap: () => _go(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final LetterItem item;
  final Color color;
  final VoidCallback onTapLetter;
  const _LetterCard({
    required this.item,
    required this.color,
    required this.onTapLetter,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTapLetter,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${item.upper}${item.lower}',
                style: const TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tên chữ: ${item.name}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.ink.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => TtsService.instance.speak(item.exampleWord),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(width: 14),
                  Text(
                    item.exampleWord,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => TtsService.instance.speak(item.compoundWord),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 2),
              ),
              child: Text(
                'Từ ghép: ${item.compoundWord}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Bảng đầy đủ 29 chữ cái để chọn nhanh, thay vì bấm "Sau" từng chữ một.
class _LetterPickerSheet extends StatelessWidget {
  final int currentIndex;
  const _LetterPickerSheet({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn chữ muốn học',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: alphabet.length,
                itemBuilder: (_, i) {
                  final selected = i == currentIndex;
                  final color = AppColors.tileColors[i % AppColors.tileColors.length];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? color : color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: selected ? null : Border.all(color: color, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        alphabet[i].upper,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: selected ? Colors.white : color,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
