import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';

class BlendingScreen extends StatefulWidget {
  const BlendingScreen({super.key});

  @override
  State<BlendingScreen> createState() => _BlendingScreenState();
}

class _BlendingScreenState extends State<BlendingScreen> {
  int _initialIndex = 3; // 'b'
  int _vowelIndex = 5; // 'ô'
  int _toneIndex = 1; // sắc -> mặc định ra "bố"

  Initial get _initial => initials[_initialIndex];
  String get _vowel => vowels[_vowelIndex];
  Tone get _tone => tones6[_toneIndex];

  String get _base => '${_initial.letter}$_vowel';
  String get _syllable => buildSyllable(_initial.letter, _vowel, _toneIndex);
  WordExample? get _example => syllableExamples[_syllable];

  static const Color _blue = AppColors.blending;
  static const Color _blueDark = Color(0xFF2E90E0);

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  /// "đờ - ê - đê - huyền - đề" (thanh đọc trơn, không kèm chữ "dấu").
  List<String> get _spellParts => _toneIndex == 0
      ? [_initial.sound, _vowel, _base]
      : [_initial.sound, _vowel, _base, _tone.name, _syllable];

  String get _spellText => _spellParts.join('  -  ');

  void _spellOut() => TtsService.instance.speakSequence(_spellParts);

  void _readExample() {
    final ex = _example;
    if (ex != null) TtsService.instance.speak(ex.phrase);
  }

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      color: _blue,
      title: 'Đánh Vần',
      body: Column(
        children: [
          const SizedBox(height: 6),
          Text(
            'Chọn âm đầu · vần · dấu ở dưới nhé!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink.withValues(alpha: 0.55),
            ),
          ),
          // Thẻ tiếng.
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                child: _resultCard(),
              ),
            ),
          ),
          // Nút Đánh vần.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Center(
              child: KidButton(
                label: 'Đánh vần',
                icon: Icons.hearing_rounded,
                color: AppColors.tones,
                fontSize: 22,
                onTap: _spellOut,
              ),
            ),
          ),
          _picker(
            label: 'Âm đầu',
            children: [
              for (var i = 0; i < initials.length; i++)
                _chip(
                  text: initials[i].letter,
                  selected: i == _initialIndex,
                  color: _blue,
                  onTap: () {
                    setState(() => _initialIndex = i);
                    TtsService.instance.speak(initials[i].sound);
                  },
                ),
            ],
          ),
          _picker(
            label: 'Vần',
            children: [
              for (var i = 0; i < vowels.length; i++)
                _chip(
                  text: vowels[i],
                  selected: i == _vowelIndex,
                  color: AppColors.words,
                  onTap: () {
                    setState(() => _vowelIndex = i);
                    TtsService.instance.speak(vowels[i]);
                  },
                ),
            ],
          ),
          _picker(
            label: 'Dấu thanh',
            children: [
              for (var i = 0; i < tones6.length; i++)
                _chip(
                  text: tones6[i].sample,
                  label: tones6[i].name,
                  selected: i == _toneIndex,
                  color: AppColors.tones,
                  onTap: () {
                    setState(() => _toneIndex = i);
                    TtsService.instance.speak(
                        i == 0 ? 'thanh ngang' : 'dấu ${tones6[i].name}');
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _resultCard() {
    final ex = _example;
    return GestureDetector(
      onTap: _spellOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF64B6F7), _blueDark],
          ),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: _blueDark.withValues(alpha: 0.45),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Các mảnh ghép.
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(_initial.letter),
                _plus(),
                _pill(_vowel, textColor: AppColors.sunny),
                if (_toneIndex != 0) ...[
                  _plus(),
                  _pill('dấu ${_tone.name}', small: true),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.south_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            // Tiếng kết quả.
            Text(
              _syllable,
              style: TextStyle(
                fontSize: 92,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.08,
                shadows: [
                  Shadow(
                    color: _blueDark.withValues(alpha: 0.55),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Cách đánh vần.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _spellText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            // Từ ghép ví dụ.
            const SizedBox(height: 14),
            if (ex != null)
              GestureDetector(
                onTap: _readExample,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ex.emoji, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Từ ghép',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _blueDark.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            ex.phrase,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: _blueDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.volume_up_rounded,
                          color: _blueDark, size: 26),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Chạm thẻ để nghe đánh vần 🔊',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, {Color textColor = Colors.white, bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 14 : 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 26 : 46,
          fontWeight: FontWeight.w900,
          color: textColor,
          height: 1,
        ),
      ),
    );
  }

  Widget _plus() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text('+',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white54)),
      );

  Widget _picker({required String label, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 3),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink.withValues(alpha: 0.55),
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: FadeRight(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String text,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    String? label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 54,
          decoration: BoxDecoration(
            color: selected ? color : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.35),
              width: selected ? 0 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? color.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: selected ? 10 : 5,
                offset: Offset(0, selected ? 5 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : color,
                  height: 1,
                ),
              ),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white70
                          : color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
