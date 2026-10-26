import 'package:flutter/material.dart';

import 'core/theme/app_radius.dart';
import 'core/theme/app_spacing.dart';

abstract final class AppColors {
  static const paper = Color(0xFFF5F1E8);
  static const ink = Color(0xFF1E2421);
  static const inkMuted = Color(0xB31E2421);
  static const forest = Color(0xFF2E5B4E);
  static const forestTint = Color(0xFF91A99F);
  static const clay = Color(0xFFA8502B);
  static const rule = Color(0xFFD8D0BE);
  static const stop = Color(0xFFB3261E);
  static const handFill = Color(0xFFEDE5D0);
  static const illustrationFill = Color(0xFFEDE5D0);
  static const white = Colors.white;
}

abstract final class AppTheme {
  static ThemeData get light {
    final sans = const TextTheme().apply(fontFamily: 'SourceSans3');
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forest,
        onPrimary: AppColors.white,
        secondary: AppColors.clay,
        error: AppColors.clay,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
      ),
      textTheme: sans.copyWith(
        bodyLarge: sans.bodyLarge?.copyWith(color: AppColors.ink, fontSize: 18),
        bodyMedium: sans.bodyMedium?.copyWith(
          color: AppColors.ink,
          fontSize: 15,
        ),
        bodySmall: sans.bodySmall?.copyWith(
          color: AppColors.inkMuted,
          fontSize: 13,
        ),
        labelLarge: sans.labelLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 17,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: EdgeInsets.all(AppSpace.s16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.snackBar)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        modalBackgroundColor: AppColors.paper,
        elevation: 0,
        modalElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dividerColor: AppColors.rule,
      splashFactory: NoSplash.splashFactory,
    );
  }

  static TextStyle serif(double size, {FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: 'SourceSerif4',
        fontSize: size,
        fontWeight: weight,
        color: AppColors.ink,
      );

  static TextStyle body({double size = 15, Color? color, FontWeight? weight}) =>
      TextStyle(
        fontFamily: 'SourceSans3',
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: weight,
      );

  static TextStyle get muted => body(color: AppColors.inkMuted);

  static TextStyle get splashTitle =>
      serif(AppSpace.splashTitleSize, weight: FontWeight.w700);

  static TextStyle get splashTagline =>
      body(size: AppSpace.splashTaglineSize, color: AppColors.inkMuted);

  static TextStyle get onboardingTitleM =>
      serif(AppSpace.onboardingTitleSize, weight: FontWeight.w700);

  static TextStyle get onboardingBody => body(size: AppSpace.splashTaglineSize);

  static TextStyle get caption =>
      body(size: AppSpace.onboardingCaptionSize, color: AppColors.inkMuted);

  static TextStyle get onboardingDeviceName =>
      body(size: AppSpace.onboardingDeviceNameSize, weight: FontWeight.w600);

  static TextStyle get onboardingDeviceStatus => body(
    size: AppSpace.onboardingDeviceStatusSize,
    color: AppColors.inkMuted,
  );

  static const onboardingPairedStatus = TextStyle(
    fontFamily: 'SourceSans3',
    fontSize: AppSpace.onboardingDeviceStatusSize,
    color: AppColors.forest,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get onboardingFailedStatus => body(
    size: AppSpace.onboardingDeviceStatusSize,
    color: AppColors.clay,
    weight: FontWeight.w600,
  );
}
