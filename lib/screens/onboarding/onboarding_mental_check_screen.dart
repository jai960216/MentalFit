import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_routes.dart';

class OnboardingMentalCheckScreen extends StatelessWidget {
  const OnboardingMentalCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('심리 상태 체크')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('온보딩 2/4 - 심리 상태 체크'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.onboardingPreferences),
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}
