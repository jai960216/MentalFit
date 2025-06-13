import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';  // 실제 키 발급 후 활성화

// Firebase 설정 (FlutterFire CLI로 자동 생성된 파일)
import 'firebase_options.dart';

// 앱 설정
import 'core/config/app_theme.dart';
import 'core/config/app_router.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // === 1단계: Firebase 초기화 ===
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase 초기화 완료');

    // === 2단계: Kakao SDK 초기화 (실제 키 발급 후 활성화) ===
    // TODO: 실제 Kakao 앱 키 발급 후 아래 주석 해제
    /*
    KakaoSdk.init(
      nativeAppKey: 'YOUR_KAKAO_NATIVE_APP_KEY',
      javaScriptAppKey: 'YOUR_KAKAO_JAVASCRIPT_APP_KEY',
    );
    debugPrint('✅ Kakao SDK 초기화 완료');
    */
    debugPrint('ℹ️ Kakao SDK는 실제 키 발급 후 활성화 예정');

    // === 3단계: 시스템 UI 설정 ===
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // 화면 방향 고정 (세로 모드만)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    debugPrint('✅ 앱 초기화 완료');

    // 앱 실행
    runApp(const ProviderScope(child: MentalFitApp()));
  } catch (e, stackTrace) {
    // 초기화 실패 시 에러 처리
    debugPrint('❌ 앱 초기화 실패: $e');
    debugPrint('스택 추적: $stackTrace');

    // 에러 상황에서도 앱을 실행 (기본 모드)
    runApp(const ProviderScope(child: MentalFitApp()));
  }
}

class MentalFitApp extends StatelessWidget {
  const MentalFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 12 기준
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'MentalFit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,

          // 국제화 설정
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
          // 에러 핸들링 및 글로벌 설정
          builder: (context, widget) {
            // 에러 발생 시 기본 위젯 반환
            return widget ??
                const MaterialApp(
                  home: Scaffold(
                    body: Center(child: Text('앱을 로드하는 중 문제가 발생했습니다.')),
                  ),
                );
          },
        );
      },
    );
  }
}
