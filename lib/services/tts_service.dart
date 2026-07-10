import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Bộ phát âm tiếng Việt dùng chung cho toàn app.
///
/// - Trên điện thoại (native): dùng giọng vi-VN có sẵn trên máy (flutter_tts).
/// - Trên web: gọi hàm serverless `/api/tts` (giọng Google Kore, có cache) để
///   đọc hay hơn giọng lơ lớ của trình duyệt.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _webPlayer = AudioPlayer();
  bool _ready = false;

  /// Tốc độ đọc mặc định (chậm cho bé). 0.0 - 1.0 trên iOS.
  static const double _defaultRate = 0.42;

  Future<void> init() async {
    if (_ready) return;
    if (kIsWeb) {
      // Web không dùng flutter_tts — phát audio từ /api/tts.
      _ready = true;
      return;
    }

    // Cấu hình audio session CHỈ dành cho iOS (giúp phát tiếng cả khi gạt im
    // lặng). Trên web/Android các lệnh này không tồn tại nên phải bỏ qua, nếu
    // không sẽ ném lỗi và làm hỏng toàn bộ init → mất tiếng.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
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
      } catch (_) {}
    }

    // Chọn giọng tiếng Việt: ưu tiên vi-VN, nếu máy dùng mã khác thì dò tìm.
    // Bọc try/catch từng lệnh để một lệnh không hỗ trợ (trên web) không làm
    // hỏng cả init.
    try {
      await _tts.setLanguage('vi-VN');
      final langs = (await _tts.getLanguages) as List<dynamic>?;
      if (langs != null) {
        final vi = langs.map((e) => e.toString()).firstWhere(
              (l) => l.toLowerCase().startsWith('vi'),
              orElse: () => 'vi-VN',
            );
        await _tts.setLanguage(vi);
      }
    } catch (_) {}

    try {
      await _tts.setSpeechRate(_defaultRate);
      await _tts.setPitch(1.05);
      await _tts.setVolume(1.0);
    } catch (_) {}
    try {
      // Chờ đọc xong mới trả về ở lệnh speak (giúp đọc nối tiếp).
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
    _ready = true;
  }

  /// URL của hàm serverless đọc chữ (giọng Google Kore) trên web.
  String _webTtsUrl(String text) =>
      '${Uri.base.origin}/api/tts?text=${Uri.encodeQueryComponent(text)}';

  /// Phát 1 đoạn chữ trên web qua /api/tts.
  Future<void> _webSpeak(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    try {
      await _webPlayer.stop();
      await _webPlayer.play(UrlSource(_webTtsUrl(t)));
    } catch (_) {}
  }

  /// Đọc một đoạn văn bản tiếng Việt.
  Future<void> speak(String text, {double? rate}) async {
    await init();
    if (kIsWeb) {
      await _webSpeak(text);
      return;
    }
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
    if (kIsWeb) {
      // Web: gộp thành 1 câu, dấu phẩy tạo nhịp nghỉ tự nhiên → 1 lần gọi/cache.
      final joined = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(', ');
      await _webSpeak(joined);
      return;
    }
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
    if (kIsWeb) {
      await _webPlayer.stop();
      return;
    }
    await _tts.stop();
  }
}
