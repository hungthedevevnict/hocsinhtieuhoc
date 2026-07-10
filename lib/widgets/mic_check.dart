import 'dart:math';

import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';

/// Nút mic "đọc theo": bé chạm rồi đọc [target], app nghe và chấm đúng/sai,
/// khen bằng giọng nói + hiện thông báo. Nhúng vào bất kỳ màn hình học nào.
class MicCheck extends StatefulWidget {
  final String target; // chữ/tiếng bé cần đọc
  final Color color;
  final double size;
  const MicCheck({
    super.key,
    required this.target,
    this.color = AppColors.sunny,
    this.size = 64,
  });

  @override
  State<MicCheck> createState() => _MicCheckState();
}

class _MicCheckState extends State<MicCheck>
    with SingleTickerProviderStateMixin {
  final Random _rng = Random();
  late final AnimationController _pulse;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    SpeechService.instance.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_listening) {
      await SpeechService.instance.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    await TtsService.instance.stop();
    final ok = await SpeechService.instance.init();
    if (!ok) {
      _snack('Cần cho phép Micro trong Cài đặt nhé', AppColors.letters);
      return;
    }
    setState(() => _listening = true);
    await SpeechService.instance.listen(onFinal: _check);
  }

  void _check(String spoken) {
    if (!mounted) return;
    setState(() => _listening = false);
    final correct = matchesTarget(spoken, widget.target);
    if (correct) {
      final praise = praises[_rng.nextInt(praises.length)];
      TtsService.instance.speakSequence(
        [praise, widget.target],
        gap: const Duration(milliseconds: 200),
      );
      _snack('🎉 $praise', AppColors.words);
    } else {
      TtsService.instance.speak(widget.target);
      _snack(
        spoken.isEmpty
            ? 'Chưa nghe rõ, thử lại nào!'
            : 'Bé đọc: "$spoken" — thử lại nhé',
        AppColors.primary,
      );
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1800),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: ScaleTransition(
            scale: _listening
                ? Tween(begin: 1.0, end: 1.14).animate(_pulse)
                : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _listening ? AppColors.letters : widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_listening ? AppColors.letters : widget.color)
                        .withValues(alpha: 0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _listening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _listening ? 'Đang nghe...' : 'Đọc theo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}
