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

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
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

      // === Booking Routes (Placeholder) ===
      GoRoute(
        path: AppRoutes.bookingList,
        name: 'booking-list',
        builder: (context, state) => const PlaceholderScreen(title: '예약 목록'),
      ),
      GoRoute(
        path: '${AppRoutes.bookingDetail}/:bookingId',
        name: 'booking-detail',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          return PlaceholderScreen(title: '예약 상세 ($bookingId)');
        },
      ),

      // === Records Routes (Placeholder) ===
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

      // === Self Check Routes (Placeholder) ===
      GoRoute(
        path: AppRoutes.selfCheckList,
        name: 'self-check-list',
        builder: (context, state) => const PlaceholderScreen(title: '자가진단'),
      ),
      GoRoute(
        path: '${AppRoutes.selfCheckTest}/:testId',
        name: 'self-check-test',
        builder: (context, state) {
          final testId = state.pathParameters['testId']!;
          return PlaceholderScreen(title: '자가진단 테스트 ($testId)');
        },
      ),

      // === Profile Routes (Placeholder) ===
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
      return null;
    },
  );
}

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
