import 'package:flutter/material.dart';
import 'package:flutter_mentalfit/shared/models/user_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../shared/widgets/custom_text_field.dart';
import 'signup_models.dart';

// === 환영 메시지 섹션 ===
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MentalFit에 오신 것을\n환영합니다!',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '스포츠 심리 상담의 새로운 경험을 시작해보세요',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// === 사용자 유형 선택 섹션 ===
class UserTypeSection extends StatelessWidget {
  final UserType selectedType;
  final Function(UserType) onTypeChanged;
  final bool isLoading;

  const UserTypeSection({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사용자 유형',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children:
                UserType.values.map((type) {
                  final isSelected = selectedType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: isLoading ? null : () => onTypeChanged(type),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(
                            type.displayName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              color:
                                  isSelected
                                      ? AppColors.white
                                      : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

// === 회원가입 폼 섹션 ===
class SignupFormSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool obscurePassword;
  final bool obscurePasswordConfirm;
  final VoidCallback onPasswordVisibilityToggle;
  final VoidCallback onPasswordConfirmVisibilityToggle;
  final String? Function(String?) validateName;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validatePasswordConfirm;
  final bool isLoading;

  const SignupFormSection({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.obscurePassword,
    required this.obscurePasswordConfirm,
    required this.onPasswordVisibilityToggle,
    required this.onPasswordConfirmVisibilityToggle,
    required this.validateName,
    required this.validateEmail,
    required this.validatePassword,
    required this.validatePasswordConfirm,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextField(
          labelText: '이름',
          hintText: '실명을 입력해주세요',
          controller: nameController,
          prefixIcon: Icons.person_outline,
          validator: validateName,
          enabled: !isLoading,
        ),
        SizedBox(height: 20.h),

        CustomTextField(
          labelText: '이메일',
          hintText: '이메일 주소를 입력하세요',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          validator: validateEmail,
          enabled: !isLoading,
        ),
        SizedBox(height: 20.h),

        CustomTextField(
          labelText: '비밀번호',
          hintText: '영문, 숫자 포함 6자 이상',
          controller: passwordController,
          obscureText: obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: obscurePassword ? Icons.visibility : Icons.visibility_off,
          onSuffixIconPressed: onPasswordVisibilityToggle,
          validator: validatePassword,
          enabled: !isLoading,
        ),
        SizedBox(height: 20.h),

        CustomTextField(
          labelText: '비밀번호 확인',
          hintText: '비밀번호를 다시 입력하세요',
          controller: passwordConfirmController,
          obscureText: obscurePasswordConfirm,
          prefixIcon: Icons.lock_outline,
          suffixIcon:
              obscurePasswordConfirm ? Icons.visibility : Icons.visibility_off,
          onSuffixIconPressed: onPasswordConfirmVisibilityToggle,
          validator: validatePasswordConfirm,
          enabled: !isLoading,
        ),
      ],
    );
  }
}

// === 약관 동의 섹션 ===
class AgreementsSection extends StatelessWidget {
  final bool agreeToTerms;
  final bool agreeToPrivacy;
  final Function(bool) onTermsChanged;
  final Function(bool) onPrivacyChanged;
  final bool isLoading;

  const AgreementsSection({
    super.key,
    required this.agreeToTerms,
    required this.agreeToPrivacy,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAgreementRow(
          context,
          value: agreeToTerms,
          onChanged: onTermsChanged,
          text: '이용약관에 동의합니다',
          onShowDialog: () => _showTermsDialog(context),
          isLoading: isLoading,
        ),
        SizedBox(height: 12.h),
        _buildAgreementRow(
          context,
          value: agreeToPrivacy,
          onChanged: onPrivacyChanged,
          text: '개인정보처리방침에 동의합니다',
          onShowDialog: () => _showPrivacyDialog(context),
          isLoading: isLoading,
        ),
      ],
    );
  }

  Widget _buildAgreementRow(
    BuildContext context, {
    required bool value,
    required Function(bool) onChanged,
    required String text,
    required VoidCallback onShowDialog,
    required bool isLoading,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          onChanged: isLoading ? null : (val) => onChanged(val ?? false),
          activeColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: GestureDetector(
            onTap: isLoading ? null : () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(text: '$text '),
                  TextSpan(
                    text: '(필수)',
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        TextButton(
          onPressed: isLoading ? null : onShowDialog,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '보기',
            style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('이용약관'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: const SingleChildScrollView(
                child: Text(SignupConstants.termsContent),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('개인정보처리방침'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: const SingleChildScrollView(
                child: Text(SignupConstants.privacyContent),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }
}

// === 소셜 구분선 ===
class SocialDivider extends StatelessWidget {
  const SocialDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            '또는 소셜 계정으로 가입',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// === 소셜 로그인 버튼 섹션 ===
class SocialButtonsSection extends StatelessWidget {
  final Function(SocialLoginType) onSocialSignup;
  final bool isLoading;

  const SocialButtonsSection({
    super.key,
    required this.onSocialSignup,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSocialButton(
            label: 'Google로 가입',
            icon: Icons.g_mobiledata,
            backgroundColor: AppColors.white,
            textColor: AppColors.error,
            onTap: () => onSocialSignup(SocialLoginType.google),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === 로그인 링크 섹션 ===
class LoginLinkSection extends StatelessWidget {
  final bool isLoading;

  const LoginLinkSection({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '이미 계정이 있으신가요? ',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
          GestureDetector(
            onTap: isLoading ? null : () => context.push(AppRoutes.login),
            child: Text(
              '로그인',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
