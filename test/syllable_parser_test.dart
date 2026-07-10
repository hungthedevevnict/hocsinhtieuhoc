import 'package:flutter_test/flutter_test.dart';

import 'package:danh_van_tieng_viet/data/syllable_parser.dart';

void main() {
  test('Tách đúng — tiếng đơn giản (âm đầu + 1 nguyên âm)', () {
    for (final w in ['bờ', 'đê', 'cá', 'rô', 'ba', 'mẹ', 'bố', 'nhà', 'thơ',
      'gà', 'cô', 'chú', 'nghé', 'già', 'gì', 'giá', 'thỏ', 'khỉ', 'quê']) {
      final s = parseSyllable(w);
      expect(s, isNotNull, reason: 'Không tách được "$w"');
      expect(s!.syllable, w, reason: 'Sai kết quả "$w"');
    }
  });

  test('Tách đúng — tiếng có âm cuối', () {
    for (final w in ['con', 'bàn', 'còn', 'cơm', 'bát', 'sách', 'thóc',
      'ngon', 'ăn', 'ấm', 'ông', 'anh', 'canh', 'kính', 'lớp']) {
      final s = parseSyllable(w);
      expect(s, isNotNull, reason: 'Không tách được "$w"');
      expect(s!.syllable, w, reason: 'Sai kết quả "$w"');
    }
  });

  test('Tách đúng — vần đôi/ba (giờ đã hỗ trợ)', () {
    for (final w in ['hoa', 'yêu', 'khuyên', 'ngoan', 'buồn', 'chuối',
      'hươu', 'nước', 'người', 'tiên', 'biển', 'muỗi', 'quả', 'thuyền',
      'oanh', 'uyên', 'khoai', 'nguyễn']) {
      final s = parseSyllable(w);
      expect(s, isNotNull, reason: 'Không tách được "$w"');
      expect(s!.syllable, w, reason: 'Sai kết quả "$w"');
    }
  });

  test('Đánh vần đúng vài trường hợp tiêu biểu', () {
    expect(parseSyllable('ba')!.spellParts, ['bờ', 'a', 'ba']);
    expect(parseSyllable('bố')!.spellParts, ['bờ', 'ô', 'bô', 'sắc', 'bố']);
    expect(parseSyllable('con')!.spellParts, ['o', 'nờ', 'on', 'cờ', 'on', 'con']);
    expect(parseSyllable('còn')!.spellParts,
        ['o', 'nờ', 'on', 'cờ', 'on', 'con', 'huyền', 'còn']);
    expect(parseSyllable('hoa')!.spellParts, ['o', 'a', 'oa', 'hờ', 'oa', 'hoa']);
    expect(parseSyllable('ăn')!.spellParts, ['ă', 'nờ', 'ăn']);
  });

  test('Từ chối ký tự lạ / không phải tiếng Việt', () {
    for (final w in ['xyz', 'w', '123', 'ब']) {
      expect(parseSyllable(w), isNull, reason: '"$w" không nên tách được');
    }
  });

  test('Tách 1 dòng "tiếng1 tiếng2 [emoji]" thành từ ghép', () {
    final r1 = parseCompoundWordLine('bờ đê');
    expect(r1.word?.word, 'bờ đê');
    expect(r1.word?.emoji, '📚');

    final r2 = parseCompoundWordLine('con bò 🐄');
    expect(r2.word?.word, 'con bò');
    expect(r2.word?.emoji, '🐄');

    final r3 = parseCompoundWordLine('bông hoa');
    expect(r3.word?.word, 'bông hoa');

    final r4 = parseCompoundWordLine('xyz đê');
    expect(r4.word, isNull);
    expect(r4.error, isNotNull);
  });
}
