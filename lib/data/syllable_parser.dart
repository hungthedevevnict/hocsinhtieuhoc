import 'app_data.dart';

/// Tách 1 tiếng gõ tay (vd "đề", "con", "hoa", "khuyên") thành âm đầu + vần +
/// thanh, để tạo [SyllableSpec] mà không cần bố mẹ chọn từng chip.
///
/// Hỗ trợ MỌI vần tiếng Việt: nguyên âm đơn, nguyên âm đôi/ba, có/không âm cuối.
/// Chỉ từ chối khi tiếng có ký tự lạ hoặc cấu trúc không phải tiếng Việt.

/// Các âm đầu, xếp DÀI → NGẮN để so khớp tham lam đúng thứ tự.
const List<String> _onsets = [
  'ngh',
  'ch', 'gh', 'gi', 'kh', 'ng', 'nh', 'ph', 'qu', 'th', 'tr',
  'b', 'c', 'd', 'đ', 'g', 'h', 'k', 'l', 'm', 'n', 'p', 'r', 's', 't', 'v', 'x',
];

/// Âm cuối 2 chữ / 1 chữ.
const Set<String> _finals2 = {'ng', 'nh', 'ch'};
const Set<String> _finals1 = {'c', 'm', 'n', 'p', 't'};

/// Tra ngược: mỗi chữ nguyên âm (có/không dấu) → (nguyên âm gốc, chỉ số thanh).
final Map<String, (String, int)> _reverseTone = {
  for (final entry in tonedVowels.entries)
    for (var t = 0; t < entry.value.length; t++) entry.value[t]: (entry.key, t),
};

/// Bỏ dấu thanh khỏi tiếng: trả về (tiếng chưa dấu, chỉ số thanh).
/// Vd "quyển" => ("quyên", 3). Mỗi tiếng tiếng Việt có tối đa 1 dấu thanh.
(String, int) _stripTone(String s) {
  for (var i = 0; i < s.length; i++) {
    final hit = _reverseTone[s[i]];
    if (hit != null && hit.$2 != 0) {
      return (s.substring(0, i) + hit.$1 + s.substring(i + 1), hit.$2);
    }
  }
  return (s, 0);
}

/// Kiểm tra phần vần (chưa dấu) có hợp lệ không: 1-3 nguyên âm + âm cuối tuỳ chọn.
bool _isValidRime(String rime) {
  if (rime.isEmpty) return false;
  var vowels = rime;
  if (rime.length >= 2 && _finals2.contains(rime.substring(rime.length - 2))) {
    vowels = rime.substring(0, rime.length - 2);
  } else if (rime.length >= 2 && _finals1.contains(rime.substring(rime.length - 1))) {
    vowels = rime.substring(0, rime.length - 1);
  }
  if (vowels.isEmpty || vowels.length > 3) return false;
  for (final ch in vowels.split('')) {
    if (!baseVowels.contains(ch)) return false;
  }
  return true;
}

SyllableSpec? parseSyllable(String rawInput) {
  final input = rawInput.trim();
  if (input.isEmpty) return null;
  final (base, tone) = _stripTone(input.toLowerCase());

  // Thử tách âm đầu (dài → ngắn), phần còn lại là vần.
  for (final onset in _onsets) {
    if (!base.startsWith(onset)) continue;
    final rime = base.substring(onset.length);
    if (_isValidRime(rime)) {
      return SyllableSpec(onset, consonantSound[onset]!, rime, tone, input);
    }
  }
  // Không có âm đầu (tiếng bắt đầu bằng nguyên âm): "ăn", "oa", "yêu"...
  if (_isValidRime(base)) {
    return SyllableSpec('', '', base, tone, input);
  }
  return null;
}

/// Kết quả tách 1 dòng nhập tay thành 1 từ (1 tiếng hoặc nhiều tiếng ghép),
/// hoặc lỗi nếu không hiểu.
class ParsedLineResult {
  final CompoundWord? word;
  final String? error;
  const ParsedLineResult.ok(this.word) : error = null;
  const ParsedLineResult.fail(this.error) : word = null;
}

/// Mỗi dòng: 1 hoặc nhiều tiếng liên tiếp (từ đơn hay từ ghép đều được),
/// rồi emoji tuỳ chọn ở cuối. Đọc các tiếng từ trái sang phải, tiếng nào
/// không hiểu được nữa thì coi phần còn lại của dòng là emoji/nhãn.
ParsedLineResult parseCompoundWordLine(String line) {
  final cleaned = line.trim();
  if (cleaned.isEmpty) return const ParsedLineResult.fail(null); // dòng trống, bỏ qua âm thầm

  final tokens = cleaned
      .split(RegExp(r'\s+'))
      .map((t) => t.replaceAll(RegExp(r'[,.;:!?]+$'), ''))
      .where((t) => t.isNotEmpty)
      .toList();

  final syllables = <SyllableSpec>[];
  var i = 0;
  for (; i < tokens.length; i++) {
    final s = parseSyllable(tokens[i]);
    if (s == null) break;
    syllables.add(s);
  }

  if (syllables.isEmpty) {
    return ParsedLineResult.fail('Không hiểu tiếng "${tokens[0]}" trong "$cleaned"');
  }

  final emoji = i < tokens.length ? tokens.sublist(i).join(' ') : '📚';
  return ParsedLineResult.ok(CompoundWord(emoji, syllables));
}
