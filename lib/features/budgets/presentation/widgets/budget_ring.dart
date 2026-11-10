import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Animated circular progress ring. `ratio` is display-clamped to [0,1].
class BudgetRing extends StatelessWidget {
  final double ratio;
  final Color color;
  final double size;
  final double stroke;
  final bool over;

  const BudgetRing({
    super.key,
    required this.ratio,
    required this.color,
    this.size = 56,
    this.stroke = 5,
    this.over = false,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final pct = (ratio * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
        duration: reduceMotion
            ? const Duration(milliseconds: 1)
            : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (_, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _RingPainter(
                progress: value,
                color: color,
                stroke: stroke,
                over: over,
              ),
            ),
            Text(
              over ? '!' : '$pct%',
              style: TextStyle(
                fontSize: size * (over ? 0.30 : 0.24),
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;
  final bool over;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
    required this.over,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.borderSubtle;

    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    if (over) {
      // Full ring, add a small glow to signal over-budget.
      fg.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.stroke != stroke ||
      old.over != over;
}
