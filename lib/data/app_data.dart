// Dữ liệu tiếng Việt cho app học đánh vần (chương trình lớp 1).

/// Một chữ cái trong bảng chữ cái.
class LetterItem {
  final String upper; // chữ hoa: A
  final String lower; // chữ thường: a
  final String name; // tên chữ để đọc: "a", "bê", "xê"...
  final String sound; // âm (cách đọc khi đánh vần): "a", "bờ", "cờ"...
  final String exampleWord; // từ ví dụ: "bà", "cá"
  final String emoji; // hình minh hoạ

  const LetterItem({
    required this.upper,
    required this.lower,
    required this.name,
    required this.sound,
    required this.exampleWord,
    required this.emoji,
  });
}

/// 29 chữ cái tiếng Việt.
const List<LetterItem> alphabet = [
  LetterItem(upper: 'A', lower: 'a', name: 'a', sound: 'a', exampleWord: 'bà', emoji: '👵'),
  LetterItem(upper: 'Ă', lower: 'ă', name: 'á', sound: 'á', exampleWord: 'ăn', emoji: '🍚'),
  LetterItem(upper: 'Â', lower: 'â', name: 'ớ', sound: 'ớ', exampleWord: 'mây', emoji: '☁️'),
  LetterItem(upper: 'B', lower: 'b', name: 'bê', sound: 'bờ', exampleWord: 'bóng', emoji: '⚽'),
  LetterItem(upper: 'C', lower: 'c', name: 'xê', sound: 'cờ', exampleWord: 'cá', emoji: '🐟'),
  LetterItem(upper: 'D', lower: 'd', name: 'dê', sound: 'dờ', exampleWord: 'dê', emoji: '🐐'),
  LetterItem(upper: 'Đ', lower: 'đ', name: 'đê', sound: 'đờ', exampleWord: 'đèn', emoji: '💡'),
  LetterItem(upper: 'E', lower: 'e', name: 'e', sound: 'e', exampleWord: 'xe', emoji: '🚗'),
  LetterItem(upper: 'Ê', lower: 'ê', name: 'ê', sound: 'ê', exampleWord: 'bê', emoji: '🐄'),
  LetterItem(upper: 'G', lower: 'g', name: 'giê', sound: 'gờ', exampleWord: 'gà', emoji: '🐔'),
  LetterItem(upper: 'H', lower: 'h', name: 'hát', sound: 'hờ', exampleWord: 'hoa', emoji: '🌸'),
  LetterItem(upper: 'I', lower: 'i', name: 'i', sound: 'i', exampleWord: 'bi', emoji: '🔵'),
  LetterItem(upper: 'K', lower: 'k', name: 'ca', sound: 'cờ', exampleWord: 'kem', emoji: '🍦'),
  LetterItem(upper: 'L', lower: 'l', name: 'e-lờ', sound: 'lờ', exampleWord: 'lá', emoji: '🍃'),
  LetterItem(upper: 'M', lower: 'm', name: 'em-mờ', sound: 'mờ', exampleWord: 'mèo', emoji: '🐱'),
  LetterItem(upper: 'N', lower: 'n', name: 'en-nờ', sound: 'nờ', exampleWord: 'nón', emoji: '👒'),
  LetterItem(upper: 'O', lower: 'o', name: 'o', sound: 'o', exampleWord: 'bò', emoji: '🐄'),
  LetterItem(upper: 'Ô', lower: 'ô', name: 'ô', sound: 'ô', exampleWord: 'ô', emoji: '☂️'),
  LetterItem(upper: 'Ơ', lower: 'ơ', name: 'ơ', sound: 'ơ', exampleWord: 'cờ', emoji: '🚩'),
  LetterItem(upper: 'P', lower: 'p', name: 'pê', sound: 'pờ', exampleWord: 'pin', emoji: '🔋'),
  LetterItem(upper: 'Q', lower: 'q', name: 'quy', sound: 'quờ', exampleWord: 'quả', emoji: '🍎'),
  LetterItem(upper: 'R', lower: 'r', name: 'e-rờ', sound: 'rờ', exampleWord: 'rùa', emoji: '🐢'),
  LetterItem(upper: 'S', lower: 's', name: 'ét-sờ', sound: 'sờ', exampleWord: 'sao', emoji: '⭐'),
  LetterItem(upper: 'T', lower: 't', name: 'tê', sound: 'tờ', exampleWord: 'táo', emoji: '🍎'),
  LetterItem(upper: 'U', lower: 'u', name: 'u', sound: 'u', exampleWord: 'cú', emoji: '🦉'),
  LetterItem(upper: 'Ư', lower: 'ư', name: 'ư', sound: 'ư', exampleWord: 'sư tử', emoji: '🦁'),
  LetterItem(upper: 'V', lower: 'v', name: 'vê', sound: 'vờ', exampleWord: 'vịt', emoji: '🦆'),
  LetterItem(upper: 'X', lower: 'x', name: 'ích-xì', sound: 'xờ', exampleWord: 'xe', emoji: '🚗'),
  LetterItem(upper: 'Y', lower: 'y', name: 'i-dài', sound: 'i', exampleWord: 'cây', emoji: '🌳'),
];

