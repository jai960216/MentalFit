import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MentalFit')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('메인 홈 화면'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.aiCounseling),
              child: const Text('AI 상담하기'),
            ),
          ],
        ),
      ),
    );
  }
}
