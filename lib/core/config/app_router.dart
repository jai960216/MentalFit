import 'package:flutter/material.dart';
import 'package:flutter_mentalfit/screens/info/privacy_screen.dart';
import 'package:flutter_mentalfit/screens/info/terms_screen.dart';
import 'package:flutter_mentalfit/screens/profile/edit_profile_screen.dart';
import 'package:flutter_mentalfit/screens/profile/settings_screen.dart';
import 'package:flutter_mentalfit/screens/settings/notifications_screen.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

// === 스크린 임포트 ===
import '../../screens/profile/profile_screen.dart';

// Auth
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/user_type_selection_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';

// Onboarding
import '../../screens/onboarding/onboarding_basic_info_screen.dart';
import '../../screens/onboarding/onboarding_mental_check_screen.dart';
import '../../screens/onboarding/onboarding_preferences_screen.dart';
import '../../screens/onboarding/onboarding_complete_screen.dart';

// Main
import '../../screens/home/home_screen.dart';

// AI Counseling
import '../../screens/ai_counseling/ai_counseling_screen.dart';

// Chat
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_room_screen.dart';

// Counselor
import '../../screens/counselor/counselor_list_screen.dart';
import '../../screens/counselor/counselor_detail_screen.dart';
import '../../screens/counselor/counselor_register_screen.dart';

// Booking
import '../../screens/booking/booking_calendar_screen.dart';
import '../../screens/booking/booking_confirm_screen.dart';
import '../../screens/booking/booking_list_screen.dart';

// Self Check
import '../../screens/self_check/self_check_list_screen.dart';
import '../../screens/self_check/self_check_test_screen.dart';
import '../../screens/self_check/self_check_result_screen.dart';
import '../../screens/self_check/self_check_history_screen.dart';

// === 에러 및 플레이스홀더 화면 ===
import '../../shared/widgets/error_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';

