import 'dart:async';

import 'package:flutter/material.dart';

import '../data/app_data.dart';
import '../services/audio_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/kid_widgets.dart';

/// Màn "Kiểm tra": hiện cả bài thành lưới 3 từ/dòng cho bé tự đọc. Bố mẹ bấm
/// ghi âm để thu lại bé đọc cả bài, rồi nghe lại sau. Chạm 1 từ để nghe mẫu.
class LessonReviewScreen extends StatefulWidget {
  final String lessonId;
  final String title;
  final List<CompoundWord> words;
  const LessonReviewScreen({
    super.key,
    required this.lessonId,
    required this.title,
    required this.words,
  });

  @override
  State<LessonReviewScreen> createState() => _LessonReviewScreenState();
}

class _LessonReviewScreenState extends State<LessonReviewScreen>
    with SingleTickerProviderStateMixin {
  bool _recording = false;
  bool _playing = false;
  bool _hasRecording = false;
  int _elapsed = 0; // giây đã ghi
  Timer? _timer;
  late final AnimationController _pulse;
  int? _tappedWord;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _refreshHasRecording();
  }

  Future<void> _refreshHasRecording() async {
    final has = await AudioService.instance.hasRecording(widget.lessonId);
    if (mounted) setState(() => _hasRecording = has);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    AudioService.instance.cancelRecording();
    AudioService.instance.stopPlaying();
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      await AudioService.instance.stopRecording(widget.lessonId);
      _timer?.cancel();
      setState(() {
        _recording = false;
        _hasRecording = true;
      });
      return;
    }
    await TtsService.instance.stop();
    await AudioService.instance.stopPlaying();
    final ok = await AudioService.instance.startRecording(widget.lessonId);
    if (!ok) {
      _showMessage('Cần cho phép Micro trong Cài đặt để ghi âm nhé.');
      return;
    }
    setState(() {
      _recording = true;
      _playing = false;
      _elapsed = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await AudioService.instance.stopPlaying();
      setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    await AudioService.instance.play(
      widget.lessonId,
      onDone: () {
        if (mounted) setState(() => _playing = false);
      },
    );
  }

  Future<void> _deleteRecording() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá bản ghi âm?'),
        content: const Text('Bỏ bản ghi âm của bài này nhé?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true) return;
    await AudioService.instance.stopPlaying();
    await AudioService.instance.deleteRecording(widget.lessonId);
    setState(() {
      _hasRecording = false;
      _playing = false;
    });
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  String get _timeText {
    final m = (_elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return KidScaffold(
      color: AppColors.compound,
      title: widget.title,
      body: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            _recording
                ? 'Đang ghi âm ⏺  $_timeText'
                : 'Bé đọc cả bài, bố mẹ bấm ● để ghi âm nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _recording ? AppColors.letters : AppColors.ink.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: widget.words.length,
                itemBuilder: (_, i) => _WordTile(
                  word: widget.words[i],
                  highlighted: _tappedWord == i,
                  onTap: () {
                    setState(() => _tappedWord = i);
                    TtsService.instance.speak(widget.words[i].word);
                  },
                ),
              ),
            ),
          ),
          // Nút nghe lại + xoá (khi đã có bản ghi và không đang ghi).
          if (_hasRecording && !_recording)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KidButton(
                    label: _playing ? 'Dừng' : 'Nghe lại bài đọc',
                    icon: _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: AppColors.blending,
                    fontSize: 17,
                    onTap: _togglePlay,
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _deleteRecording,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.letters.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_rounded, color: AppColors.letters, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          // Nút ghi âm to.
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 4),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _toggleRecord,
                  child: ScaleTransition(
                    scale: _recording
                        ? Tween(begin: 1.0, end: 1.1).animate(_pulse)
                        : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: _recording ? AppColors.letters : AppColors.compound,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_recording ? AppColors.letters : AppColors.compound)
                                .withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        _recording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _recording ? 'Bấm để dừng' : (_hasRecording ? 'Ghi lại' : 'Ghi âm bé đọc'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink.withValues(alpha: 0.55),
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

class _WordTile extends StatelessWidget {
  final CompoundWord word;
  final bool highlighted;
  final VoidCallback onTap;
  const _WordTile({required this.word, required this.highlighted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.compound : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.compound, width: highlighted ? 0 : 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.compound.withValues(alpha: highlighted ? 0.4 : 0.12),
              blurRadius: highlighted ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(word.emoji, style: TextStyle(fontSize: highlighted ? 30 : 24)),
            const SizedBox(height: 4),
            Text(
              word.word,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: highlighted ? Colors.white : AppColors.compound,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
