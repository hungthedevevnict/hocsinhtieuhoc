import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ghi âm bé đọc bài và phát lại cho bố mẹ nghe.
///
/// - Trên điện thoại (native): lưu file .m4a trong thư mục tài liệu, nhớ được
///   sau khi tắt app.
/// - Trên web: `record` trả về một blob URL của trình duyệt; giữ trong phiên
///   để nghe lại (không lưu lâu dài sau khi tải lại trang).
///
/// Không dùng `dart:io` để còn build được cho web.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  // lessonId -> vị trí bản ghi (đường dẫn file trên native, hoặc blob URL trên web).
  final Map<String, String> _locations = {};

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<String?> _location(String lessonId) async {
    if (_locations.containsKey(lessonId)) return _locations[lessonId];
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final p = prefs.getString('rec_$lessonId');
      if (p != null) _locations[lessonId] = p;
    }
    return _locations[lessonId];
  }

  Future<bool> hasRecording(String lessonId) async =>
      (await _location(lessonId)) != null;

  /// Bắt đầu ghi âm cho bài [lessonId]. Trả về false nếu không có quyền mic.
  Future<bool> startRecording(String lessonId) async {
    if (!await _recorder.hasPermission()) return false;
    await _player.stop();
    var path = '';
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/lesson_$lessonId.m4a';
    }
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    return true;
  }

  /// Dừng ghi và lưu vị trí bản ghi cho bài này.
  Future<void> stopRecording(String lessonId) async {
    final loc = await _recorder.stop();
    if (loc == null) return;
    _locations[lessonId] = loc;
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rec_$lessonId', loc);
    }
  }

  /// Dừng ghi mà không lưu (dùng khi rời màn hình giữa chừng).
  Future<void> cancelRecording() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  Future<void> play(String lessonId, {void Function()? onDone}) async {
    final loc = await _location(lessonId);
    if (loc == null) return;
    await _player.stop();
    _player.onPlayerComplete.first.then((_) => onDone?.call());
    await _player.play(kIsWeb ? UrlSource(loc) : DeviceFileSource(loc));
  }

  Future<void> stopPlaying() => _player.stop();

  Future<void> deleteRecording(String lessonId) async {
    _locations.remove(lessonId);
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rec_$lessonId');
      // Không xoá file vật lý (tránh dùng dart:io); lần ghi sau sẽ đè lên.
    }
  }
}
