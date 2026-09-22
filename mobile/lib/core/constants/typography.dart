import 'package:flutter/material.dart';
import 'colors.dart';

class AppTypography {
  static TextStyle get headlineXl => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.onSurface,
  );

  static TextStyle get headlineXlMobile => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 34 / 26,
    letterSpacing: -0.52,
    color: AppColors.onSurface,
  );

  static TextStyle get headlineLg => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.36,
    color: AppColors.onSurface,
  );

  static TextStyle get headlineMd => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.2,
    color: AppColors.onSurface,
  );

  static TextStyle get headlineSm => TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  static TextStyle get bodyLg => TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  static TextStyle get bodyMd => TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurface,
  );

  static TextStyle get bodySm => TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle get labelLg => TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    color: AppColors.onSurface,
  );

  static TextStyle get labelMd => TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.24,
    color: AppColors.onSurface,
  );

  static TextStyle get labelSm => TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 14 / 10,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle get monoMetric => const TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 22 / 18,
    letterSpacing: -0.36,
    color: AppColors.primary,
  );
}
