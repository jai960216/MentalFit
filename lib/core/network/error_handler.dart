import 'package:flutter/material.dart';
import 'api_exception.dart';

class ErrorHandler {
  static ErrorHandler? _instance;

  // 싱글톤 패턴
  ErrorHandler._();

  static ErrorHandler get instance {
    _instance ??= ErrorHandler._();
    return _instance!;
  }

  // 에러 처리 메인 메서드
  void handleError(
    BuildContext? context,
    dynamic error, {
    VoidCallback? onRetry,
    bool showSnackBar = true,
    bool showDialog = false,
    String? customMessage,
  }) {
    final apiException = _convertToApiException(error);
    final errorMessage = customMessage ?? apiException.userMessage;

    // 로깅
    _logError(apiException);

    // UI에 에러 표시
    if (context != null) {
      if (showDialog) {
        _showErrorDialog(context, errorMessage, onRetry);
      } else if (showSnackBar) {
        _showErrorSnackBar(context, errorMessage, onRetry);
      }
    }

    // 특별한 에러 타입별 추가 처리
    _handleSpecialErrors(context, apiException);
  }

  // 에러를 ApiException으로 변환
  ApiException _convertToApiException(dynamic error) {
    if (error is ApiException) {
      return error;
    } else {
      return ApiExceptionFactory.fromException(
        error is Exception ? error : Exception(error.toString()),
      );
    }
  }

  // 에러 로깅
  void _logError(ApiException error) {
    debugPrint('=== API ERROR ===');
    debugPrint('Code: ${error.code}');
    debugPrint('Message: ${error.message}');
    debugPrint('Status Code: ${error.statusCode}');
    debugPrint('Details: ${error.details}');
    debugPrint('=================');
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action:
            onRetry != null
                ? SnackBarAction(
                  label: '다시 시도',
                  textColor: Colors.white,
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
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('오류'),
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

  // 특별한 에러 타입별 처리
  void _handleSpecialErrors(BuildContext? context, ApiException error) {
    switch (error.runtimeType) {
      case UnauthorizedException:
        _handleUnauthorizedError(context);
        break;
      case NetworkException:
        _handleNetworkError(context);
        break;
      case ServerException:
        _handleServerError(context);
        break;
      case ValidationException:
        _handleValidationError(context, error as ValidationException);
        break;
    }
  }

  // 인증 에러 처리
  void _handleUnauthorizedError(BuildContext? context) {
    // TODO: 로그인 화면으로 이동
    debugPrint('인증 에러: 로그인 화면으로 이동 필요');
  }

  // 네트워크 에러 처리
  void _handleNetworkError(BuildContext? context) {
    // TODO: 오프라인 모드 활성화
    debugPrint('네트워크 에러: 오프라인 모드 활성화');
  }

  // 서버 에러 처리
  void _handleServerError(BuildContext? context) {
    // TODO: 서버 상태 확인 페이지 표시
    debugPrint('서버 에러: 서버 상태 확인 필요');
  }

  // 유효성 검사 에러 처리
  void _handleValidationError(
    BuildContext? context,
    ValidationException error,
  ) {
    if (context != null) {
      final errors = error.getAllErrors();
      final errorMessage = errors.isNotEmpty ? errors.first : error.userMessage;

      _showErrorSnackBar(context, errorMessage, null);
    }
  }
}

// 글로벌 에러 핸들러 유틸리티
class GlobalErrorHandler {
  static void handleError(
    dynamic error, {
    BuildContext? context,
    VoidCallback? onRetry,
    bool showSnackBar = true,
    bool showDialog = false,
    String? customMessage,
  }) {
    ErrorHandler.instance.handleError(
      context,
      error,
      onRetry: onRetry,
      showSnackBar: showSnackBar,
      showDialog: showDialog,
      customMessage: customMessage,
    );
  }

  // 간편한 스낵바 표시
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

  // 간편한 다이얼로그 표시
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

// 비동기 에러 핸들러
class AsyncErrorHandler {
  static void handleAsyncError(
    Future future, {
    BuildContext? context,
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    future.catchError((error) {
      GlobalErrorHandler.handleError(
        error,
        context: context,
        onRetry: onRetry,
        customMessage: customMessage,
      );
    });
  }

  // Future 래퍼
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
      GlobalErrorHandler.handleError(
        error,
        context: context,
        onRetry: onRetry,
        customMessage: customMessage,
      );
      return fallbackValue;
    }
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
