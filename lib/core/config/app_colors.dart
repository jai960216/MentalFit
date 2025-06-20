import 'package:flutter/material.dart';

class AppColors {
  // 기본 색상
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03A9F4);
  static const Color accent = Color(0xFF00BCD4);

  // 라이트 모드 색상
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

  // 다크 모드 색상
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextHint = Color(0xFF666666);
  static const Color darkDivider = Color(0xFF424242);
  static const Color darkBorder = Color(0xFF424242);
  static const Color darkShadow = Color(0x40000000);
  static const Color darkCardShadow = Color(0x20000000);

  // 다크 모드 상태 배경 색상
  static const Color darkSuccessLight = Color(0xFF1B3A1B);
  static const Color darkWarningLight = Color(0xFF3A2F1B);
  static const Color darkErrorLight = Color(0xFF3A1B1B);
  static const Color darkInfoLight = Color(0xFF1B2A3A);

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

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBackground, darkSurface],
  );

  // 투명도
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
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
