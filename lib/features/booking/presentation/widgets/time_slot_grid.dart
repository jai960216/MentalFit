import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';

class TimeSlotGrid extends StatelessWidget {
  final DateTime selectedDate;
  final Function(TimeOfDay) onTimeSelected;

  const TimeSlotGrid({
    super.key,
    required this.selectedDate,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateTimeSlots();

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final timeSlot = timeSlots[index];
        return _TimeSlotTile(
          time: timeSlot,
          onTap: () => onTimeSelected(timeSlot),
        );
      },
    );
  }

  List<TimeOfDay> _generateTimeSlots() {
    final slots = <TimeOfDay>[];
    for (var hour = 9; hour <= 18; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour != 18) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
    return slots;
  }
}

class _TimeSlotTile extends StatelessWidget {
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeSlotTile({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider, width: 1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Center(
            child: Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
