import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // === 유효성 검사 ===
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    if (value.length < 6) {
      return '비밀번호는 6자 이상이어야 합니다';
    }
    return null;
  }

  // === 로그인 처리 ===
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref
          .read(authProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (result.success && result.user != null) {
        if (mounted) {
          // 온보딩 완료 여부에 따라 라우팅
          if (result.user!.isOnboardingCompleted) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.onboardingBasicInfo);
          }
        }
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(
            context,
            result.error ?? '로그인에 실패했습니다.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // === 소셜 로그인 처리 ===
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final result = await ref.read(authProvider.notifier).signInWithGoogle();

      if (result.success && result.user != null) {
        if (mounted) {
          // 온보딩 완료 여부에 따라 라우팅
          if (result.user!.isOnboardingCompleted) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.onboardingBasicInfo);
          }
        }
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(
            context,
            result.error ?? 'Google 로그인에 실패했습니다.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleKakaoLogin() async {
    setState(() => _isLoading = true);

    try {
      final result = await ref.read(authProvider.notifier).signInWithKakao();

      if (result.success && result.user != null) {
        if (mounted) {
          // 온보딩 완료 여부에 따라 라우팅
          if (result.user!.isOnboardingCompleted) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.onboardingBasicInfo);
          }
        }
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(
            context,
            result.error ?? 'Kakao 로그인에 실패했습니다.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authProvider.notifier).signInWithApple();
      if (result.success && result.user != null) {
        if (mounted) {
          if (result.user!.isOnboardingCompleted) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.onboardingBasicInfo);
          }
        }
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(
            context,
            result.error ?? 'Apple 로그인에 실패했습니다.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // === 비밀번호 찾기 ===
  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('비밀번호 찾기'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('등록하신 이메일 주소를 입력해주세요.\n비밀번호 재설정 링크를 보내드립니다.'),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: emailController,
                  labelText: '이메일',
                  hintText: '이메일 주소를 입력하세요',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: _validateEmail,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  if (emailController.text.isNotEmpty) {
                    final success = await ref
                        .read(authProvider.notifier)
                        .resetPassword(emailController.text.trim());

                    if (mounted) {
                      Navigator.of(context).pop(success);

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('비밀번호 재설정 이메일을 발송했습니다.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('이메일 발송에 실패했습니다.'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('발송'),
              ),
            ],
          ),
    );

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AuthProvider 상태 감시
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 60.h),

                // === 앱 로고 및 제목 ===
                _buildHeader(),

                SizedBox(height: 60.h),

                // === 로그인 폼 ===
                _buildLoginForm(),

                SizedBox(height: 16.h),

                // === 로그인 상태 유지 & 비밀번호 찾기 ===
                _buildRememberAndForgot(),

                SizedBox(height: 32.h),

                // === 로그인 버튼 ===
                CustomButton(
                  text: '로그인',
                  onPressed:
                      (_isLoading || authState.isLoading) ? null : _handleLogin,
                  isLoading: _isLoading || authState.isLoading,
                ),

                SizedBox(height: 32.h),

                // === 소셜 로그인 구분선 ===
                _buildSocialDivider(),

                SizedBox(height: 24.h),

                // === 소셜 로그인 버튼들 ===
                _buildSocialButtons(),

                SizedBox(height: 40.h),

                // === 회원가입 링크 ===
                _buildSignupLink(),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 60.w,
              height: 60.w,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'MentalFit',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '스포츠 심리 상담 플랫폼',
          style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // 이메일 입력
        CustomTextField(
          labelText: '이메일',
          hintText: '이메일 주소를 입력하세요',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: _validateEmail,
          enabled: !_isLoading,
        ),

        SizedBox(height: 20.h),

        // 비밀번호 입력
        CustomTextField(
          labelText: '비밀번호',
          hintText: '비밀번호를 입력하세요',
          controller: _passwordController,
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon:
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
          onSuffixIconPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: _validatePassword,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildRememberAndForgot() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged:
              _isLoading
                  ? null
                  : (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
          activeColor: AppColors.primary,
        ),
        Text(
          '로그인 상태 유지',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isLoading ? null : _handleForgotPassword,
          child: Text(
            '비밀번호 찾기',
            style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            '또는 소셜 계정으로 로그인',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _SocialLoginButton(
            onPressed: _isLoading ? null : _handleGoogleLogin,
            icon: Icons.g_mobiledata,
            backgroundColor: AppColors.white,
            iconColor: AppColors.error,
            label: 'Google',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _SocialLoginButton(
            onPressed: _isLoading ? null : _handleKakaoLogin,
            icon: Icons.chat_bubble,
            backgroundColor: const Color(0xFFFEE500),
            iconColor: AppColors.black,
            label: 'Kakao',
          ),
        ),
        SizedBox(width: 12.w),
        if (Platform.isIOS)
          Expanded(
            child: _SocialLoginButton(
              onPressed: _isLoading ? null : _handleAppleLogin,
              icon: Icons.apple,
              backgroundColor: Colors.black,
              iconColor: Colors.white,
              label: 'Apple',
            ),
          ),
      ],
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '계정이 없으신가요? ',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () {
                    context.push(AppRoutes.signup);
                  },
          child: Text(
            '회원가입',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// === 소셜 로그인 버튼 위젯 ===
class _SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String label;

  const _SocialLoginButton({
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140.w,
      height: 56.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
