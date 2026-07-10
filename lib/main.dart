import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/tts_service.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Khởi động sẵn bộ đọc để lần chạm đầu tiên không bị trễ.
  TtsService.instance.init();
  runApp(const BeDanhVanApp());
}

class BeDanhVanApp extends StatelessWidget {
  const BeDanhVanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bé Đánh Vần',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
