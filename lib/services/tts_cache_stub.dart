import 'dart:typed_data';

/// Bản web: không lưu file trên máy (browser đã tự cache theo Cache-Control
/// của /api/tts), nên đọc/ghi ở đây là no-op.
class TtsDiskCache {
  Future<Uint8List?> read(String key) async => null;
  Future<void> write(String key, Uint8List bytes) async {}
}
