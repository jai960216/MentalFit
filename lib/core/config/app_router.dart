import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

// === 스크린 임포트 ===
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

// Booking
import '../../screens/booking/booking_calendar_screen.dart';
import '../../screens/booking/booking_confirm_screen.dart';
import '../../screens/booking/booking_list_screen.dart';

// Self Check
import '../../screens/self_check/self_check_list_screen.dart';
import '../../screens/self_check/self_check_test_screen.dart';
import '../../screens/self_check/self_check_result_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
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
        path: '${AppRoutes.chatRoom}/:chatRoomId',
        name: 'chat-room',
        builder: (context, state) {
          final chatRoomId = state.pathParameters['chatRoomId']!;
          return ChatRoomScreen(chatRoomId: chatRoomId);
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
          final counselorId = state.pathParameters['counselorId']!;
          return CounselorDetailScreen(counselorId: counselorId);
        },
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
          final counselorId = state.pathParameters['counselorId']!;
          return BookingCalendarScreen(counselorId: counselorId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.bookingConfirm}/:counselorId',
        name: 'booking-confirm',
        builder: (context, state) {
          final counselorId = state.pathParameters['counselorId']!;
          return BookingConfirmScreen(counselorId: counselorId);
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
          final recordId = state.pathParameters['recordId']!;
          return PlaceholderScreen(title: '기록 상세 ($recordId)');
        },
      ),

      // === Self Check Routes ===
      GoRoute(
        path: AppRoutes.selfCheckList,
        name: 'self-check-list',
        builder: (context, state) => const SelfCheckListScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.selfCheckTest}/:testId',
        name: 'self-check-test',
        builder: (context, state) {
          final testId = state.pathParameters['testId']!;
          return SelfCheckTestScreen(testId: testId);
        },
      ),
      GoRoute(
        path: '${AppRoutes.selfCheckResult}/:resultId',
        name: 'self-check-result',
        builder: (context, state) {
          final resultId = state.pathParameters['resultId']!;
          return SelfCheckResultScreen(resultId: resultId);
        },
      ),
      GoRoute(
        path: AppRoutes.selfCheckHistory,
        name: 'self-check-history',
        builder: (context, state) => const PlaceholderScreen(title: '자가진단 기록'),
      ),

      // === Profile Routes ===
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const PlaceholderScreen(title: '마이페이지'),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'edit-profile',
        builder: (context, state) => const PlaceholderScreen(title: '프로필 수정'),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const PlaceholderScreen(title: '설정'),
      ),

      // === Error Route ===
      GoRoute(
        path: '/error',
        name: 'error',
        builder:
            (context, state) => ErrorScreen(
              error: state.extra as String? ?? '알 수 없는 오류가 발생했습니다.',
            ),
      ),
    ],

    errorBuilder:
        (context, state) =>
            ErrorScreen(error: '페이지를 찾을 수 없습니다: ${state.uri.toString()}'),

    redirect: (context, state) {
      // 필요시 리다이렉트 로직 추가
      return null;
    },
  );
}

// === 플레이스홀더 화면 ===
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title 화면',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '곧 구현 예정입니다',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('뒤로 가기'),
            ),
          ],
        ),
      ),
    );
  }
}

// === 에러 화면 ===
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오류'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              '오류가 발생했습니다',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('뒤로 가기'),
            ),
          ],
        ),
      ),
    );
  }
}
