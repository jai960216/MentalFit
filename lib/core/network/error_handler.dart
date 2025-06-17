import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final dynamic data;

  ApiException({required this.code, required this.message, this.data});

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}

class ErrorHandler {
  static final ErrorHandler instance = ErrorHandler._internal();
  ErrorHandler._internal();

  // 에러 메시지 매핑
  final Map<String, String> _errorMessages = {
    'NETWORK_ERROR': '인터넷 연결을 확인해주세요',
    'AUTH_ERROR': '인증에 실패했습니다',
    'PERMISSION_DENIED': '권한이 거부되었습니다',
    'INVALID_INPUT': '잘못된 입력입니다',
    'SERVER_ERROR': '서버 오류가 발생했습니다',
    'UNKNOWN_ERROR': '알 수 없는 오류가 발생했습니다',
  };

  // 에러 처리 메인 메서드
  void handleError(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    bool showSnackBar = true,
    bool showDialog = false,
    String? customMessage,
  }) {
    final String message = _getErrorMessage(error, customMessage);

    if (showSnackBar) {
      _showErrorSnackBar(context, message, onRetry);
    }

    if (showDialog) {
      _showErrorDialog(context, message, onRetry);
    }
  }

  // 에러 메시지 가져오기
  String _getErrorMessage(dynamic error, String? customMessage) {
    if (customMessage != null) return customMessage;

    if (error is ApiException) {
      return _errorMessages[error.code] ?? error.message;
    }

    if (error is String) return error;

    return _errorMessages['UNKNOWN_ERROR']!;
  }

  // 스낵바로 에러 표시
  void _showErrorSnackBar(
    BuildContext context,
    String message,
    VoidCallback? onRetry,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        action:
            onRetry != null
                ? SnackBarAction(
                  label: '다시 시도',
                  textColor: AppColors.white,
                  onPressed: onRetry,
                )
                : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // 다이얼로그로 에러 표시
  void _showErrorDialog(
    BuildContext context,
    String message,
    VoidCallback? onRetry,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: AppColors.error, size: 24),
                const SizedBox(width: 8),
                const Text('오류'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry();
                  },
                  child: const Text('다시 시도'),
                ),
            ],
          ),
    );
  }
}

// 전역 에러 핸들러
class GlobalErrorHandler {
  static void handleError(
    dynamic error, {
    BuildContext? context,
    VoidCallback? onRetry,
    bool showSnackBar = true,
    bool showDialog = false,
    String? customMessage,
  }) {
    if (context != null) {
      ErrorHandler.instance.handleError(
        context,
        error,
        onRetry: onRetry,
        showSnackBar: showSnackBar,
        showDialog: showDialog,
        customMessage: customMessage,
      );
    }
  }

  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    handleError(
      error,
      context: context,
      onRetry: onRetry,
      showSnackBar: true,
      showDialog: false,
      customMessage: customMessage,
    );
  }

  static void showErrorDialog(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    handleError(
      error,
      context: context,
      onRetry: onRetry,
      showSnackBar: false,
      showDialog: true,
      customMessage: customMessage,
    );
  }
}

// 비동기 에러 핸들러
class AsyncErrorHandler {
  static Future<T?> safeCall<T>(
    Future<T> future, {
    BuildContext? context,
    VoidCallback? onRetry,
    String? customMessage,
    T? fallbackValue,
  }) async {
    try {
      return await future;
    } catch (error) {
      if (context != null) {
        GlobalErrorHandler.handleError(
          error,
          context: context,
          onRetry: onRetry,
          customMessage: customMessage,
        );
      }
      return fallbackValue;
    }
  }
}

// 에러 위젯
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ],
        ),
      ),
    );
  }
}

// 에러 바운더리 위젯
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace!);
      } else {
        return ErrorWidget(
          message: '예상치 못한 오류가 발생했습니다.',
          onRetry: () {
            setState(() {
              _error = null;
              _stackTrace = null;
            });
          },
        );
      }
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ErrorWidget.builder는 더 이상 사용되지 않으므로 제거
  }
}

// 에러 상태 관리
class ErrorState {
  final ApiException? error;
  final bool hasError;
  final DateTime? timestamp;

  const ErrorState({this.error, this.hasError = false, this.timestamp});

  factory ErrorState.noError() {
    return const ErrorState();
  }

  factory ErrorState.withError(ApiException error) {
    return ErrorState(error: error, hasError: true, timestamp: DateTime.now());
  }

  ErrorState clearError() {
    return const ErrorState();
  }

  // 에러가 최근인지 확인 (5분 이내)
  bool get isRecentError {
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp!).inMinutes < 5;
  }

  @override
  String toString() {
    return 'ErrorState(hasError: $hasError, error: ${error?.code})';
  }
}
