import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // 환경별 기본 URL
  static const String _prodUrl = 'https://api.mentalfit.app';
  static const String _stagingUrl = 'https://staging-api.mentalfit.app';
  static const String _devUrl = 'https://dev-api.mentalfit.app';

  static String get baseUrl {
    if (kDebugMode) {
      return _devUrl;
    } else if (kProfileMode) {
      return _stagingUrl;
    } else {
      return _prodUrl;
    }
  }

  // 인증 관련
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String socialLogin = '/auth/social';
  static const String resetPassword = '/auth/reset-password';

  // 사용자 관련
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile';
  static const String deleteAccount = '/user/delete';

  // 상담사 관련
  static const String counselors = '/counselors';
  static const String appointments = '/appointments'; // 추가된 엔드포인트

  // 예약 관련
  static const String bookings = '/bookings';
  static const String createBooking = '/bookings/create';

  // 채팅 관련
  static const String chatRooms = '/chat/rooms';
  static const String createChatRoom = '/chat/rooms/create';
  static const String getChatRoom = '/chat/rooms';
  static const String sendMessage = '/chat/messages/send';
  static const String getMessages = '/chat/messages';

  // 자가진단 관련
  static const String selfCheck = '/self-check';
  static const String selfCheckTests = '/self-check/tests';
  static const String submitTest = '/self-check/submit';
  static const String testResults = '/self-check/results';

  // 온보딩 관련
  static const String saveOnboarding = '/onboarding/save';
  static const String getOnboarding = '/onboarding/get';
  static const String completeOnboarding = '/onboarding/complete';

  // 상담 기록 관련
  static const String records = '/records';
}

// HTTP 헤더 상수들
class ApiHeaders {
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String accept = 'Accept';
  static const String applicationJson = 'application/json';
}