/// Âm đầu dùng cho ghép vần. Đã chọn các phụ âm không vướng luật
/// chính tả c/k/g/gh/ng/ngh để bé không bị nhầm khi ghép với mọi nguyên âm.
class Initial {
  final String letter; // chữ viết: "b", "th"
  final String sound; // đọc âm: "bờ", "thờ"
  const Initial(this.letter, this.sound);
}

const List<Initial> initials = [
  Initial('b', 'bờ'),
  Initial('ch', 'chờ'),
  Initial('d', 'dờ'),
  Initial('đ', 'đờ'),
  Initial('h', 'hờ'),
  Initial('kh', 'khờ'),
  Initial('l', 'lờ'),
  Initial('m', 'mờ'),
  Initial('n', 'nờ'),
  Initial('nh', 'nhờ'),
  Initial('ph', 'phờ'),
  Initial('r', 'rờ'),
  Initial('s', 'sờ'),
  Initial('t', 'tờ'),
  Initial('th', 'thờ'),
  Initial('v', 'vờ'),
  Initial('x', 'xờ'),
];

/// Nguyên âm đơn có thể đứng làm vần (đọc được khi ghép, thanh ngang).
const List<String> vowels = ['a', 'e', 'ê', 'i', 'o', 'ô', 'ơ', 'u', 'ư'];

/// Nguyên âm kèm 6 thanh, theo thứ tự: ngang, sắc, huyền, hỏi, ngã, nặng.
/// Dùng để ghép dấu vào tiếng khi đánh vần (b + ô + sắc = bố).
const Map<String, List<String>> tonedVowels = {
  'a': ['a', 'á', 'à', 'ả', 'ã', 'ạ'],
  // ă, â chỉ xuất hiện trong tiếng có âm cuối (ăn, âm...), không đứng 1 mình.
  'ă': ['ă', 'ắ', 'ằ', 'ẳ', 'ẵ', 'ặ'],
  'â': ['â', 'ấ', 'ầ', 'ẩ', 'ẫ', 'ậ'],
  'e': ['e', 'é', 'è', 'ẻ', 'ẽ', 'ẹ'],
  'ê': ['ê', 'ế', 'ề', 'ể', 'ễ', 'ệ'],
  'i': ['i', 'í', 'ì', 'ỉ', 'ĩ', 'ị'],
  'o': ['o', 'ó', 'ò', 'ỏ', 'õ', 'ọ'],
  'ô': ['ô', 'ố', 'ồ', 'ổ', 'ỗ', 'ộ'],
  'ơ': ['ơ', 'ớ', 'ờ', 'ở', 'ỡ', 'ợ'],
  'u': ['u', 'ú', 'ù', 'ủ', 'ũ', 'ụ'],
  'ư': ['ư', 'ứ', 'ừ', 'ử', 'ữ', 'ự'],
};

/// Một thanh (dấu). [name] để đọc/nói, [sample] là chữ mẫu hiện trên nút chọn.
class Tone {
  final String name; // "ngang", "sắc", "huyền"...
  final String sample; // chữ mẫu hiện trên nút: a, á, à, ả, ã, ạ
  const Tone(this.name, this.sample);
}

/// 6 thanh theo thứ tự chuẩn.
const List<Tone> tones6 = [
  Tone('ngang', 'a'),
  Tone('sắc', 'á'),
  Tone('huyền', 'à'),
  Tone('hỏi', 'ả'),
  Tone('ngã', 'ã'),
  Tone('nặng', 'ạ'),
];

