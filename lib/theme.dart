import 'package:flutter/material.dart';

/// Bảng màu tươi sáng, thân thiện với trẻ em.
class AppColors {
  static const Color background = Color(0xFFFFF8E7); // vàng kem nhạt
  static const Color primary = Color(0xFFFF7043); // cam san hô
  static const Color letters = Color(0xFFEF5350); // đỏ
  static const Color blending = Color(0xFF42A5F5); // xanh dương
  static const Color tones = Color(0xFFAB47BC); // tím
  static const Color words = Color(0xFF66BB6A); // xanh lá
  static const Color sunny = Color(0xFFFFCA28); // vàng
  static const Color compound = Color(0xFF26C6DA); // xanh ngọc (bài học)
  static const Color ink = Color(0xFF3E2723); // nâu đậm cho chữ

  static const List<Color> tileColors = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF66BB6A),
    Color(0xFFFFA726),
    Color(0xFF26C6DA),
    Color(0xFFEC407A),
    Color(0xFF5C6BC0),
  ];
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
    );
  }
}
