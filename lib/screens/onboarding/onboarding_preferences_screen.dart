import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/services/onboarding_service.dart';
import '../../providers/onboarding_provider.dart';
import '../../shared/models/onboarding_model.dart';

class OnboardingPreferencesScreen extends ConsumerStatefulWidget {
  const OnboardingPreferencesScreen({super.key});

  @override
  ConsumerState<OnboardingPreferencesScreen> createState() =>
      _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState
    extends ConsumerState<OnboardingPreferencesScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late OnboardingService _onboardingService;

  // 상담 방식 선택
  CounselingPreference? _selectedCounselingPreference;

  // 선호 시간대 선택 (다중 선택)
  List<String> _selectedTimeSlots = [];

  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _setupAnimations();
    _loadExistingData();
  }

  Future<void> _initializeService() async {
    _onboardingService = await OnboardingService.getInstance();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  void _loadExistingData() {
    final onboardingData = ref.read(onboardingProvider);
    if (onboardingData.counselingPreference != null) {
      _selectedCounselingPreference = onboardingData.counselingPreference;
    }
    if (onboardingData.preferredTimes != null) {
      _selectedTimeSlots = List.from(onboardingData.preferredTimes!);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // === 다음 단계로 이동 ===
  Future<void> _handleNext() async {
    if (!_validateSelections()) return;

    setState(() => _isLoading = true);

    try {
      // 1. 로컬 상태 업데이트
      ref
          .read(onboardingProvider.notifier)
          .updatePreferences(
            counselingPreference: _selectedCounselingPreference!,
            preferredTimes: _selectedTimeSlots,
          );

      // 2. 서버에 저장 (선택사항)
      await _onboardingService.savePreferences(
        counselingPreference: _selectedCounselingPreference!,
        preferredTimes: _selectedTimeSlots,
      );

      if (mounted) {
        context.go(AppRoutes.onboardingComplete);
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

  // === 유효성 검사 ===
  bool _validateSelections() {
    try {
      if (_selectedCounselingPreference == null) {
        _showErrorMessage('상담 방식을 선택해주세요.');
        return false;
      }

      if (_selectedTimeSlots.isEmpty) {
        _showErrorMessage('선호하는 시간대를 하나 이상 선택해주세요.');
        return false;
      }

      // 선택된 시간대가 유효한지 확인
      for (String timeSlot in _selectedTimeSlots) {
        if (!PreferredTime.timeSlots.contains(timeSlot)) {
          _showErrorMessage('잘못된 시간대가 선택되었습니다: $timeSlot');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('유효성 검사 오류: $e');
      _showErrorMessage('선택 항목 확인 중 오류가 발생했습니다.');
      return false;
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // === 시간대 선택 토글 ===
  void _toggleTimeSlot(String timeSlot) {
    // 입력값 검증
    if (timeSlot.isEmpty || !PreferredTime.timeSlots.contains(timeSlot)) {
      print('잘못된 시간대: $timeSlot');
      return;
    }

    setState(() {
      if (_selectedTimeSlots.contains(timeSlot)) {
        _selectedTimeSlots.remove(timeSlot);
      } else {
        _selectedTimeSlots.add(timeSlot);
      }
    });

    // 디버그 출력
    print('선택된 시간대들: $_selectedTimeSlots');
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(onboardingProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('상담 선호도'),
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _isLoading
                  ? null
                  : () => context.go(AppRoutes.onboardingMentalCheck),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === 진행률 표시 ===
            _buildProgressIndicator(progress),

            // === 스크롤 가능한 콘텐츠 영역 ===
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // === 메인 콘텐츠 ===
                      Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // === 헤더 ===
                            _buildHeader(),

                            SizedBox(height: 14.h), // 더 축소
                            // === 상담 방식 선택 ===
                            _buildCounselingMethodSection(),

                            SizedBox(height: 14.h), // 더 축소
                            // === 선호 시간대 선택 ===
                            _buildPreferredTimeSection(),

                            SizedBox(height: 28.h), // 버튼 영역을 위한 충분한 여백
                          ],
                        ),
                      ),

                      // === 버튼 영역 (하단 고정) ===
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          24.w,
                          8.h,
                          24.w,
                          16.h,
                        ), // 패딩 더 축소
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.r),
                            topRight: Radius.circular(20.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.grey400.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: CustomButton(
                          text: '다음',
                          onPressed: _isLoading ? null : _handleNext,
                          isLoading: _isLoading,
                          icon: Icons.arrow_forward,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildProgressIndicator(double progress) {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: AppColors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3/4 단계',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% 완료',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LinearProgressIndicator(
            value: 0.75, // 3/4 단계
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상담 선호도를 알려주세요',
          style: TextStyle(
            fontSize: 22.sp, // 헤더 폰트 크기 축소
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h), // 간격 축소
        Text(
          '맞춤형 상담 서비스를 제공하기 위해\n선호하는 상담 방식과 시간대를 선택해주세요.',
          style: TextStyle(
            fontSize: 14.sp, // 설명 폰트 크기 축소
            color: AppColors.textSecondary,
            height: 1.3, // 줄 간격 축소
          ),
        ),
      ],
    );
  }

  Widget _buildCounselingMethodSection() {
    return Container(
      padding: EdgeInsets.all(16.w), // 패딩 축소
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선호하는 상담 방식',
            style: TextStyle(
              fontSize: 16.sp, // 폰트 크기 축소
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h), // 간격 축소
          _buildCounselingMethodOption(
            CounselingPreference.faceToFace,
            '대면 상담',
            '상담사와 직접 만나서 상담',
            Icons.person,
            '더 깊이 있는 소통 가능',
          ),
          SizedBox(height: 8.h), // 간격 축소
          _buildCounselingMethodOption(
            CounselingPreference.video,
            '비대면 상담',
            '화상통화나 음성통화로 상담',
            Icons.videocam,
            '언제 어디서나 편리하게',
          ),
        ],
      ),
    );
  }

  Widget _buildCounselingMethodOption(
    CounselingPreference preference,
    String title,
    String subtitle,
    IconData icon,
    String benefit,
  ) {
    final isSelected = _selectedCounselingPreference == preference;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCounselingPreference = preference;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.grey50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.grey300,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    benefit,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color:
                          isSelected ? AppColors.primary : AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 24.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferredTimeSection() {
    return Container(
      padding: EdgeInsets.all(16.w), // 패딩 축소
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey400.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '선호하는 상담 시간대',
                style: TextStyle(
                  fontSize: 16.sp, // 폰트 크기 축소
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6.w,
                  vertical: 2.h,
                ), // 패딩 축소
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '복수선택',
                  style: TextStyle(
                    fontSize: 10.sp, // 폰트 크기 축소
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h), // 간격 축소
          Text(
            '상담받고 싶은 시간대를 모두 선택해주세요.',
            style: TextStyle(
              fontSize: 13.sp, // 폰트 크기 축소
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 12.h), // 간격 축소
          _buildTimeSlotGrid(),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    return Column(
      children:
          PreferredTime.timeSlots.map((timeSlot) {
            final isLast = timeSlot == PreferredTime.timeSlots.last;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 6.h), // 간격을 더 축소
              child: _buildTimeSlotCard(timeSlot),
            );
          }).toList(),
    );
  }

  Widget _buildTimeSlotCard(String timeSlot) {
    // 입력값 검증
    if (timeSlot.isEmpty) {
      return const SizedBox.shrink(); // 빈 시간대는 렌더링하지 않음
    }

    final isSelected = _selectedTimeSlots.contains(timeSlot);

    // 시간대별 아이콘과 설명 (안전하게 가져오기)
    final timeSlotInfo = _getTimeSlotInfo(timeSlot);

    return GestureDetector(
      onTap: () {
        try {
          _toggleTimeSlot(timeSlot);
        } catch (e) {
          print('시간대 선택 오류: $e');
          // 에러가 발생해도 앱이 크래시되지 않도록 처리
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('시간대 선택 중 오류가 발생했습니다: ${timeSlot}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52.h, // 높이를 더 축소
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 6.h,
        ), // 패딩 더 축소
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.grey50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 30.w, // 아이콘 크기 더 축소
              height: 30.w,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.grey200,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                timeSlotInfo['icon'] as IconData? ??
                    Icons.access_time, // null 안전 처리
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 15.sp, // 아이콘 크기 더 축소
              ),
            ),

            SizedBox(width: 10.w), // 간격 축소
            // 텍스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    timeSlot,
                    style: TextStyle(
                      fontSize: 13.sp, // 폰트 크기 더 축소
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    (timeSlotInfo['description'] as String?) ??
                        '시간 미정', // null 안전 처리
                    style: TextStyle(
                      fontSize: 11.sp, // 폰트 크기 더 축소
                      color:
                          isSelected
                              ? AppColors.primary.withOpacity(0.8)
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 선택 표시
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.grey300,
              size: 18.sp, // 아이콘 크기 더 축소
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTimeSlotInfo(String timeSlot) {
    switch (timeSlot) {
      case '아침':
        return {'icon': Icons.wb_sunny, 'description': '09:00 - 12:00'};
      case '오후':
        return {'icon': Icons.brightness_3, 'description': '13:00 - 17:00'};
      case '저녁':
        return {'icon': Icons.nightlight_round, 'description': '18:00 - 21:00'};
      case '유동적':
        return {'icon': Icons.schedule, 'description': '시간 조정 가능'};
      default:
        // 예상치 못한 시간대에 대한 기본값 추가
        return {'icon': Icons.access_time, 'description': '시간 미정'};
    }
  }
}
