import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Bộ phát âm tiếng Việt dùng chung cho toàn app.
///
/// Dùng giọng đọc vi-VN có sẵn trên iOS. Nói chậm để bé nghe rõ,
/// và có thể đọc lần lượt nhiều đoạn (ví dụ đánh vần "bờ - a - ba").
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  /// Tốc độ đọc mặc định (chậm cho bé). 0.0 - 1.0 trên iOS.
  static const double _defaultRate = 0.42;

  Future<void> init() async {
    if (_ready) return;

    // QUAN TRỌNG trên iOS: dùng shared audio session và đặt category = playback
    // để app phát tiếng ngay cả khi bật nút gạt im lặng (silent switch),
    // và không bị các app khác làm câm.
    await _tts.setSharedInstance(true);
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

    // Chọn giọng tiếng Việt: ưu tiên vi-VN, nếu máy dùng mã khác thì dò tìm.
    await _tts.setLanguage('vi-VN');
    final langs = (await _tts.getLanguages) as List<dynamic>?;
    if (langs != null) {
      final vi = langs
          .map((e) => e.toString())
          .firstWhere(
            (l) => l.toLowerCase().startsWith('vi'),
            orElse: () => 'vi-VN',
          );
      await _tts.setLanguage(vi);
    }

    await _tts.setSpeechRate(_defaultRate);
    await _tts.setPitch(1.05);
    await _tts.setVolume(1.0);
    // Chờ đọc xong mới trả về ở lệnh speak (giúp đọc nối tiếp).
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// Đọc một đoạn văn bản tiếng Việt.
  Future<void> speak(String text, {double? rate}) async {
    await init();
    await _tts.stop();
    if (rate != null) {
      await _tts.setSpeechRate(rate);
    }
    await _tts.speak(text);
    if (rate != null) {
      await _tts.setSpeechRate(_defaultRate);
    }
  }

  /// Đọc lần lượt từng đoạn, có nghỉ ngắn giữa các đoạn.
  /// Dùng để đánh vần: ["bờ", "a", "ba"].
  Future<void> speakSequence(
    List<String> parts, {
    double rate = 0.38,
    Duration gap = const Duration(milliseconds: 260),
  }) async {
    await init();
    await _tts.stop();
    await _tts.setSpeechRate(rate);
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;
      await _tts.speak(part);
      if (i < parts.length - 1) {
        await Future<void>.delayed(gap);
      }
    }
    await _tts.setSpeechRate(_defaultRate);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
