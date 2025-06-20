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
import '../../shared/widgets/theme_aware_widgets.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ThemedScaffold(
      appBar: const CustomAppBar(title: '프로필 수정'),
      body:
          _isLoading
              ? const LoadingWidget()
              : FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      children: [
                        // === 프로필 이미지 섹션 ===
                        _buildProfileImageSection(theme),
                        SizedBox(height: 32.h),

                        // === 프로필 정보 카드 ===
                        _buildProfileInfoCard(theme),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // === 프로필 이미지 섹션 ===
  Widget _buildProfileImageSection(ThemeData theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    _selectedProfileImage != null
                        ? Image.file(_selectedProfileImage!, fit: BoxFit.cover)
                        : _selectedProfileImageUrl != null &&
                            _selectedProfileImageUrl!.isNotEmpty
                        ? Image.network(
                          _selectedProfileImageUrl!,
                          fit: BoxFit.cover,
                        )
                        : Icon(
                          Icons.person,
                          size: 60.w,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
              ),
            ),
            GestureDetector(
              onTap: _selectProfileImage,
              child: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2.w,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  size: 20.w,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // === 프로필 정보 카드 ===
  Widget _buildProfileInfoCard(ThemeData theme) {
    return ThemedContainer(
      useSurface: true,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextFieldSection(),
          SizedBox(height: 24.h),
          _buildDropdownSection(theme),
          SizedBox(height: 32.h),
          _buildSaveButton(theme),
        ],
      ),
    );
  }

  // === 텍스트 필드 섹션 ===
  Widget _buildTextFieldSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ThemedText(
          text: '이름',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        CustomTextField(
          controller: _nameController,
          hintText: '이름을 입력하세요',
          validator: (value) => Validators.validateRequired(value, '이름'),
        ),
        SizedBox(height: 16.h),
        const ThemedText(
          text: '나의 목표',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        CustomTextField(
          controller: _goalController,
          hintText: '이번 시즌 목표를 알려주세요',
          maxLines: 3,
        ),
      ],
    );
  }

  // === 드롭다운 섹션 ===
  Widget _buildDropdownSection(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ThemedText(
                text: '생년월일',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              _buildDropdownField(
                theme: theme,
                value:
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.year}년 ${_selectedBirthDate!.month}월 ${_selectedBirthDate!.day}일'
                        : '선택하세요',
                icon: Icons.calendar_today,
                onTap: _selectBirthDate,
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ThemedText(
                text: '주요 종목',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              _buildDropdownField(
                theme: theme,
                value: _selectedSport ?? '선택하세요',
                icon: Icons.sports_soccer,
                onTap: _showSportSelectionDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // === 드롭다운 필드 ===
  Widget _buildDropdownField({
    required ThemeData theme,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14.sp,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  // === 저장 버튼 ===
  Widget _buildSaveButton(ThemeData theme) {
    return CustomButton(
      text: '수정 완료',
      onPressed: _isSaving ? null : _handleSave,
      isLoading: _isSaving,
    );
  }
}
