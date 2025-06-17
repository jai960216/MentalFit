import 'package:flutter/material.dart';

class AppColors {
  // 기본 색상
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03A9F4);
  static const Color accent = Color(0xFF00BCD4);

  // 배경 색상
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // 상태 색상
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // 상태 배경 색상
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color infoLight = Color(0xFFE3F2FD);

  // 구분선 색상
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);

  // 그림자 색상
  static const Color shadow = Color(0x1A000000);
  static const Color cardShadow = Color(0x0D000000);

  // 그레이스케일
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, white],
  );

  // 투명도
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // 테마 데이터
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        error: error,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shadowColor: cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
      ),
    );
  }

  // Material Colors
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Blue Colors
  static const Color lightBlue50 = Color(0xFFE3F2FD);
  static const Color lightBlue100 = Color(0xFFBBDEFB);
  static const Color lightBlue200 = Color(0xFF90CAF9);
  static const Color lightBlue300 = Color(0xFF64B5F6);
  static const Color lightBlue400 = Color(0xFF42A5F5);
  static const Color lightBlue500 = Color(0xFF2196F3);
  static const Color lightBlue600 = Color(0xFF1E88E5);
  static const Color lightBlue700 = Color(0xFF1976D2);
  static const Color lightBlue800 = Color(0xFF1565C0);
  static const Color lightBlue900 = Color(0xFF0D47A1);

  // Status Colors
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color pending = Color(0xFFFFA000);
  static const Color completed = Color(0xFF43A047);
  static const Color cancelled = Color(0xFFE53935);
}
