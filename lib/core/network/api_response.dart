class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  const ApiResponse._({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.metadata,
  });

  // 성공 응답 생성
  factory ApiResponse.success(
    T data, {
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse._(
      success: true,
      data: data,
      statusCode: statusCode ?? 200,
      metadata: metadata,
    );
  }

  // 에러 응답 생성
  factory ApiResponse.error(
    String error, {
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse._(
      success: false,
      error: error,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  // 로딩 상태 (선택적)
  factory ApiResponse.loading() {
    return const ApiResponse._(success: false);
  }

  // 응답 데이터 변환
  ApiResponse<R> map<R>(R Function(T) mapper) {
    if (success && data != null) {
      try {
        final mappedData = mapper(data!);
        return ApiResponse.success(
          mappedData,
          statusCode: statusCode,
          metadata: metadata,
        );
      } catch (e) {
        return ApiResponse.error(
          '데이터 변환 중 오류가 발생했습니다: $e',
          statusCode: statusCode,
          metadata: metadata,
        );
      }
    } else {
      return ApiResponse.error(
        error ?? '데이터가 없습니다.',
        statusCode: statusCode,
        metadata: metadata,
      );
    }
  }

  // 조건부 실행
  ApiResponse<T> when({
    required Function(T data) onSuccess,
    required Function(String error) onError,
  }) {
    if (success && data != null) {
      onSuccess(data!);
    } else {
      onError(error ?? '알 수 없는 오류가 발생했습니다.');
    }
    return this;
  }

  // 데이터 존재 여부 확인
  bool get hasData => success && data != null;

  // 에러 존재 여부 확인
  bool get hasError => !success && error != null;

  // 성공 여부와 데이터 존재 여부 모두 확인
  bool get isSuccessful => success && data != null;

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, error: $error, statusCode: $statusCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiResponse<T> &&
        other.success == success &&
        other.data == data &&
        other.error == error &&
        other.statusCode == statusCode;
  }

  @override
  int get hashCode {
    return success.hashCode ^
        data.hashCode ^
        error.hashCode ^
        statusCode.hashCode;
  }
}

// 페이지네이션을 위한 확장 ApiResponse
class PaginatedApiResponse<T> extends ApiResponse<List<T>> {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginatedApiResponse._({
    required bool success,
    List<T>? data,
    String? error,
    int? statusCode,
    Map<String, dynamic>? metadata,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
  }) : super._(
         success: success,
         data: data,
         error: error,
         statusCode: statusCode,
         metadata: metadata,
       );

  factory PaginatedApiResponse.success(
    List<T> data, {
    required int currentPage,
    required int totalPages,
    required int totalItems,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return PaginatedApiResponse._(
      success: true,
      data: data,
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      hasNextPage: currentPage < totalPages,
      hasPreviousPage: currentPage > 1,
      statusCode: statusCode ?? 200,
      metadata: metadata,
    );
  }

  factory PaginatedApiResponse.error(
    String error, {
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    return PaginatedApiResponse._(
      success: false,
      error: error,
      currentPage: 0,
      totalPages: 0,
      totalItems: 0,
      hasNextPage: false,
      hasPreviousPage: false,
      statusCode: statusCode,
      metadata: metadata,
    );
  }

  @override
  String toString() {
    return 'PaginatedApiResponse(success: $success, data: ${data?.length} items, currentPage: $currentPage, totalPages: $totalPages, totalItems: $totalItems)';
  }
}

// API 응답 상태 열거형
enum ApiResponseStatus { loading, success, error, empty }

// API 응답 결과 확장 메서드
extension ApiResponseExtensions<T> on ApiResponse<T> {
  // 상태 확인
  ApiResponseStatus get status {
    if (!success) {
      return ApiResponseStatus.error;
    } else if (data == null) {
      return ApiResponseStatus.empty;
    } else {
      return ApiResponseStatus.success;
    }
  }

  // 데이터 또는 기본값 반환
  T? dataOrNull() => success ? data : null;

  R? dataOrDefault<R>(R defaultValue) {
    if (success && data != null && data is R) {
      return data as R;
    }
    return defaultValue;
  }

  // 에러 메시지 또는 기본 메시지 반환
  String get errorMessage => error ?? '알 수 없는 오류가 발생했습니다.';

  // 성공 데이터에 함수 적용
  ApiResponse<R> fold<R>(
    R Function(T data) onSuccess,
    R Function(String error) onError,
  ) {
    if (success && data != null) {
      try {
        final result = onSuccess(data!);
        return ApiResponse.success(result);
      } catch (e) {
        return ApiResponse.error('처리 중 오류가 발생했습니다: $e');
      }
    } else {
      try {
        final result = onError(error ?? '데이터가 없습니다.');
        return ApiResponse.success(result);
      } catch (e) {
        return ApiResponse.error('오류 처리 중 문제가 발생했습니다: $e');
      }
    }
  }
}
