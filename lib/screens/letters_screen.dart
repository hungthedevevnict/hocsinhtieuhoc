import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';
import '../widgets/mic_check.dart';

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
    TtsService.instance.speak('${item.sound}. ${item.exampleWord}');
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

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      color: AppColors.letters,
      title: 'Học Chữ Cái',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          Container(
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
          const SizedBox(height: 16),
          // Bé đọc theo từ ví dụ.
          MicCheck(target: item.exampleWord, color: color, size: 60),
        ],
      ),
    );
  }
}
