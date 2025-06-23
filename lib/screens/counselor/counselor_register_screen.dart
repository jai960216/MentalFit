import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import '../../core/config/app_colors.dart';
import '../../core/network/error_handler.dart';
import '../../providers/auth_provider.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/counselor_service.dart';
import '../../shared/models/counselor_model.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/loading_widget.dart';
import '../auth/signup_models.dart';

class CounselorRegisterScreen extends ConsumerStatefulWidget {
  final SignupInfo signupInfo;

  const CounselorRegisterScreen({super.key, required this.signupInfo});

  @override
  ConsumerState<CounselorRegisterScreen> createState() =>
      _CounselorRegisterScreenState();
}

class _CounselorRegisterScreenState
    extends ConsumerState<CounselorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController(); // 이메일
  final _passwordController = TextEditingController(); // 비밀번호
  late final TextEditingController _nameController;
  final _titleController = TextEditingController(); // 직책
  final _introductionController = TextEditingController(); // 한줄소개
  final _experienceController = TextEditingController(); // 경력
  final _priceController = TextEditingController(); // 가격
  final _packagePriceController = TextEditingController(); // 패키지 가격
  final _groupPriceController = TextEditingController(); // 그룹 가격
  final _specialtyController = TextEditingController(); // 전문분야
  final _qualificationController = TextEditingController(); // 자격증
  final _languageController = TextEditingController(); // 언어

  // State
  String? _profileImageBase64;
  final List<String> _specialties = [];
  final List<String> _qualifications = [];
  final List<String> _languages = [];
  CounselingMethod _preferredMethod = CounselingMethod.online;
  bool _isLoading = false;
  // 상담 가능한 시간대
  final List<AvailableTime> _availableTimes = [];
  String _selectedDay = '월';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.signupInfo.name);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _introductionController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    _packagePriceController.dispose();
    _groupPriceController.dispose();
    _specialtyController.dispose();
    _qualificationController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 이미지 리사이즈 및 강한 압축 (128x128, 품질 30)
      final bytes = await pickedFile.readAsBytes();
      final original = img.decodeImage(bytes);
      if (original != null) {
        final resized = img.copyResize(original, width: 128, height: 128);
        final jpg = img.encodeJpg(resized, quality: 30);
        // 20KB 이하로 제한
        if (jpg.length < 20 * 1024) {
          setState(() {
            _profileImageBase64 = base64Encode(jpg);
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이미지 용량이 너무 큽니다. 더 작은 이미지를 선택해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Auth 계정 생성
      final authNotifier = ref.read(authProvider.notifier);
      final authResult = await authNotifier.register(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        userType: UserType.counselor,
      );

      if (!authResult.success || authResult.user == null) {
        throw Exception(authResult.error ?? "Firebase Auth 계정 생성에 실패했습니다.");
      }

      final user = authResult.user!;

      // 2. 상담사 등록 요청 객체 생성
      final request = CounselorRequest(
        id: '', // Firestore에서 자동 생성
        userId: user.id,
        userName: _nameController.text,
        userProfileImageUrl: _profileImageBase64 ?? '',
        title: _titleController.text.isNotEmpty ? _titleController.text : '',
        introduction:
            _introductionController.text.isNotEmpty
                ? _introductionController.text
                : '',
        specialties: _specialties,
        qualifications: _qualifications,
        experienceYears: int.tryParse(_experienceController.text) ?? 0,
        price: Price(
          consultationFee: int.tryParse(_priceController.text) ?? 0,
          packageFee:
              _packagePriceController.text.isNotEmpty
                  ? int.tryParse(_packagePriceController.text)
                  : null,
          groupFee:
              _groupPriceController.text.isNotEmpty
                  ? int.tryParse(_groupPriceController.text)
                  : null,
        ),
        availableTimes: _availableTimes,
        languages: _languages,
        preferredMethod: _preferredMethod,
        status: CounselorRequestStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Firestore에 요청 제출
      final counselorService = await CounselorService.getInstance();
      await counselorService.submitCounselorRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상담사 등록 요청이 완료되었습니다. 관리자 승인 후 활동할 수 있습니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addToList(List<String> list, TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      setState(() {
        list.add(controller.text);
        controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('상담사 등록')),
      body:
          _isLoading
              ? const LoadingWidget()
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImagePicker(),
                      SizedBox(height: 24.h),
                      _buildTextField(
                        _emailController,
                        '이메일',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16.h),
                      _buildPasswordField(_passwordController, '비밀번호'),
                      SizedBox(height: 16.h),
                      _buildNameField(),
                      SizedBox(height: 16.h),
                      _buildTextField(_titleController, '직책 (예: 스포츠심리상담사)'),
                      SizedBox(height: 16.h),
                      _buildTextField(_introductionController, '한 줄 소개'),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        _experienceController,
                        '총 경력 (년)',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        _priceController,
                        '상담 가격 (1회)',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        _packagePriceController,
                        '패키지 가격 (선택)',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16.h),
                      _buildTextField(
                        _groupPriceController,
                        '그룹 가격 (선택)',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 24.h),
                      _buildAvailableTimesInput(),
                      SizedBox(height: 24.h),
                      _buildPreferredMethodDropdown(),
                      SizedBox(height: 24.h),
                      _buildChipInput(
                        '전문 분야',
                        _specialtyController,
                        _specialties,
                      ),
                      SizedBox(height: 24.h),
                      _buildChipInput(
                        '자격증/학력',
                        _qualificationController,
                        _qualifications,
                      ),
                      SizedBox(height: 24.h),
                      _buildChipInput('사용 언어', _languageController, _languages),
                      SizedBox(height: 32.h),
                      CustomButton(text: '등록 요청하기', onPressed: _submitRequest),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildImagePicker() => Center(
    child: Stack(
      children: [
        CircleAvatar(
          radius: 50.r,
          backgroundImage:
              _profileImageBase64 != null
                  ? MemoryImage(base64Decode(_profileImageBase64!))
                  : null,
          child:
              _profileImageBase64 == null
                  ? Icon(Icons.person, size: 50.r)
                  : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _pickImage,
          ),
        ),
      ],
    ),
  );

  Widget _buildNameField() => TextFormField(
    controller: _nameController,
    decoration: const InputDecoration(
      labelText: '이름',
      border: OutlineInputBorder(),
    ),
    validator: (value) => (value?.isEmpty ?? true) ? '이름을 입력해주세요.' : null,
  );

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    keyboardType: keyboardType,
    validator:
        (value) => (value?.isEmpty ?? true) ? '$label을(를) 입력해주세요.' : null,
  );

  Widget _buildPasswordField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        obscureText: true,
        validator:
            (value) =>
                (value == null || value.length < 6)
                    ? '비밀번호는 6자 이상이어야 합니다.'
                    : null,
      );

  Widget _buildPreferredMethodDropdown() =>
      DropdownButtonFormField<CounselingMethod>(
        value: _preferredMethod,
        decoration: const InputDecoration(
          labelText: '선호 상담 방식',
          border: OutlineInputBorder(),
        ),
        items:
            CounselingMethod.values
                .map(
                  (method) => DropdownMenuItem(
                    value: method,
                    child: Text(method.displayName),
                  ),
                )
                .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _preferredMethod = value);
          }
        },
      );

  Widget _buildChipInput(
    String label,
    TextEditingController controller,
    List<String> chips,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      SizedBox(height: 8.h),
      Wrap(
        spacing: 8.w,
        runSpacing: 4.h,
        children:
            chips
                .map(
                  (chip) => Chip(
                    label: Text(chip),
                    onDeleted: () => setState(() => chips.remove(chip)),
                  ),
                )
                .toList(),
      ),
      SizedBox(height: 8.h),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '$label 추가',
                border: const OutlineInputBorder(),
              ),
              onFieldSubmitted: (_) => _addToList(chips, controller),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addToList(chips, controller),
          ),
        ],
      ),
    ],
  );

  Widget _buildAvailableTimesInput() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('상담 가능한 시간대', style: Theme.of(context).textTheme.titleMedium),
      SizedBox(height: 8.h),
      Wrap(
        spacing: 8.w,
        runSpacing: 4.h,
        children:
            _availableTimes
                .map(
                  (t) => Chip(
                    label: Text('${t.day} ${t.startTime}~${t.endTime}'),
                    onDeleted: () => setState(() => _availableTimes.remove(t)),
                  ),
                )
                .toList(),
      ),
      SizedBox(height: 8.h),
      Row(
        children: [
          DropdownButton<String>(
            value: _selectedDay,
            items:
                ['월', '화', '수', '목', '금', '토', '일']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
            onChanged: (v) => setState(() => _selectedDay = v!),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _startTime,
              );
              if (picked != null) setState(() => _startTime = picked);
            },
            child: Text('시작: ${_startTime.format(context)}'),
          ),
          SizedBox(width: 8.w),
          TextButton(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _endTime,
              );
              if (picked != null) setState(() => _endTime = picked);
            },
            child: Text('종료: ${_endTime.format(context)}'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final start = _startTime.format(context);
              final end = _endTime.format(context);
              if (start != end) {
                setState(() {
                  _availableTimes.add(
                    AvailableTime(
                      day: _selectedDay,
                      startTime: start,
                      endTime: end,
                    ),
                  );
                });
              }
            },
          ),
        ],
      ),
    ],
  );
}
