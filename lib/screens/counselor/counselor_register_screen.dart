import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_colors.dart';
import '../../core/config/app_routes.dart';
import '../../core/network/error_handler.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/models/counselor_model.dart';
import '../../providers/counselor_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CounselorRegisterScreen extends ConsumerStatefulWidget {
  const CounselorRegisterScreen({super.key});

  @override
  ConsumerState<CounselorRegisterScreen> createState() =>
      _CounselorRegisterScreenState();
}

class _CounselorRegisterScreenState
    extends ConsumerState<CounselorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  // 기본 정보
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _introductionController = TextEditingController();

  // 전문 분야
  final List<String> _selectedSpecialties = [];

  // 자격증/학력
  final List<String> _qualifications = [];
  final _qualificationController = TextEditingController();

  // 경력
  int _experienceYears = 0;

  // 상담 방식
  CounselingMethod _preferredMethod = CounselingMethod.all;

  // 가격 정보
  final _priceController = TextEditingController();

  // 가능한 시간
  final List<AvailableTime> _availableTimes = [];

  // 사용 언어
  final List<String> _languages = ['한국어'];

  XFile? _pickedImage;
  String? _localImagePath;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _introductionController.dispose();
    _qualificationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // === 전문 분야 선택 ===
  void _showSpecialtiesDialog() {
    final specialties = [
      '불안/스트레스',
      '자신감/동기부여',
      '집중력/수행력',
      '팀워크/리더십',
      '부상/재활',
      '경기력 향상',
      '생활 관리',
      '기타',
    ];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('전문 분야 선택'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: ListView.builder(
                itemCount: specialties.length,
                itemBuilder: (context, index) {
                  final specialty = specialties[index];
                  final isSelected = _selectedSpecialties.contains(specialty);

                  return CheckboxListTile(
                    title: Text(specialty),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedSpecialties.add(specialty);
                        } else {
                          _selectedSpecialties.remove(specialty);
                        }
                      });
                    },
                  );
                },
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

  // === 자격증/학력 추가 ===
  void _addQualification() {
    if (_qualificationController.text.isNotEmpty) {
      setState(() {
        _qualifications.add(_qualificationController.text);
        _qualificationController.clear();
      });
    }
  }

  // === 경력 연수 선택 ===
  void _showExperienceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('경력 연수'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: ListView.builder(
                itemCount: 21, // 0-20년
                itemBuilder: (context, index) {
                  final years = index;
                  final isSelected = _experienceYears == years;

                  return ListTile(
                    title: Text('$years년'),
                    trailing: isSelected ? const Icon(Icons.check) : null,
                    onTap: () {
                      setState(() => _experienceYears = years);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
    );
  }

  // === 상담 방식 선택 ===
  void _showCounselingMethodDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('선호 상담 방식'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: ListView.builder(
                itemCount: CounselingMethod.values.length,
                itemBuilder: (context, index) {
                  final method = CounselingMethod.values[index];
                  final isSelected = _preferredMethod == method;

                  return ListTile(
                    leading: Icon(method.icon),
                    title: Text(method.displayName),
                    trailing: isSelected ? const Icon(Icons.check) : null,
                    onTap: () {
                      setState(() => _preferredMethod = method);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
    );
  }

  // === 가능한 시간 추가 ===
  void _showAvailableTimeDialog() {
    String selectedDay = '월';
    String selectedStartTime = '09:00';
    String selectedEndTime = '18:00';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('가능한 시간 추가'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  items:
                      ['월', '화', '수', '목', '금', '토', '일']
                          .map(
                            (day) =>
                                DropdownMenuItem(value: day, child: Text(day)),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) selectedDay = value;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStartTime,
                        items: List.generate(24, (index) {
                          final hour = index.toString().padLeft(2, '0');
                          return DropdownMenuItem(
                            value: '$hour:00',
                            child: Text('$hour:00'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) selectedStartTime = value;
                        },
                      ),
                    ),
                    const Text(' ~ '),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedEndTime,
                        items: List.generate(24, (index) {
                          final hour = index.toString().padLeft(2, '0');
                          return DropdownMenuItem(
                            value: '$hour:00',
                            child: Text('$hour:00'),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) selectedEndTime = value;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _availableTimes.add(
                      AvailableTime(
                        dayOfWeek: selectedDay,
                        startTime: selectedStartTime,
                        endTime: selectedEndTime,
                        isAvailable: true,
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }

  // === 이미지 선택 ===
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // 앱의 Document 디렉토리에 복사
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = image.name;
        final savedImage = await File(
          image.path,
        ).copy('${appDir.path}/$fileName');
        setState(() {
          _pickedImage = image;
          _localImagePath = savedImage.path;
        });
      }
    } catch (e) {
      debugPrint('이미지 선택 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택에 실패했습니다: \\${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // === 저장 처리 ===
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Storage 업로드 코드 제거, 로컬 경로만 사용
      String? finalImagePath = _localImagePath;

      final counselor = Counselor(
        id: '', // 서버에서 생성
        name: _nameController.text.trim(),
        title: _titleController.text.trim(),
        introduction: _introductionController.text.trim(),
        specialties: _selectedSpecialties,
        qualifications: _qualifications,
        experienceYears: _experienceYears,
        preferredMethod: _preferredMethod,
        price: Price(consultationFee: int.tryParse(_priceController.text) ?? 0),
        availableTimes: _availableTimes,
        languages: _languages,
        rating: 0,
        reviewCount: 0,
        isOnline: false,
        consultationCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        profileImageUrl: finalImagePath, // Firestore에는 로컬 경로 저장(임시)
      );

      final success = await ref
          .read(counselorProvider.notifier)
          .registerCounselor(counselor);

      if (success && mounted) {
        await ref
            .read(counselorProvider.notifier)
            .loadCounselors(refresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상담사가 등록되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: '상담사 등록'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === 프로필 이미지 선택 ===
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48.r,
                      backgroundImage:
                          _localImagePath != null
                              ? FileImage(File(_localImagePath!))
                              : null,
                      child:
                          (_localImagePath == null)
                              ? const Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white,
                              )
                              : null,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              // === 기본 정보 ===
              Text(
                '기본 정보',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),

              // 이름
              CustomTextField(
                labelText: '이름',
                hintText: '실명을 입력해주세요',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // 직책/자격
              CustomTextField(
                labelText: '직책/자격',
                hintText: '예: 스포츠 심리 전문가, 임상심리전문가 등',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '직책/자격을 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // 소개
              CustomTextField(
                labelText: '소개',
                hintText: '자신을 소개해주세요',
                controller: _introductionController,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '소개를 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // === 전문 분야 ===
              Text(
                '전문 분야',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),

              // 전문 분야 선택 버튼
              CustomButton(
                text: '전문 분야 선택',
                icon: Icons.add,
                type: ButtonType.outline,
                onPressed: _showSpecialtiesDialog,
              ),
              if (_selectedSpecialties.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children:
                      _selectedSpecialties.map((specialty) {
                        return Chip(
                          label: Text(specialty),
                          onDeleted: () {
                            setState(() {
                              _selectedSpecialties.remove(specialty);
                            });
                          },
                        );
                      }).toList(),
                ),
              ],
              SizedBox(height: 24.h),

              // === 자격증/학력 ===
              Text(
                '자격증/학력',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),

              // 자격증/학력 입력
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      labelText: '자격증/학력',
                      hintText: '예: 서울대학교 심리학과 졸업',
                      controller: _qualificationController,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: _addQualification,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                  ),
                ],
              ),
              if (_qualifications.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children:
                      _qualifications.map((qualification) {
                        return Chip(
                          label: Text(qualification),
                          onDeleted: () {
                            setState(() {
                              _qualifications.remove(qualification);
                            });
                          },
                        );
                      }).toList(),
                ),
              ],
              SizedBox(height: 24.h),

              // === 경력 ===
              Text(
                '경력',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),

              // 경력 선택 버튼
              CustomButton(
                text: '경력 연수 선택',
                icon: Icons.work_outline,
                type: ButtonType.outline,
                onPressed: _showExperienceDialog,
              ),
              if (_experienceYears > 0) ...[
                SizedBox(height: 8.h),
                Text(
                  '$_experienceYears년',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              SizedBox(height: 24.h),

              // === 상담 방식 ===
              Text(
                '선호 상담 방식',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),

              // 상담 방식 선택 버튼
              CustomButton(
                text: '상담 방식 선택',
                icon: _preferredMethod.icon,
                type: ButtonType.outline,
                onPressed: _showCounselingMethodDialog,
              ),
              if (_preferredMethod != CounselingMethod.all) ...[
                SizedBox(height: 8.h),
                Text(
                  _preferredMethod.displayName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              SizedBox(height: 24.h),

              // === 가격 정보 ===
              Text(
                '상담 비용',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),

              // 가격 입력
              CustomTextField(
                labelText: '1회 상담 비용',
                hintText: '예: 50000',
                controller: _priceController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '상담 비용을 입력해주세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력해주세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // === 가능한 시간 ===
              Text(
                '가능한 시간',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),

              // 가능한 시간 추가 버튼
              CustomButton(
                text: '가능한 시간 추가',
                icon: Icons.access_time,
                type: ButtonType.outline,
                onPressed: _showAvailableTimeDialog,
              ),
              if (_availableTimes.isNotEmpty) ...[
                SizedBox(height: 8.h),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _availableTimes.length,
                  itemBuilder: (context, index) {
                    final time = _availableTimes[index];
                    return ListTile(
                      title: Text(
                        '${time.dayOfWeek} ${time.startTime} - ${time.endTime}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() {
                            _availableTimes.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
              SizedBox(height: 32.h),

              // === 저장 버튼 ===
              CustomButton(
                text: '상담사 등록',
                onPressed: _isSaving ? null : _handleSave,
                isLoading: _isSaving,
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
