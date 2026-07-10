import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Bọc speech_to_text để nghe bé đọc và so khớp với chữ mục tiêu.
class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool get isListening => _speech.isListening;

  /// Khởi tạo & xin quyền mic/nhận diện giọng nói. Trả về true nếu dùng được.
  Future<bool> init() async {
    if (_available) return true;
    _available = await _speech.initialize(
      onError: (e) {},
      onStatus: (s) {},
    );
    return _available;
  }

  /// Tìm mã ngôn ngữ tiếng Việt mà máy hỗ trợ (vi_VN / vi-VN...).
  Future<String?> _vietnameseLocale() async {
    try {
      final locales = await _speech.locales();
      for (final l in locales) {
        if (l.localeId.toLowerCase().startsWith('vi')) return l.localeId;
      }
    } catch (_) {}
    return 'vi_VN';
  }

  /// Bắt đầu nghe. [onFinal] được gọi với câu bé đọc (đã nhận diện xong).
  /// [onPartial] cập nhật liên tục để hiển thị bé đang đọc gì.
  Future<void> listen({
    required void Function(String words) onFinal,
    void Function(String words)? onPartial,
  }) async {
    final ok = await init();
    if (!ok) return;
    final locale = await _vietnameseLocale();
    await _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        if (r.finalResult) {
          onFinal(r.recognizedWords);
        } else {
          onPartial?.call(r.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: locale,
        listenFor: const Duration(seconds: 6),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  Future<void> stop() async {
    if (_speech.isListening) await _speech.stop();
  }
}

/// So khớp chữ bé đọc với chữ mục tiêu (bỏ dấu câu, không phân biệt hoa thường).
bool matchesTarget(String spoken, String target) {
  String norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[.,!?;:"’‘]'), '')
      .trim();
  final s = norm(spoken);
  final t = norm(target);
  if (s.isEmpty) return false;
  // Đúng nếu bé đọc trúng từ mục tiêu (có thể lẫn trong câu dài hơn).
  final words = s.split(RegExp(r'\s+'));
  return s == t || words.contains(t) || s.contains(t);
}
