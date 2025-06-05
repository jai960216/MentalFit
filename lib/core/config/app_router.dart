import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart'; // 새로 추가
import '../../screens/auth/splash_screen.dart';
import '../../screens/onboarding/onboarding_basic_info_screen.dart';
import '../../screens/onboarding/onboarding_mental_check_screen.dart';
import '../../screens/onboarding/onboarding_preferences_screen.dart';
import '../../screens/onboarding/onboarding_complete_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/ai_counseling/ai_counseling_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        // 새로 추가
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Onboarding Routes
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

      // Main Routes
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiCounseling,
        name: 'ai-counseling',
        builder: (context, state) => const AiCounselingScreen(),
      ),
    ],

    // 에러 페이지
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('페이지를 찾을 수 없습니다: ${state.uri.toString()}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.splash),
                  child: const Text('홈으로 돌아가기'),
                ),
              ],
            ),
          ),
        ),
  );
}
