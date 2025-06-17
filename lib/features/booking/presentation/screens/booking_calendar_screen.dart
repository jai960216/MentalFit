import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../widgets/time_slot_grid.dart';
import '../widgets/booking_summary.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final List<DateTime> _availableDates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableDates();
  }

  Future<void> _loadAvailableDates() async {
    setState(() => _isLoading = true);
    try {
      // TODO: API 호출로 예약 가능한 날짜 목록 가져오기
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _availableDates.addAll([
          DateTime.now().add(const Duration(days: 1)),
          DateTime.now().add(const Duration(days: 2)),
          DateTime.now().add(const Duration(days: 3)),
        ]);
      });
    } catch (e) {
      // TODO: 에러 처리
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isDateAvailable(DateTime date) {
    return _availableDates.any(
      (availableDate) =>
          availableDate.year == date.year &&
          availableDate.month == date.month &&
          availableDate.day == date.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('예약 날짜 선택')),
      body:
          _isLoading
              ? const LoadingWidget(message: '예약 가능한 날짜를 불러오는 중...')
              : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 30)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (_isDateAvailable(selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      disabledDecoration: const BoxDecoration(
                        color: AppColors.disabled,
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, _) {
                        return _isDateAvailable(date)
                            ? null
                            : Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.disabled,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: const TextStyle(
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ),
                            );
                      },
                    ),
                  ),
                  if (_selectedDay != null) ...[
                    const Divider(),
                    Expanded(
                      child: TimeSlotGrid(
                        selectedDate: _selectedDay!,
                        onTimeSelected: (time) {
                          // TODO: 시간 선택 처리
                        },
                      ),
                    ),
                  ],
                ],
              ),
    );
  }
}