/// Ghép tiếng có dấu: âm đầu + nguyên âm + chỉ số thanh.
/// Vd: buildSyllable(Initial('b','bờ'), 'ô', 1) => 'bố'.
String buildSyllable(String initialLetter, String vowel, int toneIndex) {
  final v = tonedVowels[vowel]?[toneIndex] ?? vowel;
  return '$initialLetter$v';
}

/// 8 âm cuối hợp lệ trong tiếng Việt (không có âm cuối nào khác).
const Set<String> validFinals = {'c', 'ch', 'm', 'n', 'ng', 'nh', 'p', 't'};

/// Từ mẫu minh hoạ cho một tiếng (để bé thấy tiếng đó dùng trong từ thật).
class WordExample {
  final String emoji;
  final String phrase; // "bố của em"
  const WordExample(this.emoji, this.phrase);
}

/// Bảng từ ghép mẫu cho các tiếng thật hay gặp (đều ghép được từ âm đầu + vần + dấu ở trên).
/// Mỗi tiếng có một từ ghép/từ thật để bé thấy chữ vừa đánh vần dùng trong từ.
const Map<String, WordExample> syllableExamples = {
  // b
  'ba': WordExample('👨', 'ba má'),
  'bà': WordExample('👵', 'bà ngoại'),
  'bá': WordExample('👑', 'bá chủ'),
  'bé': WordExample('👶', 'em bé'),
  'bè': WordExample('🛶', 'bạn bè'),
  'bể': WordExample('🐠', 'bể cá'),
  'bò': WordExample('🐄', 'bò sữa'),
  'bó': WordExample('💐', 'bó hoa'),
  'bố': WordExample('👨', 'bố mẹ'),
  'bô': WordExample('🚼', 'cái bô'),
  'bơ': WordExample('🥑', 'quả bơ'),
  'bơi': WordExample('🏊', 'bơi lội'),
  'bú': WordExample('🍼', 'bú sữa'),
  // ch
  'cha': WordExample('👨', 'cha mẹ'),
  'chả': WordExample('🍢', 'chả giò'),
  'chè': WordExample('🍧', 'ăn chè'),
  'cho': WordExample('🎁', 'cho quà'),
  'chó': WordExample('🐕', 'chó con'),
  'chê': WordExample('🙅', 'chê bai'),
  // d / đ
  'da': WordExample('🧴', 'làn da'),
  'dì': WordExample('👩', 'cô dì'),
  'dê': WordExample('🐐', 'dê con'),
  'dế': WordExample('🦗', 'dế mèn'),
  'dỗ': WordExample('🤱', 'dỗ dành'),
  'dù': WordExample('🌂', 'cái dù'),
  'đá': WordExample('🪨', 'đá bóng'),
  'đà': WordExample('🦩', 'đà điểu'),
  'để': WordExample('📥', 'để dành'),
  'đề': WordExample('📝', 'đề bài'),
  'đê': WordExample('🌊', 'con đê'),
  'đỏ': WordExample('🔴', 'màu đỏ'),
  'đô': WordExample('💵', 'đô la'),
  'đủ': WordExample('✅', 'đầy đủ'),
  // h
  'hà': WordExample('🦛', 'hà mã'),
  'hè': WordExample('☀️', 'mùa hè'),
  'hồ': WordExample('🌊', 'hồ nước'),
  'hổ': WordExample('🐯', 'hổ báo'),
  'hoa': WordExample('🌸', 'bông hoa'),
  // kh
  'khi': WordExample('🐒', 'con khi'),
  'khỉ': WordExample('🐵', 'khỉ con'),
  'kho': WordExample('🏚️', 'nhà kho'),
  'khô': WordExample('🐟', 'cá khô'),
  // l
  'lá': WordExample('🍃', 'lá cây'),
  'lê': WordExample('🍐', 'quả lê'),
  'lễ': WordExample('🎉', 'lễ hội'),
  'li': WordExample('🥛', 'cái li'),
  'lò': WordExample('🔥', 'lò nướng'),
  'lọ': WordExample('🏺', 'cái lọ'),
  // m
  'má': WordExample('👩', 'ba má'),
  'me': WordExample('🌳', 'cây me'),
  'mè': WordExample('🌰', 'hạt mè'),
  'mẹ': WordExample('👩', 'mẹ con'),
  'mì': WordExample('🍜', 'mì tôm'),
  'mỡ': WordExample('🥓', 'thịt mỡ'),
  'mơ': WordExample('🍑', 'quả mơ'),
  // n / nh
  'na': WordExample('🍈', 'quả na'),
  'nơ': WordExample('🎀', 'cái nơ'),
  'nho': WordExample('🍇', 'quả nho'),
  'nhà': WordExample('🏠', 'nhà cửa'),
  // ph
  'phà': WordExample('⛴️', 'bến phà'),
  'phê': WordExample('☕', 'cà phê'),
  'phở': WordExample('🍜', 'phở bò'),
  // r
  'rá': WordExample('🧺', 'rổ rá'),
  'rễ': WordExample('🌱', 'rễ cây'),
  'rổ': WordExample('🧺', 'cái rổ'),
  'rùa': WordExample('🐢', 'con rùa'),
  // s
  'sò': WordExample('🐚', 'con sò'),
  'sư': WordExample('🦁', 'sư tử'),
  'sổ': WordExample('📔', 'cuốn sổ'),
  // t / th
  'ta': WordExample('🤝', 'chúng ta'),
  'to': WordExample('🐘', 'to lớn'),
  'tô': WordExample('🍜', 'cái tô'),
  'tơ': WordExample('🧵', 'sợi tơ'),
  'tủ': WordExample('🚪', 'tủ lạnh'),
  'thỏ': WordExample('🐰', 'thỏ con'),
  'thơ': WordExample('📖', 'bài thơ'),
  'thư': WordExample('✉️', 'lá thư'),
  'thợ': WordExample('👷', 'thợ mộc'),
  // v
  'vé': WordExample('🎫', 'vé xe'),
  'vẽ': WordExample('🎨', 'vẽ tranh'),
  'ví': WordExample('👛', 'ví tiền'),
  'võ': WordExample('🥋', 'võ thuật'),
  'vở': WordExample('📓', 'vở viết'),
  'vô': WordExample('🚪', 'đi vô'),
  // x
  'xà': WordExample('🧼', 'xà phòng'),
  'xe': WordExample('🚗', 'xe đạp'),
  'xô': WordExample('🪣', 'cái xô'),
  'xu': WordExample('🪙', 'đồng xu'),
};

