import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_data.dart';

/// Lưu các từ ghép do bố mẹ tự thêm (nhập tay hoặc từ AI đọc ảnh) trên máy,
/// tách riêng khỏi danh sách [compoundWords] có sẵn trong app.
class CustomWordsStore {
  CustomWordsStore._();
  static final CustomWordsStore instance = CustomWordsStore._();

  static const _key = 'custom_compound_words_v1';

  Map<String, dynamic> _syllableToJson(SyllableSpec s) => {
        'letter': s.letter,
        'sound': s.sound,
        'vowel': s.vowel,
        'tone': s.tone,
      };

  SyllableSpec? _syllableFromJson(Map<String, dynamic> m) {
    final vowel = m['vowel'] as String?;
    final tone = m['tone'] as int?;
    if (vowel == null || tone == null) return null;
    if (!tonedVowels.containsKey(vowel)) return null;
    if (tone < 0 || tone > 5) return null;
    return SyllableSpec(
      (m['letter'] as String?) ?? '',
      (m['sound'] as String?) ?? vowel,
      vowel,
      tone,
    );
  }

  Map<String, dynamic> _wordToJson(CompoundWord w) => {
        'emoji': w.emoji,
        'syllables': w.syllables.map(_syllableToJson).toList(),
      };

  CompoundWord? _wordFromJson(Map<String, dynamic> m) {
    final rawSyllables = m['syllables'] as List<dynamic>?;
    if (rawSyllables == null || rawSyllables.length != 2) return null;
    final syllables = rawSyllables
        .map((e) => _syllableFromJson(e as Map<String, dynamic>))
        .toList();
    if (syllables.any((s) => s == null)) return null;
    return CompoundWord(
      (m['emoji'] as String?)?.trim().isNotEmpty == true
          ? m['emoji'] as String
          : '📚',
      syllables.cast<SyllableSpec>(),
    );
  }

  Future<List<CompoundWord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _wordFromJson(e as Map<String, dynamic>))
          .whereType<CompoundWord>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<CompoundWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(words.map(_wordToJson).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> add(CompoundWord word) async {
    final current = await load();
    current.add(word);
    await _save(current);
  }

  Future<void> addAll(List<CompoundWord> words) async {
    if (words.isEmpty) return;
    final current = await load();
    current.addAll(words);
    await _save(current);
  }

  Future<void> removeAt(int index) async {
    final current = await load();
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    await _save(current);
  }
}
