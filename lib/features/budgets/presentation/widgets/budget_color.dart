import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Semantic color by progress ratio:
///   < 80%  → mint   (comfortable)
///   80–100 → amber  (warning)
///   > 100% → coral  (over)
Color budgetColor(double ratio) {
  if (ratio > 1.0) return AppColors.coral;
  if (ratio >= 0.8) return AppColors.amber;
  return AppColors.mint;
}