/// Một nhóm âm tiết để luyện dấu thanh. 6 dạng theo thứ tự:
/// ngang, sắc, huyền, hỏi, ngã, nặng.
class ToneSet {
  final List<String> forms; // [ma, má, mà, mả, mã, mạ]
  const ToneSet(this.forms);
}

/// Tên 6 thanh (dấu) và ký hiệu.
const List<String> toneNames = [
  'thanh ngang',
  'dấu sắc',
  'dấu huyền',
  'dấu hỏi',
  'dấu ngã',
  'dấu nặng',
];

const List<String> toneMarks = ['', '´', '̀', '?', '~', '.'];

const List<ToneSet> toneSets = [
  ToneSet(['ma', 'má', 'mà', 'mả', 'mã', 'mạ']),
  ToneSet(['ba', 'bá', 'bà', 'bả', 'bã', 'bạ']),
  ToneSet(['la', 'lá', 'là', 'lả', 'lã', 'lạ']),
  ToneSet(['na', 'ná', 'nà', 'nả', 'nã', 'nạ']),
  ToneSet(['va', 'vá', 'và', 'vả', 'vã', 'vạ']),
  ToneSet(['be', 'bé', 'bè', 'bẻ', 'bẽ', 'bẹ']),
  ToneSet(['co', 'có', 'cò', 'cỏ', 'cõ', 'cọ']),
  ToneSet(['da', 'dá', 'dà', 'dả', 'dã', 'dạ']),
];

/// Một từ có hình minh hoạ.
class WordItem {
  final String word;
  final String emoji;
  const WordItem(this.word, this.emoji);
}

const List<WordItem> pictureWords = [
  // Con vật
  WordItem('gà', '🐔'),
  WordItem('mèo', '🐱'),
  WordItem('chó', '🐕'),
  WordItem('cá', '🐟'),
  WordItem('bò', '🐄'),
  WordItem('voi', '🐘'),
  WordItem('gấu', '🐻'),
  WordItem('cua', '🦀'),
  WordItem('ong', '🐝'),
  WordItem('vịt', '🦆'),
  WordItem('rùa', '🐢'),
  WordItem('ngựa', '🐴'),
  // Trái cây - đồ ăn
  WordItem('táo', '🍎'),
  WordItem('chuối', '🍌'),
  WordItem('nho', '🍇'),
  WordItem('cam', '🍊'),
  WordItem('dưa', '🍉'),
  WordItem('kem', '🍦'),
  WordItem('bánh', '🍞'),
  WordItem('cà rốt', '🥕'),
  // Đồ vật - thiên nhiên
  WordItem('xe', '🚗'),
  WordItem('tàu', '🚂'),
  WordItem('nhà', '🏠'),
  WordItem('cây', '🌳'),
  WordItem('hoa', '🌸'),
  WordItem('sao', '⭐'),
  WordItem('mưa', '🌧️'),
  WordItem('trăng', '🌙'),
  WordItem('bóng', '⚽'),
  WordItem('nón', '👒'),
  // Người thân
  WordItem('bé', '👶'),
  WordItem('bà', '👵'),
  WordItem('ông', '👴'),
  WordItem('mẹ', '👩'),
  WordItem('bố', '👨'),
];

