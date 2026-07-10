import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_key_store.dart';

/// Gọi ShopAIKey (proxy chuẩn OpenAI) để ĐỌC CHỮ trong ảnh chụp bài học.
/// Chỉ làm OCR thuần — việc tách âm đầu/vần/thanh để bộ phân tích riêng của
/// app (`syllable_parser.dart`, đã có test) xử lý, tránh AI đoán sai phần
/// ngữ âm mà nó không cần phải hiểu.
///
/// Xem tài liệu: ShopAIKey API — endpoint /v1/chat/completions kiểu OpenAI,
/// auth Header `Authorization: Bearer API_KEY`.
class AiVisionService {
  AiVisionService._();
  static final AiVisionService instance = AiVisionService._();

  // Model mạnh để đọc chữ ảnh chính xác (gpt-4o-mini đọc dấu tiếng Việt hay sai).
  static const _model = 'gpt-4o';

  static const _systemPrompt =
      'Bạn là trợ lý đọc chữ trong ảnh sách/bài tập Tiếng Việt cho học sinh lớp 1.';

  static const _userPrompt = '''
Đọc TẤT CẢ các từ tiếng Việt có trong ảnh này, đừng bỏ sót từ nào — kể cả từ đơn chỉ 1 tiếng
(vd "gà", "bé") lẫn từ ghép nhiều tiếng (vd "bờ đê", "bố mẹ").
Ảnh có thể trình bày nhiều cột — đọc theo thứ tự từ trái sang phải, từ trên xuống dưới.

Mỗi từ là MỘT dòng kết quả riêng, giữ đúng số tiếng và thứ tự tiếng như trong ảnh — KHÔNG tự
ghép 2 từ đơn cạnh nhau thành 1 dòng, và KHÔNG tự tách 1 từ ghép thành nhiều dòng.

Giữ NGUYÊN dấu tiếng Việt, viết chữ thường. Chỉ trả về danh sách, mỗi từ 1 dòng — KHÔNG đánh số,
KHÔNG markdown, KHÔNG giải thích gì thêm.
''';

  /// Gửi ảnh lên AI, trả về các dòng chữ đọc được (nguyên văn, chưa lọc).
  Future<List<String>> extractWordLines(Uint8List imageBytes) async {
    final apiKey = await AiKeyStore.instance.getKey();
    if (apiKey == null) {
      throw AiVisionException('Chưa có API key. Vui lòng nhập ShopAIKey.');
    }

    final b64 = base64Encode(imageBytes);
    final body = jsonEncode({
      'model': _model,
      'temperature': 0,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _userPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$b64'},
            },
          ],
        },
      ],
    });

    // api.shopaikey.com đôi khi bị Cloudflare chặn — thử direct.shopaikey.com
    // khi request bị lỗi mạng (không retry khi server trả lỗi HTTP 4xx/5xx).
    const hosts = [
      AiKeyStore.defaultBaseUrl,
      'https://direct.shopaikey.com',
    ];

    http.Response? res;
    Object? lastNetworkError;
    for (final host in hosts) {
      try {
        res = await http
            .post(
              Uri.parse('$host/v1/chat/completions'),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 60));
        break;
      } catch (e) {
        lastNetworkError = e;
        continue;
      }
    }

    if (res == null) {
      throw AiVisionException('Không kết nối được tới AI: $lastNetworkError');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final snippet = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
      throw AiVisionException('Lỗi từ AI (mã ${res.statusCode}): $snippet');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final content = decoded['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw AiVisionException('AI không đọc được chữ nào trong ảnh này.');
    }

    return _cleanLines(content);
  }

  List<String> _cleanLines(String content) {
    // AI đôi khi bọc trong ```...``` hoặc thêm gạch đầu dòng/số thứ tự — bóc hết.
    var text = content.trim();
    final fence = RegExp(r'```(?:[a-zA-Z]*)?\s*([\s\S]*?)```');
    final m = fence.firstMatch(text);
    if (m != null) text = m.group(1)!.trim();

    return text
        .split('\n')
        .map((l) => l.trim().replaceFirst(RegExp(r'^[-*•\d]+[.)]?\s*'), ''))
        .where((l) => l.isNotEmpty)
        .toList();
  }
}

class AiVisionException implements Exception {
  final String message;
  AiVisionException(this.message);
  @override
  String toString() => message;
}