// === 모델 임포트 ===
import '../../shared/models/self_check_models.dart';
import '../../shared/models/counselor_model.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    // 🔥 전역 에러 핸들링
    errorBuilder:
        (context, state) => ErrorScreen(
          error: state.error?.toString() ?? '알 수 없는 오류가 발생했습니다.',
          onRetry: () => context.go(AppRoutes.home),
        ),
    routes: [
      // === Splash Screen ===
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // === Auth Routes ===
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.userTypeSelection,
        name: 'user-type-selection',
        builder: (context, state) => const UserTypeSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // === Onboarding Routes ===
      GoRoute(
        path: AppRoutes.onboardingBasicInfo,
        name: 'onboarding-basic-info',
        builder: (context, state) => const OnboardingBasicInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingMentalCheck,
        name: 'onboarding-mental-check',
        builder: (context, state) => const OnboardingMentalCheckScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPreferences,
        name: 'onboarding-preferences',
        builder: (context, state) => const OnboardingPreferencesScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingComplete,
        name: 'onboarding-complete',
        builder: (context, state) => const OnboardingCompleteScreen(),
      ),

      // === Main Routes ===
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // === AI Counseling Routes ===
      GoRoute(
        path: AppRoutes.aiCounseling,
        name: 'ai-counseling',
        builder: (context, state) => const AiCounselingScreen(),
      ),

      // === Chat Routes ===
      GoRoute(
        path: AppRoutes.chatList,
        name: 'chat-list',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.chatRoom}/:roomId',
        name: 'chat-room',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'];
          if (roomId == null) {
            return ErrorScreen(
              error: '채팅방 ID가 필요합니다.',
              onRetry: () => context.go(AppRoutes.chatList),
            );
          }
          return ChatRoomScreen(chatRoomId: roomId);
        },
      ),

      // === Counselor Routes ===
      GoRoute(
        path: AppRoutes.counselorList,
        name: 'counselor-list',
        builder: (context, state) => const CounselorListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.counselorDetail}/:counselorId',
        name: 'counselor-detail',
        builder: (context, state) {
          final counselorId = state.pathParameters['counselorId'];
          if (counselorId == null) {
            return ErrorScreen(
              error: '상담사 ID가 필요합니다.',
              onRetry: () => context.go(AppRoutes.counselorList),
            );
          }
          return CounselorDetailScreen(counselorId: counselorId);
        },
      ),
      GoRoute(
        path: AppRoutes.counselorRegister,
        name: 'counselor-register',
        builder: (context, state) => const CounselorRegisterScreen(),
      ),

      // === Booking Routes ===
      GoRoute(
        path: AppRoutes.bookingList,
        name: 'booking-list',
        builder: (context, state) => const BookingListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.bookingCalendar}/:counselorId',
        name: 'booking-calendar',
        builder: (context, state) {
          final counselorId = state.pathParameters['counselorId'];
          if (counselorId == null) {
            return ErrorScreen(
              error: '상담사 ID가 필요합니다.',
              onRetry: () => context.go(AppRoutes.counselorList),
            );
          }
          return BookingCalendarScreen(counselorId: counselorId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.bookingConfirm}/:counselorId',
        name: 'booking-confirm',
        builder: (context, state) {
          final counselorId = state.pathParameters['counselorId'];
          final appointment = state.extra as Appointment?;
          if (counselorId == null || appointment == null) {
            return ErrorScreen(
              error: '상담사 ID 또는 예약 정보가 필요합니다.',
              onRetry: () => context.go(AppRoutes.counselorList),
            );
          }
          return BookingConfirmScreen(
            counselorId: counselorId,
            appointment: appointment,
          );
        },
      ),

      // === Records Routes ===
      GoRoute(
        path: AppRoutes.recordsList,
        name: 'records-list',
        builder: (context, state) => const PlaceholderScreen(title: '상담 기록'),
      ),
      GoRoute(
        path: '${AppRoutes.recordDetail}/:recordId',
        name: 'record-detail',
        builder: (context, state) {
          final recordId = state.pathParameters['recordId'];
          if (recordId == null) {
            return ErrorScreen(
              error: '기록 ID가 필요합니다.',
              onRetry: () => context.go(AppRoutes.recordsList),
            );
          }
          return PlaceholderScreen(title: '기록 상세 ($recordId)');
        },
      ),

      // === Self Check Routes - 🔥 강화된 에러 처리 ===
      GoRoute(
        path: AppRoutes.selfCheckList,
        name: 'self-check-list',
        builder: (context, state) => const SelfCheckListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.selfCheckTest}/:testId',
        name: 'self-check-test',
        builder: (context, state) {
          final testId = state.pathParameters['testId'];
          if (testId == null || testId.isEmpty) {
            return ErrorScreen(
              error: '검사 ID가 필요합니다.',
              onRetry: () => context.go(AppRoutes.selfCheckList),
            );
          }

          // extra 데이터에서 testType 추출 (선택사항)
          final extra = state.extra as Map<String, dynamic>?;
          final testType = extra?['testType'] as String?;

          return SelfCheckTestScreen(
            testId: testId,
            testType: testType != null ? _parseTestType(testType) : null,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.selfCheckResult}/:resultId',
        name: 'self-check-result',
        builder: (context, state) {
          final resultId = state.pathParameters['resultId'];
          if (resultId == null || resultId.isEmpty) {
            return ErrorScreen(
              error: '결과 ID가 필요합니다.',
              onRetry: () => context.go(AppRoutes.selfCheckList),
            );
          }
          return SelfCheckResultScreen(resultId: resultId);
        },
      ),
      GoRoute(
        path: AppRoutes.selfCheckHistory,
        name: 'self-check-history',
        builder: (context, state) => const SelfCheckHistoryScreen(),
      ),

      // === Profile Routes ===
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        name: 'privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        name: 'terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        builder: (context, state) => const PlaceholderScreen(title: '도움말'),
      ),

      // === 404 Not Found Route ===
      GoRoute(
        path: '/404',
        name: 'not-found',
        builder:
            (context, state) => ErrorScreen(
              error: '요청하신 페이지를 찾을 수 없습니다.',
              onRetry: () => context.go(AppRoutes.home),
            ),
      ),
    ],

    // 🔥 라우팅 리다이렉트 설정
    redirect: (context, state) {
      final path = state.matchedLocation;

      // 존재하지 않는 경로는 404로 리다이렉트
      if (!_isValidRoute(path)) {
        return '/404';
      }

      return null; // 정상 경로는 그대로 진행
    },
  );

  // === 헬퍼 메서드들 ===

  /// TestType 문자열을 SelfCheckTestType으로 변환
  static SelfCheckTestType? _parseTestType(String typeString) {
    try {
      return SelfCheckTestType.values.firstWhere(
        (type) => type.name == typeString,
      );
    } catch (e) {
      return null;
    }
  }

  /// 유효한 라우트인지 확인
  static bool _isValidRoute(String path) {
    final validBasePaths = [
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.signup,
      AppRoutes.userTypeSelection,
      AppRoutes.forgotPassword,
      AppRoutes.onboardingBasicInfo,
      AppRoutes.onboardingMentalCheck,
      AppRoutes.onboardingPreferences,
      AppRoutes.onboardingComplete,
      AppRoutes.home,
      AppRoutes.aiCounseling,
      AppRoutes.chatList,
      AppRoutes.counselorList,
      AppRoutes.bookingList,
      AppRoutes.recordsList,
      AppRoutes.selfCheckList,
      AppRoutes.selfCheckHistory,
      AppRoutes.profile,
      AppRoutes.editProfile,
      AppRoutes.settings,
      AppRoutes.notifications,
      AppRoutes.privacy,
      AppRoutes.terms,
      AppRoutes.help,
      AppRoutes.counselorRegister,
      '/404',
    ];

    // 정확한 경로 매칭
    if (validBasePaths.contains(path)) {
      return true;
    }

    // 동적 경로 패턴 매칭
    final dynamicRoutePatterns = [
      RegExp(r'^/chat/room/[^/]+$'),
      RegExp(r'^/counselor/detail/[^/]+$'),
      RegExp(r'^/booking/calendar/[^/]+$'),
      RegExp(r'^/booking/confirm/[^/]+$'),
      RegExp(r'^/records/detail/[^/]+$'),
      RegExp(r'^/self-check/test/[^/]+$'),
      RegExp(r'^/self-check/result/[^/]+$'),
    ];

    return dynamicRoutePatterns.any((pattern) => pattern.hasMatch(path));
  }
}
