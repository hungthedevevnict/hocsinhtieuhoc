import 'package:flutter/material.dart';

import '../theme.dart';
import 'blending_screen.dart';
import 'lessons_screen.dart';
import 'letters_screen.dart';
import 'tones_screen.dart';
import 'words_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu = [
      _MenuData(
        title: 'Học Chữ Cái',
        emoji: '🔤',
        color: AppColors.letters,
        builder: (_) => const LettersScreen(),
      ),
      _MenuData(
        title: 'Đánh Vần',
        emoji: '🧩',
        color: AppColors.blending,
        builder: (_) => const BlendingScreen(),
      ),
      _MenuData(
        title: 'Dấu Thanh',
        emoji: '🎵',
        color: AppColors.tones,
        builder: (_) => const TonesScreen(),
      ),
      _MenuData(
        title: 'Đọc Từ',
        emoji: '🖼️',
        color: AppColors.words,
        builder: (_) => const WordsScreen(),
      ),
      _MenuData(
        title: 'Từ Ghép',
        emoji: '🔗',
        color: AppColors.compound,
        builder: (_) => const LessonsScreen(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _Header(),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.92,
                  children: [
                    for (final item in menu) _MenuCard(data: item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Bé Đánh Vần',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Cùng học chữ với bé nào! 🌟',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _MenuData {
  final String title;
  final String emoji;
  final Color color;
  final WidgetBuilder builder;
  const _MenuData({
    required this.title,
    required this.emoji,
    required this.color,
    required this.builder,
  });
}

class _MenuCard extends StatefulWidget {
  final _MenuData data;
  const _MenuCard({required this.data});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: d.builder),
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(Colors.white.withValues(alpha: 0.22), d.color),
                Color.alphaBlend(Colors.black.withValues(alpha: 0.12), d.color),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: d.color.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(d.emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                d.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
