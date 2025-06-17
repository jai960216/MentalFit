import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../shared/services/auth_service.dart'; // AuthStatus enum을 위해 추가

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSplashSequence();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );
  }

  Future<void> _startSplashSequence() async {
    // 애니메이션 시작
    _animationController.forward();

    // AuthProvider 초기화 및 자동 로그인 체크
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      // AuthProvider의 자동 로그인 체크 트리거
      ref.read(authProvider.notifier).checkAutoLogin();
    }
  }

  void _navigateBasedOnAuthState(AuthState authState) {
    if (_hasNavigated || !mounted) return;

    switch (authState.status) {
      case AuthStatus.authenticated:
        _hasNavigated = true;
        // 로그인된 상태
        if (authState.user?.isOnboardingCompleted ?? false) {
          // 온보딩 완료 → 홈으로
          context.go(AppRoutes.home);
        } else {
          // 온보딩 미완료 → 온보딩으로
          context.go(AppRoutes.onboardingBasicInfo);
        }
        break;

      case AuthStatus.unauthenticated:
        _hasNavigated = true;
        // 미로그인 상태 → 로그인 화면으로
        context.go(AppRoutes.login);
        break;

      case AuthStatus.error:
        _hasNavigated = true;
        // 에러 발생 → 로그인 화면으로 (에러 메시지는 이미 AuthProvider에서 처리)
        context.go(AppRoutes.login);
        break;

      case AuthStatus.initial:
      case AuthStatus.loading:
        // 아직 로딩 중 → 대기
        break;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AuthState 변화 감지
    ref.listen<AuthState>(authProvider, (previous, next) {
      _navigateBasedOnAuthState(next);
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 로고 아이콘
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 앱 이름
                      const Text(
                        'MentalFit',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 서브 타이틀
                      const Text(
                        '스포츠 심리 상담 플랫폼',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      const SizedBox(height: 80),

                      // 로딩 상태 표시
                      _buildLoadingIndicator(authState),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(AuthState authState) {
    String statusText;

    switch (authState.status) {
      case AuthStatus.initial:
      case AuthStatus.loading:
        statusText = '로딩 중...';
        break;
      case AuthStatus.authenticated:
        statusText = '로그인 확인됨';
        break;
      case AuthStatus.unauthenticated:
        statusText = '로그인 화면으로 이동';
        break;
      case AuthStatus.error:
        statusText = '오류 발생';
        break;
    }

    return Column(
      children: [
        // 로딩 인디케이터
        if (authState.status == AuthStatus.initial ||
            authState.status == AuthStatus.loading)
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              strokeWidth: 3,
            ),
          )
        else
          Icon(
            _getStatusIcon(authState.status),
            size: 30,
            color: AppColors.white,
          ),

        const SizedBox(height: 16),

        // 상태 텍스트
        Text(
          statusText,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.white,
            fontWeight: FontWeight.w300,
          ),
        ),

        // 에러 메시지 (있는 경우)
        if (authState.error != null) ...[
          const SizedBox(height: 8),
          Text(
            '잠시 후 로그인 화면으로 이동합니다',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.white.withOpacity(0.8),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon(AuthStatus status) {
    switch (status) {
      case AuthStatus.authenticated:
        return Icons.check_circle;
      case AuthStatus.unauthenticated:
        return Icons.login;
      case AuthStatus.error:
        return Icons.error_outline;
      case AuthStatus.initial:
      case AuthStatus.loading:
      default:
        return Icons.hourglass_empty;
    }
  }
}
