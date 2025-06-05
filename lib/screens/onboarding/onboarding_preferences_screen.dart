import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/services/onboarding_service.dart';
import '../../shared/models/onboarding_model.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingPreferencesScreen extends ConsumerStatefulWidget {
  const OnboardingPreferencesScreen({super.key});

  @override
  ConsumerState<OnboardingPreferencesScreen> createState() =>
      _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState
    extends ConsumerState<OnboardingPreferencesScreen> {
  CounselingPreference? _selectedCounselingType;
  List<String> _selectedTimes = [];
  bool _isLoading = false;

  late OnboardingService _onboardingService;

  final List<TimeSlot> _timeSlots = [
    TimeSlot(
      id: 'morning',
      label: '오전 (9:00 - 12:00)',
      icon: Icons.wb_sunny,
      description: '활기찬 오전 시간',
    ),
    TimeSlot(
      id: 'afternoon',
      label: '오후 (13:00 - 17:00)',
      icon: Icons.wb_sunny_outlined,
      description: '안정적인 오후 시간',
    ),
    TimeSlot(
      id: 'evening',
      label: '저녁 (18:00 - 21:00)',
      icon: Icons.brightness_3,
      description: '여유로운 저녁 시간',
    ),
    TimeSlot(
      id: 'flexible',
      label: '유동적',
      icon: Icons.schedule,
      description: '시간에 구애받지 않음',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadExistingData();
  }

  Future<void> _initializeServices() async {
    _onboardingService = await OnboardingService.getInstance();
  }

  void _loadExistingData() {
    final currentData = ref.read(onboardingProvider);
    _selectedCounselingType = currentData.counselingPreference;
    _selectedTimes = currentData.preferredTimes ?? [];
  }

  // === 유효성 검사 ===
  bool _isValidated() {
    return _selectedCounselingType != null && _selectedTimes.isNotEmpty;
  }

  // === 다음 단계로 이동 ===
  Future<void> _handleNext() async {
    if (!_isValidated()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('상담 방식과 선호 시간을 모두 선택해주세요.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. 로컬 상태 업데이트
      ref
          .read(onboardingProvider.notifier)
          .updatePreferences(
            counselingPreference: _selectedCounselingType!,
            preferredTimes: _selectedTimes,
          );

      // 2. 서버에 저장
      await _onboardingService.savePreferences(
        counselingPreference: _selectedCounselingType!,
        preferredTimes: _selectedTimes,
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

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(onboardingProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('선호도 조사'),
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === 진행률 표시 ===
            _buildProgressIndicator(progress),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === 헤더 ===
                    _buildHeader(),

                    SizedBox(height: 32.h),

                    // === 상담 방식 선택 ===
                    _buildCounselingTypeSection(),

                    SizedBox(height: 32.h),

                    // === 선호 시간 선택 ===
                    _buildPreferredTimeSection(),

                    SizedBox(height: 40.h),

                    // === 다음 버튼 ===
                    CustomButton(
                      text: '다음',
                      onPressed: _isLoading ? null : _handleNext,
                      isLoading: _isLoading,
                      icon: Icons.arrow_forward,
                    ),
                  ],
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
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '선호하시는 상담 방식과 시간대를 선택해주시면\n맞춤형 상담 서비스를 제공해드리겠습니다.',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCounselingTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호하는 상담 방식',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.h),

        // === 대면 상담 카드 ===
        _buildCounselingTypeCard(
          type: CounselingPreference.faceToFace,
          title: '대면 상담',
          description: '상담사와 직접 만나서 진행하는 상담',
          icon: Icons.people,
          benefits: ['직접적인 소통', '비언어적 표현 관찰', '신뢰감 형성'],
        ),

        SizedBox(height: 16.h),

        // === 비대면 상담 카드 ===
        _buildCounselingTypeCard(
          type: CounselingPreference.video,
          title: '비대면 상담 (화상)',
          description: '화상 통화를 통해 진행하는 상담',
          icon: Icons.video_call,
          benefits: ['시간과 장소의 자유', '편안한 환경', '접근성 향상'],
        ),
      ],
    );
  }

  Widget _buildCounselingTypeCard({
    required CounselingPreference type,
    required String title,
    required String description,
    required IconData icon,
    required List<String> benefits,
  }) {
    final isSelected = _selectedCounselingType == type;

    return GestureDetector(
      onTap:
          _isLoading
              ? null
              : () {
                setState(() {
                  _selectedCounselingType = type;
                });
              },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey400.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                    size: 24.sp,
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
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
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

            SizedBox(height: 16.h),

            // === 장점 목록 ===
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  benefits.map((benefit) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.grey100,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferredTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호하는 상담 시간대',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '여러 시간대를 선택할 수 있습니다',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 16.h),

        // === 시간대 선택 그리드 ===
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.2,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = _timeSlots[index];
            final isSelected = _selectedTimes.contains(timeSlot.id);

            return GestureDetector(
              onTap:
                  _isLoading
                      ? null
                      : () {
                        setState(() {
                          if (timeSlot.id == 'flexible') {
                            // 유동적 선택 시 다른 시간대 모두 해제
                            if (isSelected) {
                              _selectedTimes.remove(timeSlot.id);
                            } else {
                              _selectedTimes.clear();
                              _selectedTimes.add(timeSlot.id);
                            }
                          } else {
                            // 다른 시간대 선택 시 유동적 해제
                            _selectedTimes.remove('flexible');
                            if (isSelected) {
                              _selectedTimes.remove(timeSlot.id);
                            } else {
                              _selectedTimes.add(timeSlot.id);
                            }
                          }
                        });
                      },
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.grey200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey400.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.grey100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        timeSlot.icon,
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      timeSlot.label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      timeSlot.description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isSelected) ...[
                      SizedBox(height: 8.h),
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// === 시간대 클래스 ===
class TimeSlot {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  const TimeSlot({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}
