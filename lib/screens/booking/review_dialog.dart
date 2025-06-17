import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/counselor_model.dart';
import '../../shared/services/counselor_service.dart';
import '../../core/config/app_colors.dart';
import '../../providers/counselor_provider.dart';

class ReviewDialog extends ConsumerStatefulWidget {
  final Appointment appointment;
  final VoidCallback onReviewSubmitted;

  const ReviewDialog({
    super.key,
    required this.appointment,
    required this.onReviewSubmitted,
  });

  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  double _rating = 5.0;
  final TextEditingController _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) {
      _showError('리뷰 내용을 입력해주세요.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 필요');
      final review = CounselorReview(
        id: '',
        counselorId: widget.appointment.counselorId!,
        userId: user.uid,
        userName: user.displayName ?? '익명',
        rating: _rating,
        content: _controller.text.trim(),
        tags: null,
        createdAt: DateTime.now(),
        appointmentId: widget.appointment.id,
      );
      final service = await CounselorService.getInstance();
      final result = await service.addCounselorReview(review);
      if (!result.success) throw Exception(result.error);

      // 리뷰 등록 성공 후 콜백 호출
      widget.onReviewSubmitted();

      // 상담사 리뷰 목록 새로고침
      if (mounted) {
        final reviewsNotifier = ref.read(
          counselorReviewsProvider(widget.appointment.counselorId!).notifier,
        );
        await reviewsNotifier.refreshReviews();
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError('리뷰 등록 실패: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('리뷰 작성'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: AppColors.warning,
                ),
                onPressed: () => setState(() => _rating = (i + 1).toDouble()),
              ),
            ),
          ),
          Text(
            '${_rating.toInt()}점',
            style: TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '리뷰를 입력하세요',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child:
              _isSubmitting
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('등록'),
        ),
      ],
    );
  }
}
