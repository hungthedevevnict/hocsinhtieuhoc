import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  final Random _rng = Random();
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 1));

  late WordItem _answer;
  late List<WordItem> _options;
  int? _pickedIndex;
  bool _correct = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => TtsService.instance.speak('Đây là từ gì?'));
  }

  @override
  void dispose() {
    _confetti.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  void _newQuestion() {
    final pool = List<WordItem>.from(pictureWords)..shuffle(_rng);
    _answer = pool.first;
    final distractors = pool.skip(1).take(2).toList();
    _options = [_answer, ...distractors]..shuffle(_rng);
    _pickedIndex = null;
    _correct = false;
  }

  void _pick(int index) {
    if (_correct) return; // đã trả lời đúng, chờ sang câu mới
    final chosen = _options[index];
    setState(() {
      _pickedIndex = index;
      _correct = chosen.word == _answer.word;
    });
    if (_correct) {
      _confetti.play();
      final praise = praises[_rng.nextInt(praises.length)];
      TtsService.instance.speakSequence(
        [praise, _answer.word],
        gap: const Duration(milliseconds: 220),
      );
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(_newQuestion);
      });
    } else {
      TtsService.instance.speak(chosen.word);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      color: AppColors.words,
      title: 'Đọc Từ',
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'Đây là từ gì?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.words,
                ),
              ),
              const SizedBox(height: 8),
              // Hình minh hoạ to.
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () =>
                        TtsService.instance.speak('Đây là từ gì?'),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.words.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _answer.emoji,
                        style: const TextStyle(fontSize: 120),
                      ),
                    ),
                  ),
                ),
              ),
              // 3 lựa chọn.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  children: [
                    for (var i = 0; i < _options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionButton(
                          word: _options[i].word,
                          state: _stateFor(i),
                          onTap: () => _pick(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Pháo hoa khi đúng.
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.3,
              colors: AppColors.tileColors,
            ),
          ),
        ],
      ),
    );
  }

  _OptionState _stateFor(int i) {
    if (_pickedIndex == null) return _OptionState.normal;
    if (i == _pickedIndex) {
      return _correct ? _OptionState.correct : _OptionState.wrong;
    }
    // Khi đã chọn đúng, làm mờ các lựa chọn còn lại.
    if (_correct) return _OptionState.dimmed;
    return _OptionState.normal;
  }
}

enum _OptionState { normal, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  final String word;
  final _OptionState state;
  final VoidCallback onTap;
  const _OptionButton({
    required this.word,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData? icon;
    switch (state) {
      case _OptionState.correct:
        bg = AppColors.words;
        fg = Colors.white;
        icon = Icons.check_circle_rounded;
      case _OptionState.wrong:
        bg = AppColors.letters;
        fg = Colors.white;
        icon = Icons.replay_rounded;
      case _OptionState.dimmed:
        bg = Colors.white;
        fg = AppColors.ink.withValues(alpha: 0.3);
        icon = null;
      case _OptionState.normal:
        bg = Colors.white;
        fg = AppColors.ink;
        icon = null;
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.words, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 10),
              Icon(icon, color: fg, size: 32),
            ],
          ],
        ),
      ),
    );
  }
}
