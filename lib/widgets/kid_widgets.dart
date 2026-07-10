import 'package:flutter/material.dart';

import '../services/tts_service.dart';
import '../theme.dart';

/// Thanh tiêu đề đơn giản, nút quay lại to cho bé dễ bấm.
class KidAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color color;
  final List<KidAppBarAction>? actions;
  const KidAppBar({
    super.key,
    required this.title,
    required this.color,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _RoundButton(
              color: color,
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            if (actions == null || actions!.isEmpty)
              const SizedBox(width: 52)
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < actions!.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _RoundButton(
                      color: color,
                      icon: actions![i].icon,
                      onTap: actions![i].onTap,
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Một hành động (icon + callback) hiện ở góc phải của [KidAppBar].
class KidAppBarAction {
  final IconData icon;
  final VoidCallback onTap;
  const KidAppBarAction(this.icon, this.onTap);
}

class _RoundButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Nút bấm bo tròn, to, nhiều màu — kèm icon và nhãn.
class KidButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;
  final double fontSize;
  const KidButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.fontSize = 20,
  });

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: widget.fontSize + 4),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: widget.fontSize,
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

/// Nền chấm bi nhẹ nhàng cho các màn hình.
class KidScaffold extends StatelessWidget {
  final Color color;
  final String title;
  final Widget body;
  final List<KidAppBarAction>? actions;
  const KidScaffold({
    super.key,
    required this.color,
    required this.title,
    required this.body,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(color.withValues(alpha: 0.16), AppColors.background),
              AppColors.background,
            ],
            stops: const [0.0, 0.45],
          ),
        ),
        child: Column(
          children: [
            KidAppBar(title: title, color: color, actions: actions),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: TtsService.instance.loading,
                builder: (_, loading, child) => Stack(
                  children: [
                    // Chặn chạm khi đang tạo giọng để tránh double-tap.
                    AbsorbPointer(absorbing: loading, child: child!),
                    if (loading)
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(child: _TtsLoadingBadge(color: color)),
                      ),
                  ],
                ),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge nhỏ báo "đang tạo giọng đọc..." hiện ở đỉnh màn hình.
class _TtsLoadingBadge extends StatelessWidget {
  final Color color;
  const _TtsLoadingBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Đang tạo giọng đọc...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Làm mờ dần mép phải của một dải cuộn ngang để gợi ý còn kéo được.
class FadeRight extends StatelessWidget {
  final Widget child;
  const FadeRight({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.white, Colors.white, Colors.transparent],
        stops: [0.0, 0.9, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: child,
    );
  }
}
