import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';

class BookingSummary extends StatelessWidget {
  final DateTime date;
  final TimeOfDay time;
  final String counselorName;
  final String counselorImage;
  final String sessionType;
  final int duration;
  final double price;

  const BookingSummary({
    super.key,
    required this.date,
    required this.time,
    required this.counselorName,
    required this.counselorImage,
    required this.sessionType,
    required this.duration,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundImage: NetworkImage(counselorImage),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      counselorName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      sessionType,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: '날짜',
            value: '${date.year}년 ${date.month}월 ${date.day}일',
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(
            icon: Icons.access_time,
            label: '시간',
            value:
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          ),
          SizedBox(height: 8.h),
          _buildInfoRow(icon: Icons.timer, label: '상담 시간', value: '$duration분'),
          SizedBox(height: 16.h),
          const Divider(),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 결제 금액',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${price.toStringAsFixed(0)}원',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.w, color: AppColors.textSecondary),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
        SizedBox(width: 8.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
