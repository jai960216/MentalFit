import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_routes.dart';

class OnboardingBasicInfoScreen extends StatelessWidget {
  const OnboardingBasicInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기본 정보')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('온보딩 1/4 - 기본 정보 입력'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.onboardingMentalCheck),
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}
