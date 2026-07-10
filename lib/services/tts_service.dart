import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

/// Bộ phát âm tiếng Việt dùng chung cho toàn app.
///
/// Ưu tiên giọng Google Kore (tiếng Việt tự nhiên) qua hàm serverless
/// `/api/tts` — dùng cho CẢ web lẫn điện thoại, có cache nên tạo 1 lần dùng mãi.
/// Trên điện thoại, nếu mất mạng / gọi lỗi thì tự quay về giọng iOS có sẵn.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  /// Domain đã deploy trên Vercel (dùng cho bản điện thoại gọi /api/tts).
  static const String _apiBase = 'https://tuhoc.vercel.app';

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  bool _nativeTtsReady = false;

  // Cache audio trong phiên (theo chữ) để chữ lặp (bờ, ê, dấu...) khỏi tải lại.
  final Map<String, Uint8List> _cache = {};
  final List<String> _cacheOrder = [];
  static const int _cacheMax = 300;

  static const double _defaultRate = 0.42;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    // Phát audio (từ /api/tts) qua loa, kể cả khi gạt im lặng trên iOS.
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.defaultToSpeaker},
          ),
        ),
      );
    } catch (_) {}
  }

  String _apiUrl(String text) {
    final base = kIsWeb ? Uri.base.origin : _apiBase;
    return '$base/api/tts?text=${Uri.encodeQueryComponent(text)}';
  }

  void _putCache(String key, Uint8List bytes) {
    _cache[key] = bytes;
    _cacheOrder.add(key);
    if (_cacheOrder.length > _cacheMax) {
      _cache.remove(_cacheOrder.removeAt(0));
    }
  }

  /// Phát bằng giọng Google Kore qua /api/tts. Trả về true nếu phát được.
  Future<bool> _remoteSpeak(String text) async {
    final t = text.trim();
    if (t.isEmpty) return true;
    try {
      if (kIsWeb) {
        // Web: dùng UrlSource để trình duyệt tự tải + cache, thân thiện autoplay.
        await _player.stop();
        await _player.play(UrlSource(_apiUrl(t)));
        return true;
      }
      // Native: tải bytes (có cache trong phiên) rồi phát.
      var bytes = _cache[t];
      if (bytes == null) {
        final resp = await http
            .get(Uri.parse(_apiUrl(t)))
            .timeout(const Duration(seconds: 12));
        final ct = resp.headers['content-type'] ?? '';
        final isAudio = ct.contains('audio') || ct.contains('wav') || ct.contains('mpeg');
        if (resp.statusCode != 200 || resp.bodyBytes.length < 200 || !isAudio) {
          return false;
        }
        bytes = resp.bodyBytes;
        _putCache(t, bytes);
      }
      await _player.stop();
      await _player.play(BytesSource(bytes));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _ensureNativeTts() async {
    if (_nativeTtsReady) return;
    _nativeTtsReady = true;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
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
      await _tts.setPitch(1.05);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  /// Giọng iOS dự phòng (khi mất mạng / /api/tts lỗi).
  Future<void> _nativeSpeak(String text, {double? rate}) async {
    await _ensureNativeTts();
    await _tts.stop();
    await _tts.setSpeechRate(rate ?? _defaultRate);
    await _tts.speak(text);
  }

  Future<void> _nativeSpeakSequence(List<String> parts, double rate, Duration gap) async {
    await _ensureNativeTts();
    await _tts.stop();
    await _tts.setSpeechRate(rate);
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;
      await _tts.speak(part);
      if (i < parts.length - 1) await Future<void>.delayed(gap);
    }
    await _tts.setSpeechRate(_defaultRate);
  }

  /// Đọc một đoạn văn bản tiếng Việt.
  Future<void> speak(String text, {double? rate}) async {
    await init();
    if (await _remoteSpeak(text)) return;
    if (!kIsWeb) await _nativeSpeak(text, rate: rate);
  }

  /// Đọc lần lượt từng đoạn (đánh vần). Web/native đều gộp thành 1 câu để
  /// giọng Kore đọc liền có nhịp nghỉ tự nhiên; native lỗi mạng thì đọc rời.
  Future<void> speakSequence(
    List<String> parts, {
    double rate = 0.38,
    Duration gap = const Duration(milliseconds: 260),
  }) async {
    await init();
    final clean = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    final joined = clean.join(', ');
    if (await _remoteSpeak(joined)) return;
    if (!kIsWeb) await _nativeSpeakSequence(clean, rate, gap);
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    if (!kIsWeb && _nativeTtsReady) {
      try {
        await _tts.stop();
      } catch (_) {}
    }
  }
}
