import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MeshBackground extends StatefulWidget {
  final Widget child;
  const MeshBackground({super.key, required this.child});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = reduceMotion
                    ? 0.5
                    : Curves.easeInOut.transform(_c.value);
                return CustomPaint(painter: _MeshPainter(t));
              },
            ),
          ),
        ),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final double t;
  const _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.bgBase);

    void blob(Offset c, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [color, color.withAlpha(0)])
            .createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    blob(
      Offset(size.width * (0.15 + 0.06 * t), size.height * (0.10 + 0.06 * t)),
      size.width * 0.70,
      AppColors.primary.withAlpha(26),
    );
    blob(
      Offset(size.width * (0.85 - 0.06 * t), size.height * (0.90 - 0.06 * t)),
      size.width * 0.80,
      AppColors.mint.withAlpha(18),
    );
    blob(
      Offset(size.width * (0.55 + 0.08 * t), size.height * (0.50 + 0.10 * t)),
      size.width * 0.50,
      AppColors.coral.withAlpha(13),
    );
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t;
}
