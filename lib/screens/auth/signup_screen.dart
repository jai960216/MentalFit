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
import '../../providers/auth_provider.dart';
import 'package:flutter_mentalfit/shared/models/user_model.dart'; // UserType 사용
import '../../providers/onboarding_provider.dart';
import '../../core/utils/global_error_handler.dart';

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
  final _goalController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;
  UserType? _selectedUserType = UserType.general;
  DateTime? _selectedBirthDate;
  String? _selectedSport;
  String? _goal;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _goalController.dispose();
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

  bool _validateForm() {
    if (!_agreeToTerms || !_agreeToPrivacy) {
      _showSnackBar('이용약관과 개인정보처리방침에 동의해주세요.', isError: true);
      return false;
    }

    if (_selectedUserType == null) {
      _showSnackBar('유저 유형을 선택하세요');
      return false;
    }

    return true;
  }

  // === 이벤트 처리 ===
  void _handleUserTypeSelection(UserType type) {
    if (type == UserType.counselor) {
      if (!_formKey.currentState!.validate()) {
        _showSnackBar('이름, 이메일, 비밀번호를 먼저 입력해주세요.', isError: true);
        return;
      }
      context.push(
        AppRoutes.counselorRegister,
        extra: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'name': _nameController.text.trim(),
        },
      );
    } else {
      setState(() {
        _selectedUserType = type;
      });
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref
          .read(authProvider.notifier)
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            userType: _selectedUserType!,
          );

      if (result.success && result.user != null) {
        ref
            .read(onboardingProvider.notifier)
            .setSignupInfo(
              name: _nameController.text.trim(),
              birthDate: _selectedBirthDate?.toIso8601String().split('T')[0],
              sport: _selectedSport,
              goal:
                  _goalController.text.trim().isNotEmpty
                      ? _goalController.text.trim()
                      : null,
            );

        ref.read(onboardingProvider.notifier).updateStepCompletion(1, true);

        if (mounted) {
          _showSnackBar('회원가입이 완료되었습니다!');
          context.go(AppRoutes.onboardingMentalCheck);
        }
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(
            context,
            result.error ?? '회원가입에 실패했습니다.',
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

  Future<void> _handleSocialSignup(SocialLoginType type) async {
    setState(() => _isLoading = true);

    try {
      final result =
          type == SocialLoginType.google
              ? await ref.read(authProvider.notifier).signInWithGoogle()
              : await ref.read(authProvider.notifier).signInWithKakao();

      if (mounted) {
        _showSnackBar('${type.displayName} 회원가입이 완료되었습니다!');
        if (result.success && result.user != null) {
          if (result.user!.userType == null) {
            context.go(AppRoutes.userTypeSelection);
          } else if (result.user!.isOnboardingCompleted) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.onboardingBasicInfo);
          }
        }
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
          onPressed: () => context.pop(),
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

                Text(
                  '유저 유형을 선택하세요',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children:
                        UserType.values
                            .where(
                              (type) =>
                                  type != UserType.master &&
                                  type != UserType.counselor,
                            )
                            .map((type) {
                              final isSelected = _selectedUserType == type;
                              return GestureDetector(
                                onTap: () => _handleUserTypeSelection(type),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12.h,
                                    horizontal: 16.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.primary.withOpacity(
                                              0.08,
                                            )
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : AppColors.grey200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getUserTypeIcon(type),
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : AppColors.grey600,
                                        size: 24.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              type.displayName,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    isSelected
                                                        ? AppColors.primary
                                                        : AppColors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              _getUserTypeDescription(type),
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color:
                                                    isSelected
                                                        ? AppColors.primary
                                                        : AppColors
                                                            .textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 24.sp,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            })
                            .toList(),
                  ),
                ),
                SizedBox(height: 24.h),

                // === 상담사 등록 버튼 ===
                _buildCounselorRegisterButton(),
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

  // === 유저 타입 관련 헬퍼 메서드 ===
  IconData _getUserTypeIcon(UserType type) {
    switch (type) {
      case UserType.athlete:
        return Icons.directions_run;
      case UserType.general:
        return Icons.person;
      case UserType.guardian:
        return Icons.family_restroom;
      case UserType.coach:
        return Icons.sports;
      case UserType.master:
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _getUserTypeDescription(UserType type) {
    switch (type) {
      case UserType.athlete:
        return '프로/아마추어 스포츠 선수';
      case UserType.general:
        return '운동을 즐기는 일반인';
      case UserType.guardian:
        return '선수 자녀를 둔 부모님';
      case UserType.coach:
        return '스포츠 지도자 및 트레이너';
      case UserType.master:
        return '관리자 계정은 별도 승인 절차가 필요합니다';
      default:
        return '';
    }
  }

  // === 상담사 등록 버튼 위젯 ===
  Widget _buildCounselorRegisterButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상담사로 활동하고 싶으신가요?',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        CustomButton(
          text: '상담사 등록하기',
          onPressed:
              _isLoading
                  ? null
                  : () => context.push(AppRoutes.counselorRegister),
          type: ButtonType.outline,
          icon: Icons.person_add,
        ),
      ],
    );
  }
}
