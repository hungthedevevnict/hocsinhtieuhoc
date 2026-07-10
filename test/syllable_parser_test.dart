import 'package:flutter_test/flutter_test.dart';

import 'package:danh_van_tieng_viet/data/syllable_parser.dart';

void main() {
  test('Tách đúng các tiếng đơn giản thường gặp', () {
    final cases = <String, String>{
      'bờ': 'bờ', 'đê': 'đê', 'cá': 'cá', 'rô': 'rô',
      'ba': 'ba', 'mẹ': 'mẹ', 'bố': 'bố', 'nhà': 'nhà',
      'thơ': 'thơ', 'gà': 'gà', 'cô': 'cô', 'chú': 'chú',
      'nghé': 'nghé', 'già': 'già', 'gì': 'gì', 'giá': 'giá',
      'thỏ': 'thỏ', 'khỉ': 'khỉ', 'quê': 'quê',
    };
    for (final entry in cases.entries) {
      final spec = parseSyllable(entry.key);
      expect(spec, isNotNull, reason: 'Không tách được "${entry.key}"');
      expect(spec!.syllable, entry.value, reason: 'Sai kết quả cho "${entry.key}"');
    }
  });

  test('Từ chối tiếng có âm cuối hoặc vần đôi', () {
    for (final word in ['con', 'bàn', 'yêu', 'oanh', 'ngoan']) {
      expect(parseSyllable(word), isNull, reason: '"$word" không nên tách được');
    }
  });

  test('Tách 1 dòng "tiếng1 tiếng2 [emoji]" thành từ ghép', () {
    final r1 = parseCompoundWordLine('bờ đê');
    expect(r1.word?.word, 'bờ đê');
    expect(r1.word?.emoji, '📚');

    final r2 = parseCompoundWordLine('cá rô 🐟');
    expect(r2.word?.word, 'cá rô');
    expect(r2.word?.emoji, '🐟');

    final r3 = parseCompoundWordLine('xyz đê');
    expect(r3.word, isNull);
    expect(r3.error, isNotNull);

    final r4 = parseCompoundWordLine('   ');
    expect(r4.word, isNull);
    expect(r4.error, isNull);
  });
}
