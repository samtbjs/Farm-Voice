import 'package:flutter/material.dart';

/// Core colors for the Farm Voice app.
///
/// Kept to a small, deliberate set: green for the "speak" action,
/// amber for the "scan" action, plus basic neutrals.
abstract class AppColors {
  static const Color green = Color(0xFF2E7D53);
  static const Color amber = Color(0xFFC77D1F);

  static const Color background = Color(0xFFF6F7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF23291F);
  static const Color textMuted = Color(0xFF5B6259);
  static const Color border = Color(0xFFDDE3D6);
}
