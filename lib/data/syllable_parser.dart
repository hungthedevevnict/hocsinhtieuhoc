import 'app_data.dart';

/// Tách 1 tiếng gõ tay (vd "đề", "bờ", "cá") thành âm đầu + vần + thanh,
/// để tạo SyllableSpec mà không cần bố mẹ chọn từng chip.
///
/// Chỉ nhận tiếng đơn giản: 1 âm đầu (có thể rỗng) + 1 NGUYÊN ÂM ĐƠN
/// (a,e,ê,i,o,ô,ơ,u,ư) + 1 thanh. Trả về null nếu tiếng có âm cuối,
/// nguyên âm đôi/ba, hoặc âm đầu không nhận diện được.

/// Các cụm phụ âm đầu, xếp dài → ngắn để so khớp tham lam đúng thứ tự.
const List<String> _onsetCandidates = [
  'ngh',
  'ng', 'nh', 'ch', 'th', 'ph', 'kh', 'tr', 'gi', 'qu',
  'b', 'c', 'd', 'đ', 'g', 'h', 'k', 'l', 'm', 'n', 'p', 'r', 's', 't', 'v', 'x',
];

const Map<String, String> _onsetSound = {
  'b': 'bờ', 'c': 'cờ', 'ch': 'chờ', 'd': 'dờ', 'đ': 'đờ',
  'g': 'gờ', 'gi': 'giờ', 'h': 'hờ', 'k': 'cờ', 'kh': 'khờ',
  'l': 'lờ', 'm': 'mờ', 'n': 'nờ', 'ng': 'ngờ', 'ngh': 'ngờ',
  'nh': 'nhờ', 'p': 'pờ', 'ph': 'phờ', 'qu': 'quờ', 'r': 'rờ',
  's': 'sờ', 't': 'tờ', 'th': 'thờ', 'tr': 'trờ', 'v': 'vờ', 'x': 'xờ',
};

/// Tra ngược: mỗi chữ nguyên âm có dấu → (nguyên âm gốc, chỉ số thanh).
final Map<String, (String vowel, int tone)> _reverseTone = {
  for (final entry in tonedVowels.entries)
    for (var t = 0; t < entry.value.length; t++) entry.value[t]: (entry.key, t),
};

SyllableSpec? parseSyllable(String rawInput) {
  final s = rawInput.trim().toLowerCase();
  if (s.isEmpty) return null;

  for (final onset in _onsetCandidates) {
    if (!s.startsWith(onset)) continue;
    final remainder = s.substring(onset.length);
    final hit = _reverseTone[remainder];
    if (hit != null) {
      return SyllableSpec(onset, _onsetSound[onset]!, hit.$1, hit.$2);
    }
  }
  // Không có âm đầu (tiếng bắt đầu ngay bằng nguyên âm), vd "ở", "ăn".
  final hit = _reverseTone[s];
  if (hit != null) {
    return SyllableSpec('', hit.$1, hit.$1, hit.$2);
  }
  return null;
}

/// Kết quả tách 1 dòng nhập tay thành 1 từ ghép, hoặc lỗi nếu không hiểu.
class ParsedLineResult {
  final CompoundWord? word;
  final String? error;
  const ParsedLineResult.ok(this.word) : error = null;
  const ParsedLineResult.fail(this.error) : word = null;
}

/// Mỗi dòng: tiếng 1, dấu cách, tiếng 2, rồi emoji tuỳ chọn ở cuối.
ParsedLineResult parseCompoundWordLine(String line) {
  final cleaned = line.trim();
  if (cleaned.isEmpty) return const ParsedLineResult.fail(null); // dòng trống, bỏ qua âm thầm

  final tokens = cleaned
      .split(RegExp(r'\s+'))
      .map((t) => t.replaceAll(RegExp(r'[,.;:!?]+$'), ''))
      .where((t) => t.isNotEmpty)
      .toList();

  if (tokens.length < 2) {
    return ParsedLineResult.fail('"$cleaned" — cần gõ đủ 2 tiếng (vd: bờ đê)');
  }

  final s1 = parseSyllable(tokens[0]);
  final s2 = parseSyllable(tokens[1]);
  if (s1 == null) {
    return ParsedLineResult.fail('Không hiểu tiếng "${tokens[0]}" trong "$cleaned"');
  }
  if (s2 == null) {
    return ParsedLineResult.fail('Không hiểu tiếng "${tokens[1]}" trong "$cleaned"');
  }

  final emoji = tokens.length > 2 ? tokens.sublist(2).join(' ') : '📚';
  return ParsedLineResult.ok(CompoundWord(emoji, [s1, s2]));
}
