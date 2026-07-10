// Kiểm tra khởi động app và hiển thị 5 thẻ chức năng ở trang chủ.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:danh_van_tieng_viet/main.dart';

void main() {
  testWidgets('Trang chủ hiển thị 5 chức năng', (WidgetTester tester) async {
    // Khung test mặc định quá nhỏ để GridView build hết 5 thẻ; nới cao lên.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const BeDanhVanApp());
    await tester.pump();

    expect(find.text('Bé Đánh Vần'), findsOneWidget);
    expect(find.text('Học Chữ Cái'), findsOneWidget);
    expect(find.text('Đánh Vần'), findsOneWidget);
    expect(find.text('Dấu Thanh'), findsOneWidget);
    expect(find.text('Đọc Từ'), findsOneWidget);
    expect(find.text('Bài Học'), findsOneWidget);
  });
}
