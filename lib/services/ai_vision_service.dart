import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../data/app_data.dart';
import 'ai_key_store.dart';

/// Gọi ShopAIKey (proxy chuẩn OpenAI) để đọc ảnh chụp bài học và tự tách
/// thành các từ ghép 2 tiếng (âm đầu + vần + thanh) dùng được trong app.
///
/// Xem tài liệu: ShopAIKey API — endpoint /v1/chat/completions kiểu OpenAI,
/// auth Header `Authorization: Bearer API_KEY`.
class AiVisionService {
  AiVisionService._();
  static final AiVisionService instance = AiVisionService._();

  // Model rẻ, đủ tốt cho việc đọc chữ + tách âm/vần (theo khuyến nghị tài liệu).
  static const _model = 'gpt-4o-mini';

  static const _systemPrompt =
      'Bạn là trợ lý đọc sách giáo khoa Tiếng Việt lớp 1 cho học sinh mới học đánh vần.';

  static const _userPrompt = '''
Nhìn ảnh trang sách/bài tập đánh vần tiếng Việt. Tìm các TỪ GHÉP gồm ĐÚNG 2 TIẾNG.

CHỈ lấy tiếng thoả TẤT CẢ điều kiện sau (bỏ qua tiếng không thoả):
- Có ĐÚNG 1 phụ âm đầu (vd: b, c, ch, d, đ, g, gi, h, kh, l, m, n, ng, nh, ph, qu, r, s, t, th, tr, v, x).
- Vần chỉ là 1 NGUYÊN ÂM ĐƠN trong nhóm: a, e, ê, i, o, ô, ơ, u, ư (KHÔNG lấy nguyên âm đôi/ba như iê, ươ, oa; KHÔNG có âm cuối như n, t, c, m, ng, nh).
- Có thanh điệu rõ ràng (ngang/sắc/huyền/hỏi/ngã/nặng).

Bỏ qua hoàn toàn các từ có tiếng không thoả điều kiện trên (vd "con", "bàn", "yêu"...).

Trả về DUY NHẤT một mảng JSON (không markdown, không giải thích thêm), theo đúng khuôn:
[
  {
    "word": "bờ đê",
    "emoji": "🏞️",
    "syllables": [
      {"letter": "b", "sound": "bờ", "vowel": "ơ", "tone": 0},
      {"letter": "đ", "sound": "đờ", "vowel": "ê", "tone": 0}
    ]
  }
]
Trong đó "tone": 0=ngang, 1=sắc, 2=huyền, 3=hỏi, 4=ngã, 5=nặng.
"vowel" chỉ được là một trong: a, e, ê, i, o, ô, ơ, u, ư.
"sound" là cách đọc âm đầu (vd b→"bờ", ch→"chờ", ng→"ngờ", qu→"quờ").
"emoji" chọn 1 icon hợp với nghĩa của từ.
Nếu không tìm được từ nào phù hợp, trả về mảng rỗng [].
''';

  /// Gửi ảnh lên AI, trả về danh sách từ ghép hợp lệ (đã lọc theo đúng công thức
  /// âm đầu + 1 nguyên âm đơn + thanh mà app đang dùng).
  Future<List<CompoundWord>> extractCompoundWords(Uint8List imageBytes) async {
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
      throw AiVisionException('AI không trả về nội dung.');
    }

    return _parseWords(content);
  }

  List<CompoundWord> _parseWords(String content) {
    // AI đôi khi bọc JSON trong ```json ... ``` — bóc lớp markdown nếu có.
    var text = content.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final m = fence.firstMatch(text);
    if (m != null) text = m.group(1)!.trim();

    List<dynamic> raw;
    try {
      raw = jsonDecode(text) as List<dynamic>;
    } catch (_) {
      throw AiVisionException('Không đọc được kết quả từ AI. Thử ảnh khác rõ hơn nhé.');
    }

    final result = <CompoundWord>[];
    for (final item in raw) {
      final word = _parseOneWord(item as Map<String, dynamic>);
      if (word != null) result.add(word);
    }
    return result;
  }

  CompoundWord? _parseOneWord(Map<String, dynamic> item) {
    final rawSyllables = item['syllables'] as List<dynamic>?;
    if (rawSyllables == null || rawSyllables.length != 2) return null;

    final specs = <SyllableSpec>[];
    for (final s in rawSyllables) {
      final map = s as Map<String, dynamic>;
      final letter = (map['letter'] as String?)?.trim() ?? '';
      final sound = (map['sound'] as String?)?.trim() ?? '';
      final vowel = (map['vowel'] as String?)?.trim() ?? '';
      final tone = map['tone'];
      if (sound.isEmpty) return null;
      if (!tonedVowels.containsKey(vowel)) return null;
      if (tone is! int || tone < 0 || tone > 5) return null;
      specs.add(SyllableSpec(letter, sound, vowel, tone));
    }

    final emojiRaw = (item['emoji'] as String?)?.trim();
    final emoji = (emojiRaw != null && emojiRaw.isNotEmpty) ? emojiRaw : '📚';
    return CompoundWord(emoji, specs);
  }
}

class AiVisionException implements Exception {
  final String message;
  AiVisionException(this.message);
  @override
  String toString() => message;
}
