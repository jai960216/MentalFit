import 'package:dio/dio.dart';

// 기본 API 예외 클래스
abstract class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  // 사용자 친화적 메시지 반환
  String get userMessage => message;

  @override
  String toString() {
    return 'ApiException(code: $code, message: $message, statusCode: $statusCode)';
  }
}

// 네트워크 연결 오류
class NetworkException extends ApiException {
  const NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.details,
  });

  @override
  String get userMessage => '인터넷 연결을 확인해주세요.';
}

// 서버 오류 (5xx)
class ServerException extends ApiException {
  const ServerException({
    required super.message,
    super.code = 'SERVER_ERROR',
    super.statusCode,
    super.details,
  });

  @override
  String get userMessage => '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
}

// 인증 오류 (401)
class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    required super.message,
    super.code = 'UNAUTHORIZED',
    super.statusCode = 401,
    super.details,
  });

  @override
  String get userMessage => '로그인이 필요합니다. 다시 로그인해주세요.';
}

// 권한 오류 (403)
class ForbiddenException extends ApiException {
  const ForbiddenException({
    required super.message,
    super.code = 'FORBIDDEN',
    super.statusCode = 403,
    super.details,
  });

  @override
  String get userMessage => '해당 기능을 사용할 권한이 없습니다.';
}

// 리소스 없음 (404)
class NotFoundException extends ApiException {
  const NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    super.statusCode = 404,
    super.details,
  });

  @override
  String get userMessage => '요청하신 정보를 찾을 수 없습니다.';
}

// 요청 오류 (400)
class BadRequestException extends ApiException {
  const BadRequestException({
    required super.message,
    super.code = 'BAD_REQUEST',
    super.statusCode = 400,
    super.details,
  });

  @override
  String get userMessage => '잘못된 요청입니다. 입력 정보를 확인해주세요.';
}

// 충돌 오류 (409)
class ConflictException extends ApiException {
  const ConflictException({
    required super.message,
    super.code = 'CONFLICT',
    super.statusCode = 409,
    super.details,
  });

  @override
  String get userMessage => '이미 존재하는 정보입니다.';
}

// 유효성 검사 오류 (422)
class ValidationException extends ApiException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.statusCode = 422,
    super.details,
    this.fieldErrors,
  });

  @override
  String get userMessage {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final firstError = fieldErrors!.values.first.first;
      return firstError;
    }
    return '입력 정보를 확인해주세요.';
  }

  // 특정 필드의 오류 메시지 가져오기
  String? getFieldError(String field) {
    return fieldErrors?[field]?.first;
  }

  // 모든 오류 메시지 가져오기
  List<String> getAllErrors() {
    if (fieldErrors == null) return [];
    return fieldErrors!.values.expand((errors) => errors).toList();
  }
}

// 타임아웃 오류
class TimeoutException extends ApiException {
  const TimeoutException({
    required super.message,
    super.code = 'TIMEOUT',
    super.details,
  });

  @override
  String get userMessage => '요청 시간이 초과되었습니다. 다시 시도해주세요.';
}

// 요청 한도 초과 (429)
class TooManyRequestsException extends ApiException {
  const TooManyRequestsException({
    required super.message,
    super.code = 'TOO_MANY_REQUESTS',
    super.statusCode = 429,
    super.details,
  });

  @override
  String get userMessage => '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
}

// 알 수 없는 오류
class UnknownException extends ApiException {
  const UnknownException({
    required super.message,
    super.code = 'UNKNOWN_ERROR',
    super.details,
  });

  @override
  String get userMessage => '알 수 없는 오류가 발생했습니다.';
}

// DioException을 ApiException으로 변환하는 팩토리
class ApiExceptionFactory {
  static ApiException fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: dioException.message ?? 'Timeout occurred',
          details: {'originalError': dioException.toString()},
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          message: dioException.message ?? 'Network connection failed',
          details: {'originalError': dioException.toString()},
        );

      case DioExceptionType.badResponse:
        final statusCode = dioException.response?.statusCode;
        final responseData = dioException.response?.data;
        final message =
            _extractErrorMessage(responseData) ??
            dioException.message ??
            'HTTP Error $statusCode';

        switch (statusCode) {
          case 400:
            return BadRequestException(
              message: message,
              details:
                  responseData is Map<String, dynamic> ? responseData : null,
            );
          case 401:
            return UnauthorizedException(
              message: message,
              details:
                  responseData is Map<String, dynamic> ? responseData : null,
            );
          case 403:
            return ForbiddenException(
              message: message,
              details:
                  responseData is Map<String, dynamic> ? responseData : null,
            );
          case 404:
            return NotFoundException(
              message: message,
              details:
                  responseData is Map<String, dynamic> ? responseData : null,
            );
          case 409:
            return ConflictException(
              message: message,
              details:
                  responseData is Map<String, dynamic> ? responseData : null,
            );
          case 422:
            return ValidationException(
              message: message,
              details:
                  responseData is Map<String, dynamic> ? responseData : null,
              fieldErrors: _extractFieldErrors(responseData),
            );
          case 429:
            return TooManyRequestsException(
              message: message,
              details:
                  responseData is Map<String, dynamic> ? responseData : null,
            );
          default:
            if (statusCode != null && statusCode >= 500) {
              return ServerException(
                message: message,
                statusCode: statusCode,
                details:
                    responseData is Map<String, dynamic> ? responseData : null,
              );
            } else {
              return UnknownException(
                message: message,
                details:
                    responseData is Map<String, dynamic> ? responseData : null,
              );
            }
        }

      case DioExceptionType.cancel:
        return UnknownException(
          message: 'Request was cancelled',
          details: {'originalError': dioException.toString()},
        );

      case DioExceptionType.unknown:
      default:
        return UnknownException(
          message: dioException.message ?? 'Unknown error occurred',
          details: {'originalError': dioException.toString()},
        );
    }
  }

  // 응답에서 에러 메시지 추출
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      return responseData['message'] as String? ??
          responseData['error'] as String? ??
          responseData['detail'] as String?;
    }
    return null;
  }

  // 유효성 검사 오류에서 필드별 오류 추출
  static Map<String, List<String>>? _extractFieldErrors(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final errors = responseData['errors'] ?? responseData['fieldErrors'];
      if (errors is Map<String, dynamic>) {
        final Map<String, List<String>> fieldErrors = {};
        errors.forEach((key, value) {
          if (value is List) {
            fieldErrors[key] = value.map((e) => e.toString()).toList();
          } else if (value is String) {
            fieldErrors[key] = [value];
          }
        });
        return fieldErrors.isNotEmpty ? fieldErrors : null;
      }
    }
    return null;
  }

  // 일반 Exception을 ApiException으로 변환
  static ApiException fromException(Exception exception) {
    if (exception is ApiException) {
      return exception;
    } else if (exception is DioException) {
      return fromDioException(exception);
    } else {
      return UnknownException(
        message: exception.toString(),
        details: {'originalError': exception.toString()},
      );
    }
  }
}
