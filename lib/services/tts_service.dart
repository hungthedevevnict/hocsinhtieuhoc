import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import 'tts_cache_stub.dart' if (dart.library.io) 'tts_cache_io.dart';

/// Bộ phát âm tiếng Việt dùng chung cho toàn app.
///
/// Ưu tiên giọng Google Kore (tiếng Việt tự nhiên) qua hàm serverless
/// `/api/tts` — dùng cho CẢ web lẫn điện thoại, có cache nên tạo 1 lần dùng mãi.
/// Trên điện thoại còn lưu thêm xuống đĩa (`TtsDiskCache`) để mở app lại
/// (kể cả mất mạng) vẫn nghe được ngay, không phải gọi mạng lại mỗi lần mở app.
/// Trên điện thoại, nếu mất mạng / gọi lỗi thì tự quay về giọng iOS có sẵn.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  /// Domain đã deploy trên Vercel (dùng cho bản điện thoại gọi /api/tts).
  static const String _apiBase = 'https://tuhoc.vercel.app';

  /// Phiên bản giọng — BUMP mỗi khi đổi nhà cung cấp/giọng để bỏ qua cache cũ
  /// (CDN Vercel + cache trên máy) và tạo lại bằng giọng mới. mm1 = MiniMax cute_boy.
  static const String _ttsVersion = 'mm2';

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  bool _nativeTtsReady = false;

  /// True khi đang gọi mạng tạo giọng (để UI hiện "đang tạo" + chặn double-tap).
  final ValueNotifier<bool> loading = ValueNotifier<bool>(false);

  // Cache audio trong phiên (theo chữ) để chữ lặp (bờ, ê, dấu...) khỏi tải lại.
  final Map<String, Uint8List> _cache = {};
  final List<String> _cacheOrder = [];
  static const int _cacheMax = 300;

  // Cache audio xuống đĩa (điện thoại/máy tính) để mở app lại khỏi tải lại.
  final TtsDiskCache _disk = TtsDiskCache();

  // Tăng mỗi lần speak()/speakSequence()/stop() mới được gọi, để huỷ hẳn
  // lượt đọc cũ đang chờ giữa chừng (vd bé lướt sang chữ khác quá nhanh),
  // không để nó "đọc dí theo" khi đã chuyển sang nội dung mới.
  int _generation = 0;

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
    // Kèm v=<phiên bản giọng> để đổi giọng thì cache CDN cũ bị bỏ qua.
    return '$base/api/tts?text=${Uri.encodeQueryComponent(text)}&v=$_ttsVersion';
  }

  void _putCache(String key, Uint8List bytes) {
    _cache[key] = bytes;
    _cacheOrder.add(key);
    if (_cacheOrder.length > _cacheMax) {
      _cache.remove(_cacheOrder.removeAt(0));
    }
  }

  /// Băm ổn định (FNV-1a 32-bit) để đặt tên file cache trên đĩa — không đổi
  /// giữa các lần mở app, không phụ thuộc runtime (native/web).
  String _diskKey(String text) {
    var hash = 0x811c9dc5;
    // Kèm phiên bản giọng vào khoá → đổi giọng thì file cache cũ trên máy bị bỏ qua.
    for (final unit in '$_ttsVersion|$text'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// Lấy audio đã tạo cho [text] — từ cache RAM/đĩa nếu có, không thì gọi
  /// mạng tạo mới. Trả về null nếu Google lỗi hẳn (để phía trên lùi về
  /// giọng dự phòng). CHỈ tải, không phát — để gọi lặp lại khi đánh vần
  /// nhiều phần mà không phát trùng nhau.
  Future<Uint8List?> _fetchBytes(String text) async {
    final t = text.trim();
    if (t.isEmpty) return null;
    final cached = _cache[t];
    if (cached != null) return cached;
    final fromDisk = await _disk.read(_diskKey(t));
    if (fromDisk != null) {
      _putCache(t, fromDisk);
      return fromDisk;
    }
    // Chỉ hiện "đang tạo" khi phải gọi mạng (cache thì phát ngay).
    loading.value = true;
    try {
      final resp = await http
          .get(Uri.parse(_apiUrl(t)))
          .timeout(const Duration(seconds: 14));
      final ct = resp.headers['content-type'] ?? '';
      final isAudio =
          ct.contains('audio') || ct.contains('wav') || ct.contains('mpeg');
      if (resp.statusCode != 200 || resp.bodyBytes.length < 200 || !isAudio) {
        return null; // Google lỗi → 502/JSON → lùi về giọng dự phòng
      }
      final bytes = resp.bodyBytes;
      _putCache(t, bytes);
      unawaited(_disk.write(_diskKey(t), bytes));
      return bytes;
    } catch (_) {
      return null;
    } finally {
      loading.value = false;
    }
  }

  /// Phát [bytes] và ĐỢI phát xong hẳn mới trả về — để đọc nhiều đoạn nối
  /// tiếp (đánh vần) không bị đoạn sau đè lên đoạn trước.
  Future<void> _playBytes(Uint8List bytes) async {
    await _player.stop();
    final done = _player.onPlayerComplete.first;
    await _player.play(BytesSource(bytes));
    await done.timeout(const Duration(seconds: 10), onTimeout: () {});
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
    final myGen = ++_generation; // huỷ lượt đọc trước đó nếu còn đang chờ
    final bytes = await _fetchBytes(text);
    if (_generation != myGen) return; // đã bị lượt đọc mới hơn / stop() đè lên
    if (bytes != null) {
      try {
        await _playBytes(bytes);
        return;
      } catch (_) {
        // rơi xuống giọng dự phòng bên dưới
      }
      if (_generation != myGen) return;
    }
    // Google lỗi → giọng dự phòng: trình duyệt (web) hoặc giọng máy (native).
    await _nativeSpeak(text, rate: rate);
  }

  /// Đọc đánh vần ("đờ - ô - đô - sắc - đố"). GỘP thành 1 câu (ngăn bằng dấu
  /// phẩy) rồi đọc 1 lần: Google có ngữ cảnh cả câu nên phát âm chuẩn giọng
  /// Việt — đọc rời từng âm ngắn sẽ bị "Tây nói tiếng Việt". Google lỗi thì
  /// lùi về giọng máy (đọc rời từng phần).
  Future<void> speakSequence(
    List<String> parts, {
    double rate = 0.38,
    Duration gap = const Duration(milliseconds: 260),
  }) async {
    await init();
    final myGen = ++_generation; // huỷ lượt đọc trước đó nếu còn đang chờ
    final clean = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (clean.isEmpty) return;
    final joined = clean.join(', ');
    final bytes = await _fetchBytes(joined);
    if (_generation != myGen) return; // đã bị lượt đọc mới hơn / stop() đè lên
    if (bytes != null) {
      try {
        await _playBytes(bytes);
        return;
      } catch (_) {
        // rơi xuống giọng dự phòng bên dưới
      }
      if (_generation != myGen) return;
    }
    // Google lỗi → giọng máy đọc rời từng phần.
    await _nativeSpeakSequence(clean, rate, gap);
  }

  Future<void> stop() async {
    _generation++; // huỷ mọi lượt đọc đang chờ giữa chừng
    try {
      await _player.stop();
    } catch (_) {}
    if (_nativeTtsReady) {
      try {
        await _tts.stop();
      } catch (_) {}
    }
  }
}
