import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_data.dart';

/// 1 buổi học bố mẹ tự nhập (gõ tay hoặc chụp ảnh nhờ AI đọc), gồm nhiều
/// từ ghép. Lưu lại để đọc lại bất cứ lúc nào.
class Lesson {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<CompoundWord> words;

  const Lesson({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.words,
  });

  Lesson copyWith({String? title, List<CompoundWord>? words}) => Lesson(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        words: words ?? this.words,
      );
}

/// Lưu danh sách [Lesson] trên máy (SharedPreferences), để bố mẹ xem lại
/// bài cũ bất cứ khi nào cần.
class LessonsStore {
  LessonsStore._();
  static final LessonsStore instance = LessonsStore._();

  static const _key = 'lessons_v1';

  Map<String, dynamic> _syllableToJson(SyllableSpec s) => {
        'letter': s.letter,
        'sound': s.sound,
        'vowel': s.vowel,
        'tone': s.tone,
        'coda': s.coda,
      };

  SyllableSpec? _syllableFromJson(Map<String, dynamic> m) {
    final vowel = m['vowel'] as String?;
    final tone = m['tone'] as int?;
    final coda = (m['coda'] as String?) ?? '';
    if (vowel == null || tone == null) return null;
    if (!tonedVowels.containsKey(vowel)) return null;
    if (tone < 0 || tone > 5) return null;
    if (coda.isNotEmpty && !validFinals.contains(coda)) return null;
    return SyllableSpec(
      (m['letter'] as String?) ?? '',
      (m['sound'] as String?) ?? vowel,
      vowel,
      tone,
      coda,
    );
  }

  Map<String, dynamic> _wordToJson(CompoundWord w) => {
        'emoji': w.emoji,
        'syllables': w.syllables.map(_syllableToJson).toList(),
      };

  CompoundWord? _wordFromJson(Map<String, dynamic> m) {
    final raw = m['syllables'] as List<dynamic>?;
    if (raw == null || raw.length != 2) return null;
    final syllables = raw
        .map((e) => _syllableFromJson(e as Map<String, dynamic>))
        .toList();
    if (syllables.any((s) => s == null)) return null;
    final emoji = (m['emoji'] as String?)?.trim();
    return CompoundWord(
      (emoji?.isNotEmpty ?? false) ? emoji! : '📚',
      syllables.cast<SyllableSpec>(),
    );
  }

  Map<String, dynamic> _lessonToJson(Lesson l) => {
        'id': l.id,
        'title': l.title,
        'createdAt': l.createdAt.millisecondsSinceEpoch,
        'words': l.words.map(_wordToJson).toList(),
      };

  Lesson? _lessonFromJson(Map<String, dynamic> m) {
    final id = m['id'] as String?;
    final title = m['title'] as String?;
    final createdAtMs = m['createdAt'] as int?;
    final rawWords = m['words'] as List<dynamic>?;
    if (id == null || title == null || createdAtMs == null || rawWords == null) {
      return null;
    }
    final words = rawWords
        .map((e) => _wordFromJson(e as Map<String, dynamic>))
        .whereType<CompoundWord>()
        .toList();
    return Lesson(
      id: id,
      title: title,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      words: words,
    );
  }

  Future<List<Lesson>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final lessons = list
          .map((e) => _lessonFromJson(e as Map<String, dynamic>))
          .whereType<Lesson>()
          .toList();
      lessons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return lessons;
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<Lesson> lessons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(lessons.map(_lessonToJson).toList()));
  }

  Future<Lesson> addLesson(String title, List<CompoundWord> words) async {
    final lesson = Lesson(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? 'Bài chưa đặt tên' : title.trim(),
      createdAt: DateTime.now(),
      words: words,
    );
    final current = await load();
    current.insert(0, lesson);
    await _save(current);
    return lesson;
  }

  /// Thêm từ vào 1 bài đã có (dùng khi gõ tiếp/lưu tiếp vào cùng 1 bài).
  Future<void> appendWords(String lessonId, List<CompoundWord> words) async {
    if (words.isEmpty) return;
    final current = await load();
    final i = current.indexWhere((l) => l.id == lessonId);
    if (i == -1) return;
    current[i] = current[i].copyWith(words: [...current[i].words, ...words]);
    await _save(current);
  }

  Future<void> removeLesson(String id) async {
    final current = await load();
    current.removeWhere((l) => l.id == id);
    await _save(current);
  }

  /// Xoá 1 từ trong bài theo vị trí; nếu bài hết từ thì xoá luôn cả bài.
  Future<void> removeWord(String lessonId, int wordIndex) async {
    final current = await load();
    final i = current.indexWhere((l) => l.id == lessonId);
    if (i == -1) return;
    final words = List<CompoundWord>.from(current[i].words);
    if (wordIndex < 0 || wordIndex >= words.length) return;
    words.removeAt(wordIndex);
    if (words.isEmpty) {
      current.removeAt(i);
    } else {
      current[i] = current[i].copyWith(words: words);
    }
    await _save(current);
  }
}
