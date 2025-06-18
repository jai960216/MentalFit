import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/app_colors.dart';
import '../../core/network/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../providers/auth_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _cardAnimation;

  String? _selectedSport;
  DateTime? _selectedBirthDate;
  File? _selectedProfileImage;
  String? _selectedProfileImageUrl;
  bool _isLoading = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  // 스포츠 종목 목록
  final List<String> _sports = [
    '축구',
    '농구',
    '야구',
    '배구',
    '테니스',
    '탁구',
    '배드민턴',
    '골프',
    '수영',
    '육상',
    '체조',
    '태권도',
    '검도',
    '유도',
    '복싱',
    '레슬링',
    '사이클',
    '스키',
    '스노보드',
    '클라이밍',
    '볼링',
    '당구',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeUserData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  void _initializeUserData() {
    setState(() => _isLoading = true);

    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _goalController.text = user.goal ?? '';
      _selectedSport = user.sport;
      _selectedProfileImageUrl = user.profileImageUrl;

      if (user.birthDate != null) {
        try {
          _selectedBirthDate = DateTime.parse(user.birthDate!);
        } catch (e) {
          // 날짜 파싱 오류 무시
        }
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // === 이미지 선택 ===
  Future<void> _selectProfileImage() async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfileImage = File(pickedFile.path);
        });

        // Firebase Storage에 이미지 업로드
        final user = ref.read(authProvider).user;
        if (user != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_images')
              .child('${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');

          final uploadTask = storageRef.putFile(_selectedProfileImage!);
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          setState(() {
            _selectedProfileImageUrl = downloadUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필 이미지가 업로드되었습니다'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      GlobalErrorHandler.showErrorSnackBar(context, e);
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('프로필 이미지 선택'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('카메라로 촬영'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('갤러리에서 선택'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );
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

  // === 스포츠 종목 선택 ===
  void _showSportSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('주요 종목 선택'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300.h,
              child: ListView.builder(
                itemCount: _sports.length,
                itemBuilder: (context, index) {
                  final sport = _sports[index];
                  final isSelected = _selectedSport == sport;

                  return ListTile(
                    title: Text(sport),
                    trailing:
                        isSelected
                            ? Icon(Icons.check, color: AppColors.primary)
                            : null,
                    onTap: () {
                      setState(() {
                        _selectedSport = sport;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ),
    );
  }

  // === 저장 처리 ===
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final success = await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            profileImageUrl: _selectedProfileImageUrl, // 서버 업로드 후 받은 URL 사용
            birthDate: _selectedBirthDate?.toIso8601String().split('T')[0],
            sport: _selectedSport,
            goal:
                _goalController.text.trim().isNotEmpty
                    ? _goalController.text.trim()
                    : null,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 업데이트되었습니다'),
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
      appBar: const CustomAppBar(title: '프로필 수정'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // === 프로필 이미지 섹션 ===
                FadeTransition(
                  opacity: _cardAnimation,
                  child: _buildProfileImageSection(),
                ),

                SizedBox(height: 24.h),

                // === 기본 정보 섹션 ===
                FadeTransition(
                  opacity: _cardAnimation,
                  child: _buildBasicInfoSection(),
                ),

                SizedBox(height: 20.h),

                // === 부가 정보 섹션 ===
                FadeTransition(
                  opacity: _cardAnimation,
                  child: _buildAdditionalInfoSection(),
                ),

                SizedBox(height: 32.h),

                // === 저장 버튼 ===
                FadeTransition(
                  opacity: _cardAnimation,
                  child: _buildSaveButton(),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildProfileImageSection() {
    return Container(
      padding: EdgeInsets.all(24.w),
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
        children: [
          Text(
            '프로필 이미지',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 20.h),

          // 프로필 이미지
          GestureDetector(
            onTap: _selectProfileImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60.r,
                  backgroundColor: AppColors.grey200,
                  backgroundImage: _getProfileImage(),
                  child:
                      _getProfileImage() == null
                          ? Icon(
                            Icons.person,
                            size: 60.sp,
                            color: AppColors.textSecondary,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 16.sp,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          Text(
            '탭하여 이미지 변경',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: '기본 정보',
      children: [
        // 이름
        CustomTextField(
          labelText: '이름',
          hintText: '실명을 입력해주세요',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          validator: Validators.validateName,
          enabled: !_isSaving,
        ),

        SizedBox(height: 20.h),

        // 생년월일
        _buildBirthDateField(),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _buildSection(
      title: '부가 정보',
      children: [
        // 주요 종목
        _buildSportField(),

        SizedBox(height: 20.h),

        // 목표
        CustomTextField(
          labelText: '목표 (선택사항)',
          hintText: '운동 목표를 입력해주세요',
          controller: _goalController,
          prefixIcon: Icons.flag_outlined,
          maxLines: 3,
          enabled: !_isSaving,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
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
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
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
          onTap: _isSaving ? null : _selectBirthDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: _isSaving ? AppColors.grey100 : AppColors.grey50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey200),
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

  Widget _buildSportField() {
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
          onTap: _isSaving ? null : _showSportSelectionDialog,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: _isSaving ? AppColors.grey100 : AppColors.grey50,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.grey200),
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

  // === 프로필 이미지 처리 헬퍼 ===
  ImageProvider? _getProfileImage() {
    if (_selectedProfileImage != null) {
      return FileImage(_selectedProfileImage!);
    } else if (_selectedProfileImageUrl?.isNotEmpty == true) {
      return NetworkImage(_selectedProfileImageUrl!);
    }
    return null;
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: '저장하기',
      onPressed: _isSaving ? null : _handleSave,
      isLoading: _isSaving,
      icon: Icons.save,
    );
  }
}
