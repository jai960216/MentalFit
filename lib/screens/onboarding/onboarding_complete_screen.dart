import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_routes.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('서비스 안내')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('온보딩 4/4 - 서비스 안내'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
