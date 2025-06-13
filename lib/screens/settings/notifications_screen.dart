import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import '../../core/config/app_colors.dart';
import '../../core/network/error_handler.dart';

// Shared
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;

  // 알림 설정들
  bool _pushNotifications = true;
  bool _bookingReminders = true;
  bool _chatNotifications = true;
  bool _selfCheckReminders = false;
  bool _marketingNotifications = false;
  bool _newsNotifications = false;

  // 알림 시간 설정
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  List<String> _selectedDays = ['월', '화', '수', '목', '금'];

  // 소리 및 진동 설정
  bool _notificationSound = true;
  bool _vibration = true;
  String _selectedTone = '기본음';

  final List<String> _availableTones = ['기본음', '벨소리1', '벨소리2', '조용한 알림'];
  final List<String> _weekDays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSettings();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _bookingReminders = prefs.getBool('booking_reminders') ?? true;
        _chatNotifications = prefs.getBool('chat_notifications') ?? true;
        _selfCheckReminders = prefs.getBool('self_check_reminders') ?? false;
        _marketingNotifications =
            prefs.getBool('marketing_notifications') ?? false;
        _newsNotifications = prefs.getBool('news_notifications') ?? false;
        _notificationSound = prefs.getBool('notification_sound') ?? true;
        _vibration = prefs.getBool('vibration') ?? true;
        _selectedTone = prefs.getString('selected_tone') ?? '기본음';

        // 알림 시간 로드
        final hour = prefs.getInt('reminder_hour') ?? 20;
        final minute = prefs.getInt('reminder_minute') ?? 0;
        _reminderTime = TimeOfDay(hour: hour, minute: minute);

        // 선택된 요일들 로드
        _selectedDays =
            prefs.getStringList('selected_days') ?? ['월', '화', '수', '목', '금'];

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    } catch (e) {
      if (mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _selectReminderTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() => _reminderTime = selectedTime);
      await _saveSetting('reminder_hour', selectedTime.hour);
      await _saveSetting('reminder_minute', selectedTime.minute);
    }
  }

  void _toggleDay(String day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
    _saveSetting('selected_days', _selectedDays);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
      appBar: const CustomAppBar(title: '알림 설정'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // === 기본 알림 설정 ===
                _buildBasicNotificationSection(),

                SizedBox(height: 20.h),

                // === 알림 종류 설정 ===
                _buildNotificationTypesSection(),

                SizedBox(height: 20.h),

                // === 알림 시간 설정 ===
                _buildNotificationTimeSection(),

                SizedBox(height: 20.h),

                // === 소리 및 진동 설정 ===
                _buildSoundVibrationSection(),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === UI 구성 요소들 ===

  Widget _buildBasicNotificationSection() {
    return Container(
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
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 12.w),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  '기본 알림 설정',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _buildSwitchTile(
            title: '푸시 알림',
            subtitle: '모든 푸시 알림 허용',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveSetting('push_notifications', value);
              if (!value) {
                // 푸시 알림을 끄면 다른 알림들도 비활성화
                setState(() {
                  _bookingReminders = false;
                  _chatNotifications = false;
                  _selfCheckReminders = false;
                  _marketingNotifications = false;
                  _newsNotifications = false;
                });
              }
            },
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesSection() {
    return Container(
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
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 12.w),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  '알림 종류',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _buildSwitchTile(
            title: '예약 알림',
            subtitle: '상담 예약 및 일정 알림',
            value: _bookingReminders,
            enabled: _pushNotifications,
            onChanged: (value) {
              setState(() => _bookingReminders = value);
              _saveSetting('booking_reminders', value);
            },
          ),
          _buildSwitchTile(
            title: '채팅 알림',
            subtitle: '새로운 메시지 알림',
            value: _chatNotifications,
            enabled: _pushNotifications,
            onChanged: (value) {
              setState(() => _chatNotifications = value);
              _saveSetting('chat_notifications', value);
            },
          ),
          _buildSwitchTile(
            title: '자가진단 알림',
            subtitle: '정기적인 자가진단 리마인더',
            value: _selfCheckReminders,
            enabled: _pushNotifications,
            onChanged: (value) {
              setState(() => _selfCheckReminders = value);
              _saveSetting('self_check_reminders', value);
            },
          ),
          _buildSwitchTile(
            title: '마케팅 알림',
            subtitle: '이벤트 및 프로모션 정보',
            value: _marketingNotifications,
            enabled: _pushNotifications,
            onChanged: (value) {
              setState(() => _marketingNotifications = value);
              _saveSetting('marketing_notifications', value);
            },
          ),
          _buildSwitchTile(
            title: '뉴스 알림',
            subtitle: '건강 및 스포츠 관련 소식',
            value: _newsNotifications,
            enabled: _pushNotifications,
            onChanged: (value) {
              setState(() => _newsNotifications = value);
              _saveSetting('news_notifications', value);
            },
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildNotificationTimeSection() {
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  '알림 시간 설정',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 알림 시간 선택
            GestureDetector(
              onTap: _selectReminderTime,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey300),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '리마인더 시간: ${_reminderTime.format(context)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // 요일 선택
            Text(
              '알림 요일',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              children:
                  _weekDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () => _toggleDay(day),
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : AppColors.grey100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
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
          ],
        ),
      ),
    );
  }

  Widget _buildSoundVibrationSection() {
    return Container(
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
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 12.w),
            child: Row(
              children: [
                Icon(
                  Icons.volume_up_outlined,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  '소리 및 진동',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _buildSwitchTile(
            title: '알림음',
            subtitle: '알림 시 소리 재생',
            value: _notificationSound,
            onChanged: (value) {
              setState(() => _notificationSound = value);
              _saveSetting('notification_sound', value);
            },
          ),
          _buildSwitchTile(
            title: '진동',
            subtitle: '알림 시 진동',
            value: _vibration,
            onChanged: (value) {
              setState(() => _vibration = value);
              _saveSetting('vibration', value);
            },
          ),

          // 알림음 선택
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림음 선택',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTone,
                      isExpanded: true,
                      items:
                          _availableTones.map((tone) {
                            return DropdownMenuItem(
                              value: tone,
                              child: Text(tone),
                            );
                          }).toList(),
                      onChanged:
                          _notificationSound
                              ? (value) {
                                if (value != null) {
                                  setState(() => _selectedTone = value);
                                  _saveSetting('selected_tone', value);
                                }
                              }
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color:
                        enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
