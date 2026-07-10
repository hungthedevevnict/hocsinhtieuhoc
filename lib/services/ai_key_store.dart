import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Lấy API key ShopAIKey. Ưu tiên đọc từ file `secrets.env` (bố mẹ dán key
/// trực tiếp trên máy tính, tránh lỗi gõ dấu tiếng Việt trên bàn phím điện
/// thoại). Nếu file chưa có key, dùng key đã nhập tay trong app (nếu có).
class AiKeyStore {
  AiKeyStore._();
  static final AiKeyStore instance = AiKeyStore._();

  static const _keyKey = 'shopaikey_api_key';
  static const defaultBaseUrl = 'https://api.shopaikey.com';

  String? _envKeyCache;
  bool _envLoaded = false;

  Future<String?> _loadFromEnvAsset() async {
    if (_envLoaded) return _envKeyCache;
    _envLoaded = true;
    try {
      final content = await rootBundle.loadString('secrets.env');
      for (final rawLine in content.split('\n')) {
        final line = rawLine.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final idx = line.indexOf('=');
        if (idx == -1) continue;
        final key = line.substring(0, idx).trim();
        final value = line.substring(idx + 1).trim();
        if (key == 'SHOPAIKEY_API_KEY' && value.isNotEmpty) {
          _envKeyCache = value;
          break;
        }
      }
    } catch (_) {
      // File chưa khai báo/không đọc được — bỏ qua, dùng phương án khác.
    }
    return _envKeyCache;
  }

  Future<String?> getKey() async {
    // Trên web KHÔNG dùng key (tránh lộ key ra bản web công khai + bị CORS chặn).
    if (kIsWeb) return null;

    final fromEnv = await _loadFromEnvAsset();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;

    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyKey);
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  Future<void> setKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyKey, key.trim());
  }

  Future<void> clearKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyKey);
  }
}
