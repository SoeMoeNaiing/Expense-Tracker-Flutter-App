import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const spring = Duration(milliseconds: 600);
  static const stagger = Duration(milliseconds: 40);

  static const curveFast = Curves.easeOutCubic;
  static const curveMedium = Curves.easeOutQuint;
  static const curveSlow = Curves.easeInOutCubic;
  static const curveSpring = Cubic(0.34, 1.56, 0.64, 1);
}
