import 'package:flutter/material.dart';
import '../theme/theme_settings.dart';

class AppColors {
  static bool get isDark => ThemeSettings.isDark;

  // Brand Primary & Secondary (Stitch Specs)
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryDark = Color(0xFF0037B0);
  static const Color primaryContainer = Color(0xFF1D4ED8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFCAD3FF);

  static const Color secondary = Color(0xFF0284C7);
  static const Color secondaryContainer = Color(0xFF5BB8FE);
  static const Color onSecondaryContainer = Color(0xFF00476E);

  static const Color tertiary = Color(0xFF0F172A);
  static const Color tertiaryContainer = Color(0xFF545C72);

  // Dynamic Surfaces & Backgrounds
  static Color get surface => isDark ? const Color(0xFF090D16) : const Color(0xFFF8F9FF);
  static Color get surfaceLowest => isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  static Color get surfaceLow => isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF4FF);
  static Color get surfaceContainer => isDark ? const Color(0xFF1E293B) : const Color(0xFFE5EEFF);
  static Color get surfaceHigh => isDark ? const Color(0xFF334155) : const Color(0xFFDCE9FF);
  static Color get surfaceHighest => isDark ? const Color(0xFF475569) : const Color(0xFFD3E4FE);

  // Dynamic Text & Content
  static Color get onSurface => isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0B1C30);
  static Color get onSurfaceVariant => isDark ? const Color(0xFF94A3B8) : const Color(0xFF434655);
  static Color get outline => isDark ? const Color(0xFF64748B) : const Color(0xFF747686);
  static Color get outlineVariant => isDark ? const Color(0xFF334155) : const Color(0xFFC4C5D7);
  static Color get cardBorder => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  // Telemetry & Status Badges
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF065F46);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Dark Mode Foundations
  static const Color darkCanvas = Color(0xFF090D16);
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceHigh = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
}
