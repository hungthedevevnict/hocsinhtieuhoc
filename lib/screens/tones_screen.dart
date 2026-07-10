import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';

class TonesScreen extends StatefulWidget {
  const TonesScreen({super.key});

  @override
  State<TonesScreen> createState() => _TonesScreenState();
}

class _TonesScreenState extends State<TonesScreen> {
  int _setIndex = 0;
  int? _tappedTone;

  ToneSet get _set => toneSets[_setIndex];

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _speakTone(int i) {
    setState(() => _tappedTone = i);
    // Đọc: tên thanh rồi đọc tiếng. Vd: "dấu sắc. má"
    final label = i == 0 ? 'thanh ngang' : toneNames[i];
    TtsService.instance.speakSequence(
      [label, _set.forms[i]],
      gap: const Duration(milliseconds: 180),
    );
  }

  void _readAll() {
    setState(() => _tappedTone = null);
    TtsService.instance.speakSequence(
      _set.forms,
      gap: const Duration(milliseconds: 320),
    );
  }

  void _nextSet() {
    setState(() {
      _setIndex = (_setIndex + 1) % toneSets.length;
      _tappedTone = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      color: AppColors.tones,
      title: 'Dấu Thanh',
      body: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            'Chạm vào từng chữ để nghe dấu nhé!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemCount: 6,
                itemBuilder: (_, i) => _ToneTile(
                  form: _set.forms[i],
                  toneName: i == 0 ? 'ngang' : toneNames[i].replaceAll('dấu ', ''),
                  color: AppColors.tileColors[i % AppColors.tileColors.length],
                  highlighted: _tappedTone == i,
                  onTap: () => _speakTone(i),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                KidButton(
                  label: 'Nghe cả nhà',
                  icon: Icons.volume_up_rounded,
                  color: AppColors.tones,
                  onTap: _readAll,
                ),
                const SizedBox(width: 14),
                KidButton(
                  label: 'Tiếng khác',
                  icon: Icons.refresh_rounded,
                  color: AppColors.sunny,
                  onTap: _nextSet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToneTile extends StatelessWidget {
  final String form;
  final String toneName;
  final Color color;
  final bool highlighted;
  final VoidCallback onTap;
  const _ToneTile({
    required this.form,
    required this.toneName,
    required this.color,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: highlighted ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: highlighted ? 0.45 : 0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              form,
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: highlighted ? Colors.white : color,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              toneName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: highlighted
                    ? Colors.white70
                    : AppColors.ink.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
