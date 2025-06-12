import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // 추가
// import 'package:firebase_core/firebase_core.dart';
// import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'core/config/app_theme.dart';
import 'core/config/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (임시 주석)
  // await Firebase.initializeApp();

  // Kakao SDK 초기화 (임시 주석)
  // KakaoSdk.init(
  //   nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY',
  //   javaScriptAppKey: 'YOUR_KAKAO_JAVASCRIPT_APP_KEY',
  // );

  runApp(const ProviderScope(child: MentalFitApp()));
}

class MentalFitApp extends StatelessWidget {
  const MentalFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'MentalFit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,

          // 이 부분을 추가
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'), // 한국어
            Locale('en', 'US'), // 영어
          ],
          locale: const Locale('ko', 'KR'), // 기본 언어 설정
        );
      },
    );
  }
}
