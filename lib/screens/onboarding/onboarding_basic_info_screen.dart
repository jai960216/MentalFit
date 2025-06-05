import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/services/onboarding_service.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingBasicInfoScreen extends ConsumerStatefulWidget {
  const OnboardingBasicInfoScreen({super.key});

  @override
  ConsumerState<OnboardingBasicInfoScreen> createState() =>
      _OnboardingBasicInfoScreenState();
}

class _OnboardingBasicInfoScreenState
    extends ConsumerState<OnboardingBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();

  String? _selectedSport;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  late OnboardingService _onboardingService;
  List<SportCategory> _sportCategories = [];
  List<String> _allSports = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadExistingData();
  }

  Future<void> _initializeServices() async {
    _onboardingService = await OnboardingService.getInstance();
    await _loadSportCategories();
  }

  Future<void> _loadSportCategories() async {
    try {
      _sportCategories = await _onboardingService.getSportCategories();
      _allSports =
          _sportCategories.expand((category) => category.sports).toList();
      if (mounted) setState(() {});
    } catch (e) {
      print('스포츠 종목 로드 오류: $e');
    }
  }

  void _loadExistingData() {
    final currentData = ref.read(onboardingProvider);
    if (currentData.name != null) {
      _nameController.text = currentData.name!;
    }
    if (currentData.sport != null) {
      _selectedSport = currentData.sport;
    }
    if (currentData.goal != null) {
      _goalController.text = currentData.goal!;
    }
    if (currentData.birthDate != null) {
      _selectedBirthDate = DateTime.tryParse(currentData.birthDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  // === 유효성 검사 ===
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이름을 입력해주세요';
    }
    if (value.trim().length < 2) {
      return '이름은 2자 이상이어야 합니다';
    }
    return null;
  }

  String? _validateSport() {
    if (_selectedSport == null || _selectedSport!.isEmpty) {
      return '주요 종목을 선택해주세요';
    }
    return null;
  }

  String? _validateBirthDate() {
    if (_selectedBirthDate == null) {
      return '생년월일을 선택해주세요';
    }

    final age = DateTime.now().difference(_selectedBirthDate!).inDays ~/ 365;
    if (age < 10 || age > 100) {
      return '올바른 생년월일을 선택해주세요';
    }

    return null;
  }

  // === 생년월일 선택 ===
  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  // === 다음 단계로 이동 ===
  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    final sportError = _validateSport();
    final dateError = _validateBirthDate();

    if (sportError != null || dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sportError ?? dateError!),
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
          .updateBasicInfo(
            name: _nameController.text.trim(),
            birthDate: _selectedBirthDate!.toIso8601String().split('T')[0],
            sport: _selectedSport!,
            goal:
                _goalController.text.trim().isNotEmpty
                    ? _goalController.text.trim()
                    : null,
          );

      // 2. 서버에 저장 (선택사항)
      await _onboardingService.saveBasicInfo(
        name: _nameController.text.trim(),
        birthDate: _selectedBirthDate!.toIso8601String().split('T')[0],
        sport: _selectedSport!,
        goal:
            _goalController.text.trim().isNotEmpty
                ? _goalController.text.trim()
                : null,
      );

      if (mounted) {
        context.go(AppRoutes.onboardingMentalCheck);
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
        title: const Text('기본 정보'),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === 헤더 ===
                      _buildHeader(),

                      SizedBox(height: 32.h),

                      // === 이름 입력 ===
                      _buildNameField(),

                      SizedBox(height: 24.h),

                      // === 생년월일 선택 ===
                      _buildBirthDateField(),

                      SizedBox(height: 24.h),

                      // === 종목 선택 ===
                      _buildSportSelection(),

                      SizedBox(height: 24.h),

                      // === 목표 입력 (선택사항) ===
                      _buildGoalField(),

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
                '1/4 단계',
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
            value: 0.25, // 1/4 단계
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
          '기본 정보를 입력해주세요',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '개인화된 상담 서비스를 제공하기 위해\n몇 가지 정보가 필요합니다.',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return CustomTextField(
      labelText: '이름',
      hintText: '실명을 입력해주세요',
      controller: _nameController,
      prefixIcon: Icons.person_outline,
      validator: _validateName,
      enabled: !_isLoading,
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '생년월일',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _isLoading ? null : _selectBirthDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color:
                    _validateBirthDate() != null
                        ? AppColors.error
                        : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColors.textSecondary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.year}년 ${_selectedBirthDate!.month}월 ${_selectedBirthDate!.day}일'
                        : '생년월일을 선택해주세요',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color:
                          _selectedBirthDate != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSportSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주요 종목',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _isLoading ? null : _showSportSelectionDialog,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color:
                    _validateSport() != null
                        ? AppColors.error
                        : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.sports, color: AppColors.textSecondary, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    _selectedSport ?? '주요 종목을 선택해주세요',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color:
                          _selectedSport != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.textSecondary,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalField() {
    return CustomTextField(
      labelText: '목표 (선택사항)',
      hintText: '예: 전국대회 우승, 개인기록 갱신 등',
      controller: _goalController,
      prefixIcon: Icons.flag_outlined,
      maxLines: 3,
      enabled: !_isLoading,
    );
  }

  // === 종목 선택 다이얼로그 ===
  void _showSportSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(maxHeight: 500.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        Text(
                          '종목 선택',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child:
                        _sportCategories.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _sportCategories.length,
                              itemBuilder: (context, index) {
                                final category = _sportCategories[index];
                                return ExpansionTile(
                                  title: Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  children:
                                      category.sports.map((sport) {
                                        return ListTile(
                                          title: Text(sport),
                                          trailing:
                                              _selectedSport == sport
                                                  ? const Icon(
                                                    Icons.check,
                                                    color: AppColors.primary,
                                                  )
                                                  : null,
                                          onTap: () {
                                            setState(() {
                                              _selectedSport = sport;
                                            });
                                            Navigator.pop(context);
                                          },
                                        );
                                      }).toList(),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
