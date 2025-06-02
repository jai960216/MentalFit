import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_routes.dart';

class OnboardingPreferencesScreen extends StatelessWidget {
  const OnboardingPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('선호도 조사')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('온보딩 3/4 - 선호도 조사'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.onboardingComplete),
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}
