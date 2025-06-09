import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'signup_models.dart';
import 'signup_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  UserType _selectedUserType = UserType.athlete;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // === 유효성 검사 ===
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return '이름을 입력해주세요';
    if (value.length < 2) return '이름은 2자 이상이어야 합니다';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return '이메일을 입력해주세요';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '비밀번호를 입력해주세요';
    if (value.length < 6) return '비밀번호는 6자 이상이어야 합니다';
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      return '비밀번호는 영문과 숫자를 포함해야 합니다';
    }
    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) return '비밀번호 확인을 입력해주세요';
    if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다';
    return null;
  }

  // === 이벤트 처리 ===
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms || !_agreeToPrivacy) {
      _showSnackBar('이용약관과 개인정보처리방침에 동의해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 2)); // Mock

      if (mounted) {
        _showSnackBar('회원가입이 완료되었습니다!');
        context.go(AppRoutes.onboardingBasicInfo);
      }
    } catch (e) {
      if (mounted) _showSnackBar('회원가입 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialSignup(SocialLoginType type) async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1)); // Mock

      if (mounted) {
        _showSnackBar('${type.displayName} 회원가입이 완료되었습니다!');
        context.go(AppRoutes.onboardingBasicInfo);
      }
    } catch (e) {
      if (mounted) _showSnackBar('소셜 회원가입 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),

                WelcomeSection(),
                SizedBox(height: 32.h),

                UserTypeSection(
                  selectedType: _selectedUserType,
                  onTypeChanged:
                      (type) => setState(() => _selectedUserType = type),
                  isLoading: _isLoading,
                ),
                SizedBox(height: 24.h),

                SignupFormSection(
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  passwordConfirmController: _passwordConfirmController,
                  obscurePassword: _obscurePassword,
                  obscurePasswordConfirm: _obscurePasswordConfirm,
                  onPasswordVisibilityToggle:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                  onPasswordConfirmVisibilityToggle:
                      () => setState(
                        () =>
                            _obscurePasswordConfirm = !_obscurePasswordConfirm,
                      ),
                  validateName: _validateName,
                  validateEmail: _validateEmail,
                  validatePassword: _validatePassword,
                  validatePasswordConfirm: _validatePasswordConfirm,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 24.h),

                AgreementsSection(
                  agreeToTerms: _agreeToTerms,
                  agreeToPrivacy: _agreeToPrivacy,
                  onTermsChanged:
                      (value) => setState(() => _agreeToTerms = value),
                  onPrivacyChanged:
                      (value) => setState(() => _agreeToPrivacy = value),
                  isLoading: _isLoading,
                ),
                SizedBox(height: 32.h),

                CustomButton(
                  text: '회원가입',
                  onPressed: _isLoading ? null : _handleSignup,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 24.h),

                const SocialDivider(),
                SizedBox(height: 20.h),

                SocialButtonsSection(
                  onSocialSignup: _handleSocialSignup,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 24.h),

                LoginLinkSection(isLoading: _isLoading),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
