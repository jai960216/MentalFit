import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/services/auth_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  late AuthService _authService;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
  }

  Future<void> _initializeServices() async {
    _authService = await AuthService.getInstance();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    // === 상태에 따른 컨텐츠 ===
                    if (!_emailSent) ...[
                      // === 이메일 입력 화면 ===
                      _buildEmailInputContent(),
                    ] else ...[
                      // === 이메일 전송 완료 화면 ===
                      _buildEmailSentContent(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildEmailInputContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === 헤더 ===
        _buildHeader(),

        SizedBox(height: 40.h),

        // === 설명 ===
        _buildDescription(),

        SizedBox(height: 32.h),

        // === 이메일 입력 폼 ===
        _buildEmailForm(),

        SizedBox(height: 32.h),

        // === 전송 버튼 ===
        CustomButton(
          text: '재설정 링크 전송',
          onPressed: _isLoading ? null : _handleSendResetLink,
          isLoading: _isLoading,
          icon: Icons.send,
        ),

        SizedBox(height: 24.h),

        // === 도움말 ===
        _buildHelpSection(),

        SizedBox(height: 40.h),

        // === 로그인으로 돌아가기 ===
        _buildBackToLoginButton(),
      ],
    );
  }

  Widget _buildEmailSentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40.h),

        // === 성공 아이콘 ===
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read,
            size: 40.sp,
            color: AppColors.success,
          ),
        ),

        SizedBox(height: 24.h),

        // === 제목 ===
        Text(
          '이메일을 확인해주세요',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        SizedBox(height: 16.h),

        // === 설명 ===
        Text(
          '${_emailController.text}로\n비밀번호 재설정 링크를 보내드렸습니다.',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 32.h),

        // === 안내 사항 ===
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 20.sp, color: AppColors.info),
                  SizedBox(width: 8.w),
                  Text(
                    '확인 사항',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                '• 이메일이 도착하지 않았다면 스팸함을 확인해주세요\n• 링크는 24시간 후 만료됩니다\n• 새로운 비밀번호는 안전하게 설정해주세요',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 32.h),

        // === 액션 버튼들 ===
        Column(
          children: [
            CustomButton(
              text: '이메일 다시 보내기',
              onPressed: _isLoading ? null : _handleResendEmail,
              isLoading: _isLoading,
              type: ButtonType.outline,
              icon: Icons.refresh,
            ),
            SizedBox(height: 16.h),
            CustomButton(
              text: '로그인으로 돌아가기',
              onPressed: () => context.go(AppRoutes.login),
              icon: Icons.arrow_back,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Icon(Icons.lock_reset, size: 32.sp, color: AppColors.primary),
        ),
        SizedBox(height: 20.h),
        Text(
          '비밀번호를 잊으셨나요?',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      '걱정하지 마세요! 등록하신 이메일 주소를 입력해주시면 비밀번호 재설정 링크를 보내드릴게요.',
      style: TextStyle(
        fontSize: 16.sp,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildEmailForm() {
    return CustomTextField(
      labelText: '이메일 주소',
      hintText: '등록하신 이메일을 입력해주세요',
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icons.email_outlined,
      validator: Validators.validateEmail,
      enabled: !_isLoading,
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '도움이 필요하신가요?',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '이메일을 찾을 수 없거나 계정에 문제가 있으시면 고객센터로 문의해주세요.',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () {
              _showContactSupport();
            },
            child: Text(
              '고객센터 문의하기',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return Center(
      child: TextButton(
        onPressed: () => context.go(AppRoutes.login),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 16.sp, color: AppColors.primary),
            SizedBox(width: 8.w),
            Text(
              '로그인으로 돌아가기',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === 액션 핸들러들 ===

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.requestPasswordReset(
        _emailController.text.trim(),
      );

      if (result) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(context, '이메일 전송에 실패했습니다.');
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

  Future<void> _handleResendEmail() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.requestPasswordReset(
        _emailController.text.trim(),
      );

      if (result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이메일을 다시 보내드렸습니다.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          GlobalErrorHandler.showErrorSnackBar(context, '이메일 전송에 실패했습니다.');
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

  void _showContactSupport() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('고객센터 문의'),
            content: const Text(
              '이메일: support@mentalfit.app\n전화: 1588-0000\n\n운영시간: 평일 09:00 - 18:00',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }
}
