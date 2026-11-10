import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const String _sora = 'Sora';
  static const String _inter = 'Inter';

  static TextTheme textTheme() {
    // Side effect: registers & fetches the fonts. Return values discarded
    // on purpose — we build TextStyle by family name below so we never
    // touch the return type (which resolves oddly when extra UI packages
    // exist in the dependency graph).
    GoogleFonts.sora();
    GoogleFonts.inter();

    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: _sora,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      headlineLarge: TextStyle(
        fontFamily: _sora,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: _sora,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: _inter,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: _inter,
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: _inter,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: _inter,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: AppColors.textTertiary,
      ),
    );
  }
}
