import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Bản điện thoại/máy tính: lưu audio đã tạo xuống thư mục cache của app,
/// để mở app lại (kể cả mất mạng) vẫn nghe được ngay, không phải gọi mạng lại.
class TtsDiskCache {
  Directory? _dir;

  Future<Directory> _cacheDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/tts_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  Future<Uint8List?> read(String key) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/$key.bin');
      if (await file.exists()) return await file.readAsBytes();
    } catch (_) {}
    return null;
  }

  Future<void> write(String key, Uint8List bytes) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/$key.bin');
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }
}
