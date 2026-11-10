import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const fab = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryBright],
  );

  static const chartArea = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x407C5CFF), Color(0x007C5CFF)],
  );

  static const glass = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x0FFFFFFF), Color(0x05FFFFFF)],
  );

  static const activePill = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0x267C5CFF), Color(0x26B85CFF)],
  );

  static const moneyText = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.textPrimary, Color(0xFFC8BFFF)],
  );
}
