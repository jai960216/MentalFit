import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (로고 기반)
  static const Color primary = Color(0xFF1E88E5); // 메인 블루
  static const Color secondary = Color(0xFF00BCD4); // 시안 블루
  static const Color accent = Color(0xFF4FC3F7); // 라이트 블루

  // Background Colors
  static const Color background = Color(0xFFF5F9FF); // 연한 배경
  static const Color surface = Color(0xFFFFFFFF); // 카드/표면

  // Text Colors
  static const Color textPrimary = Color(0xFF212121); // 메인 텍스트
  static const Color textSecondary = Color(0xFF757575); // 보조 텍스트
  static const Color textHint = Color(0xFFBDBDBD); // 힌트 텍스트

  // Functional Colors
  static const Color success = Color(0xFF4CAF50); // 성공
  static const Color warning = Color(0xFFFF9800); // 경고
  static const Color error = Color(0xFFF44336); // 에러
  static const Color info = Color(0xFF2196F3); // 정보

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Grey Scale (50부터 900까지 추가)
  static const Color grey50 = Color(0xFFFAFAFA); // 추가
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // 추가 색상들 (상담 앱에 필요한)
  static const Color lightBlue50 = Color(0xFFE1F5FE);
  static const Color lightBlue100 = Color(0xFFB3E5FC);
  static const Color lightBlue200 = Color(0xFF81D4FA);

  // 상태 색상 (더 세분화)
  static const Color successLight = Color(0xFFE8F5E8);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Gradient Colors
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

  // 카드 그림자 색상
  static const Color shadowColor = Color(0x1A000000);
  static const Color cardShadow = Color(0x0D000000);
}
