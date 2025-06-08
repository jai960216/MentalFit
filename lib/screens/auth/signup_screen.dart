import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/services/social_auth_service.dart';
import '../../shared/models/user_model.dart';
import '../../providers/auth_provider.dart';

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

  late AuthService _authService;
  late SocialAuthService _socialAuthService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _authService = await AuthService.getInstance();
    _socialAuthService = await SocialAuthService.getInstance();
  }

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
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요';
    }
    if (value.length < 2) {
      return '이름은 2자 이상이어야 합니다';
    }
    return null;
  }

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
    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
      return '비밀번호는 영문과 숫자를 포함해야 합니다';
    }
    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }

  // === 회원가입 처리 ===
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms || !_agreeToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이용약관과 개인정보처리방침에 동의해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        userType: _selectedUserType,
      );

      if (result.success && result.user != null) {
        // AuthProvider 상태 업데이트
        ref.read(authProvider.notifier).updateUser(result.user!);

        if (mounted) {
          // 회원가입 성공 - 온보딩으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원가입이 완료되었습니다!'),
              backgroundColor: AppColors.success,
            ),
          );

          context.go(AppRoutes.onboardingBasicInfo);
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

  // === 소셜 회원가입 처리 ===
  Future<void> _handleSocialSignup(SocialLoginType type) async {
    setState(() => _isLoading = true);

    try {
      AuthResult result;

      switch (type) {
        case SocialLoginType.google:
          result = await _socialAuthService.signInWithGoogle();
          break;
        case SocialLoginType.kakao:
          result = await _socialAuthService.signInWithKakao();
          break;
      }

      if (result.success && result.user != null) {
        // AuthProvider 상태 업데이트
        ref.read(authProvider.notifier).updateUser(result.user!);

        if (mounted) {
          // 소셜 회원가입 성공 - 온보딩으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('소셜 회원가입이 완료되었습니다!'),
              backgroundColor: AppColors.success,
            ),
          );

          context.go(AppRoutes.onboardingBasicInfo);
        }
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(
            context,
            result.error ?? '소셜 회원가입에 실패했습니다.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: AppColors.white,
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

                // === 회원가입 안내 ===
                _buildWelcomeText(),

                SizedBox(height: 32.h),

                // === 사용자 유형 선택 ===
                _buildUserTypeSelection(),

                SizedBox(height: 24.h),

                // === 회원가입 폼 ===
                _buildSignupForm(),

                SizedBox(height: 24.h),

                // === 약관 동의 ===
                _buildAgreements(),

                SizedBox(height: 32.h),

                // === 회원가입 버튼 ===
                CustomButton(
                  text: '회원가입',
                  onPressed: _isLoading ? null : _handleSignup,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 24.h),

                // === 소셜 회원가입 구분선 ===
                _buildSocialDivider(),

                SizedBox(height: 20.h),

                // === 소셜 회원가입 버튼들 ===
                _buildSocialButtons(),

                SizedBox(height: 24.h),

                // === 로그인 링크 ===
                _buildLoginLink(),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MentalFit에 오신 것을\n환영합니다! 👋',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '스포츠 심리 상담 서비스를 이용하기 위해\n계정을 만들어주세요.',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeSelection() {
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
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children:
                UserType.values.map((type) {
                  final isSelected = _selectedUserType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap:
                          _isLoading
                              ? null
                              : () {
                                setState(() {
                                  _selectedUserType = type;
                                });
                              },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          type.displayName,
                          textAlign: TextAlign.center,
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
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        // 이름 입력
        CustomTextField(
          labelText: '이름',
          hintText: '실명을 입력해주세요',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          validator: _validateName,
          enabled: !_isLoading,
        ),

        SizedBox(height: 20.h),

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
          hintText: '영문, 숫자 포함 6자 이상',
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

        SizedBox(height: 20.h),

        // 비밀번호 확인
        CustomTextField(
          labelText: '비밀번호 확인',
          hintText: '비밀번호를 다시 입력하세요',
          controller: _passwordConfirmController,
          obscureText: _obscurePasswordConfirm,
          prefixIcon: Icons.lock_outline,
          suffixIcon:
              _obscurePasswordConfirm ? Icons.visibility : Icons.visibility_off,
          onSuffixIconPressed: () {
            setState(() {
              _obscurePasswordConfirm = !_obscurePasswordConfirm;
            });
          },
          validator: _validatePasswordConfirm,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _buildAgreements() {
    return Column(
      children: [
        // 이용약관 동의
        Row(
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged:
                  _isLoading
                      ? null
                      : (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: GestureDetector(
                onTap:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _agreeToTerms = !_agreeToTerms;
                          });
                        },
                child: Row(
                  children: [
                    Text(
                      '이용약관에 동의합니다 ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '(필수)',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        // 이용약관 상세 보기
                        _showTermsDialog();
                      },
              child: Text(
                '보기',
                style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
              ),
            ),
          ],
        ),

        // 개인정보처리방침 동의
        Row(
          children: [
            Checkbox(
              value: _agreeToPrivacy,
              onChanged:
                  _isLoading
                      ? null
                      : (value) {
                        setState(() {
                          _agreeToPrivacy = value ?? false;
                        });
                      },
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: GestureDetector(
                onTap:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _agreeToPrivacy = !_agreeToPrivacy;
                          });
                        },
                child: Row(
                  children: [
                    Text(
                      '개인정보처리방침에 동의합니다 ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '(필수)',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
            TextButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        // 개인정보처리방침 상세 보기
                        _showPrivacyDialog();
                      },
              child: Text(
                '보기',
                style: TextStyle(fontSize: 14.sp, color: AppColors.primary),
              ),
            ),
          ],
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
            '또는 소셜 계정으로 가입',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        // Google 회원가입
        Expanded(
          child: _SocialSignupButton(
            onPressed:
                _isLoading
                    ? null
                    : () => _handleSocialSignup(SocialLoginType.google),
            icon: Icons.g_mobiledata, // 실제로는 Google 아이콘 사용
            backgroundColor: AppColors.white,
            iconColor: AppColors.error,
            label: 'Google로 가입',
          ),
        ),

        SizedBox(width: 12.w),

        // 카카오 회원가입
        Expanded(
          child: _SocialSignupButton(
            onPressed:
                _isLoading
                    ? null
                    : () => _handleSocialSignup(SocialLoginType.kakao),
            icon: Icons.chat_bubble, // 실제로는 카카오 아이콘 사용
            backgroundColor: const Color(0xFFFEE500),
            iconColor: AppColors.black,
            label: 'Kakao로 가입',
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '이미 계정이 있으신가요? ',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () {
                    context.pop(); // 로그인 화면으로 돌아가기
                  },
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
    );
  }

  // === 다이얼로그들 ===

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('이용약관'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: SingleChildScrollView(
                child: Text(
                  '''제1조 (목적)
이 약관은 MentalFit(이하 "회사")이 제공하는 스포츠 심리 상담 서비스(이하 "서비스")의 이용조건 및 절차, 회사와 이용자의 권리, 의무, 책임사항과 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (정의)
① "서비스"란 회사가 제공하는 스포츠 심리 상담, AI 상담, 전문 상담사 연결 등의 모든 서비스를 의미합니다.
② "이용자"란 이 약관에 따라 회사가 제공하는 서비스를 받는 회원 및 비회원을 말합니다.
③ "회원"이란 회사에 개인정보를 제공하여 회원등록을 한 자로서, 회사의 정보를 지속적으로 제공받으며 회사가 제공하는 서비스를 계속적으로 이용할 수 있는 자를 말합니다.

제3조 (약관의 게시와 개정)
① 회사는 이 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.
② 회사는 관련 법령을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.

제4조 (서비스의 제공)
① 회사는 다음과 같은 서비스를 제공합니다:
- AI 기반 심리 상담 서비스
- 전문 상담사와의 1:1 상담 서비스
- 자가진단 및 심리 검사 서비스
- 상담 기록 관리 서비스

제5조 (이용자의 의무)
① 이용자는 다음 행위를 하여서는 안 됩니다:
- 신청 또는 변경 시 허위내용의 등록
- 타인의 정보 도용
- 회사가 게시한 정보의 변경
- 회사 및 제3자의 저작권 등 지적재산권에 대한 침해

이용약관에 대한 자세한 내용은 서비스 내에서 확인하실 수 있습니다.''',
                  style: TextStyle(fontSize: 12.sp, height: 1.4),
                ),
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

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('개인정보처리방침'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: SingleChildScrollView(
                child: Text(
                  '''1. 개인정보의 처리목적
MentalFit(이하 "회사")는 다음의 목적을 위하여 개인정보를 처리합니다:
- 회원 가입 및 관리
- 서비스 제공 및 계약의 이행
- 고객 상담 및 민원 처리
- 서비스 개선 및 신규 서비스 개발

2. 개인정보의 처리 및 보유기간
① 회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집시에 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.
② 각각의 개인정보 처리 및 보유 기간은 다음과 같습니다:
- 회원 가입 및 관리: 회원 탈퇴 시까지
- 상담 서비스 제공: 서비스 종료 후 3년

3. 개인정보의 제3자 제공
회사는 원칙적으로 정보주체의 개인정보를 수집·이용 목적으로 명시한 범위 내에서 처리하며, 정보주체의 사전 동의 없이는 본래의 목적 범위를 초과하여 처리하거나 제3자에게 제공하지 않습니다.

4. 개인정보처리의 위탁
회사는 원활한 개인정보 업무처리를 위하여 다음과 같이 개인정보 처리업무를 위탁하고 있습니다:
- 위탁업체: AWS, Firebase 등
- 위탁업무: 서버 운영 및 데이터 저장

5. 정보주체의 권리·의무 및 행사방법
정보주체는 회사에 대해 언제든지 다음 각 호의 개인정보 보호 관련 권리를 행사할 수 있습니다:
- 개인정보 처리정지 요구권
- 개인정보 열람요구권
- 개인정보 정정·삭제요구권
- 개인정보 처리정지 요구권

자세한 개인정보처리방침은 서비스 내에서 확인하실 수 있습니다.''',
                  style: TextStyle(fontSize: 12.sp, height: 1.4),
                ),
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

// === 소셜 회원가입 버튼 위젯 ===
class _SocialSignupButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String label;

  const _SocialSignupButton({
    required this.onPressed,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 4,
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
              Icon(icon, color: iconColor, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
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