/// Một tiếng trong từ ghép, đủ thông tin để đánh vần riêng tiếng đó.
/// Vd: SyllableSpec('b', 'bờ', 'ơ', 0) => tiếng "bờ" (âm đầu b, vần ơ, thanh ngang).
/// [coda] là âm cuối (vd "n" trong "con"), để trống '' nếu tiếng mở.
class SyllableSpec {
  final String letter; // chữ viết âm đầu: "b", "đ", "c", "g"...
  final String sound; // đọc âm: "bờ", "đờ", "cờ", "gờ"...
  final String vowel; // nguyên âm (không âm cuối): "ơ", "ê", "a"...
  final int tone; // chỉ số thanh trong tones6 (0=ngang...5=nặng)
  final String coda; // âm cuối: '', 'c','ch','m','n','ng','nh','p','t'

  const SyllableSpec(this.letter, this.sound, this.vowel, this.tone, [this.coda = '']);

  /// Đọc âm cuối (dùng chung bảng đọc phụ âm với âm đầu).
  static const Map<String, String> _consonantSound = {
    'b': 'bờ', 'c': 'cờ', 'ch': 'chờ', 'd': 'dờ', 'đ': 'đờ', 'g': 'gờ', 'gi': 'giờ',
    'h': 'hờ', 'k': 'cờ', 'kh': 'khờ', 'l': 'lờ', 'm': 'mờ', 'n': 'nờ', 'ng': 'ngờ',
    'ngh': 'ngờ', 'nh': 'nhờ', 'p': 'pờ', 'ph': 'phờ', 'qu': 'quờ', 'r': 'rờ',
    's': 'sờ', 't': 'tờ', 'th': 'thờ', 'tr': 'trờ', 'v': 'vờ', 'x': 'xờ',
  };

  /// Vần (nguyên âm + âm cuối, chưa có dấu): "ơ" hoặc "on", "anh"...
  String get rime => '$vowel$coda';

  /// Tiếng chưa có dấu: "bơ" hoặc "con", "canh"...
  String get base => '$letter$rime';

  String get syllable => '$letter${tonedVowels[vowel]![tone]}$coda';

  /// Đánh vần riêng tiếng này.
  /// - Tiếng mở: "bờ - ơ - bờ" hoặc "đờ - ê - đê - huyền - đề".
  /// - Tiếng có âm cuối: "o - n - on - cờ - on - con" hoặc thêm dấu:
  ///   "o - n - on - cờ - on - con - huyền - còn".
  List<String> get spellParts {
    if (coda.isEmpty) {
      return tone == 0
          ? [sound, vowel, base]
          : [sound, vowel, base, tones6[tone].name, syllable];
    }
    final codaSound = _consonantSound[coda] ?? coda;
    // Không có âm đầu (vd "ăn"): chỉ cần đánh vần phần vần, không ghép thêm.
    final steps = letter.isEmpty
        ? [vowel, codaSound, rime]
        : [vowel, codaSound, rime, sound, rime, base];
    return tone == 0 ? steps : [...steps, tones6[tone].name, syllable];
  }
}

/// Một từ ghép 2 tiếng để bé luyện đánh vần nối tiếng, vd "bờ đê".
class CompoundWord {
  final String emoji;
  final List<SyllableSpec> syllables;
  const CompoundWord(this.emoji, this.syllables);

  String get word => syllables.map((s) => s.syllable).join(' ');
}

/// Câu khen khi bé làm đúng / chạm chữ.
const List<String> praises = [
  'Giỏi quá!',
  'Tuyệt vời!',
  'Con giỏi lắm!',
  'Đúng rồi!',
  'Xuất sắc!',
  'Hoan hô!',
];
