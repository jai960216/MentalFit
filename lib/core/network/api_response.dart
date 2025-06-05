// 기본 API 응답 래퍼
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
    this.meta,
  });

  // 성공 응답 생성
  factory ApiResponse.success({
    required T data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      meta: meta,
    );
  }

  // 실패 응답 생성
  factory ApiResponse.error({
    required String error,
    String? message,
    int? statusCode,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
      meta: meta,
    );
  }

  // JSON에서 변환
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    try {
      final success = json['success'] as bool? ?? false;

      T? data;
      if (success && json['data'] != null && fromJsonT != null) {
        if (json['data'] is List) {
          // 리스트 데이터 처리
          final List<dynamic> dataList = json['data'] as List<dynamic>;
          data =
              dataList
                      .map((item) => fromJsonT(item as Map<String, dynamic>))
                      .toList()
                  as T;
        } else if (json['data'] is Map<String, dynamic>) {
          // 단일 객체 데이터 처리
          data = fromJsonT(json['data'] as Map<String, dynamic>);
        } else {
          // 기본 타입 (String, int, bool 등)
          data = json['data'] as T?;
        }
      } else {
        data = json['data'] as T?;
      }

      return ApiResponse<T>(
        success: success,
        data: data,
        message: json['message'] as String?,
        error: json['error'] as String?,
        statusCode: json['statusCode'] as int?,
        meta: json['meta'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return ApiResponse.error(error: 'JSON 파싱 오류: $e', statusCode: -1);
    }
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'message': message,
      'error': error,
      'statusCode': statusCode,
      'meta': meta,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, error: $error)';
  }
}

// 페이징 처리된 응답
class PaginatedResponse<T> {
  final List<T> data;
  final PaginationMeta pagination;

  const PaginatedResponse({required this.data, required this.pagination});

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final List<dynamic> dataList = json['data'] as List<dynamic>;
    final List<T> data =
        dataList
            .map((item) => fromJsonT(item as Map<String, dynamic>))
            .toList();

    return PaginatedResponse<T>(
      data: data,
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'data': data, 'pagination': pagination.toJson()};
  }
}

// 페이징 메타데이터
class PaginationMeta {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final bool hasNextPage;
  final bool hasPreviousPage;

  const PaginationMeta({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['currentPage'] as int,
      totalPages: json['totalPages'] as int,
      totalItems: json['totalItems'] as int,
      itemsPerPage: json['itemsPerPage'] as int,
      hasNextPage: json['hasNextPage'] as bool,
      hasPreviousPage: json['hasPreviousPage'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'hasNextPage': hasNextPage,
      'hasPreviousPage': hasPreviousPage,
    };
  }

  @override
  String toString() {
    return 'PaginationMeta(page: $currentPage/$totalPages, total: $totalItems)';
  }
}

// API 요청 결과 래퍼
class ApiResult<T> {
  final T? data;
  final ApiException? error;

  const ApiResult.success(this.data) : error = null;
  const ApiResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  // 성공 시 데이터 반환, 실패 시 예외 발생
  T get() {
    if (isSuccess) {
      return data!;
    } else {
      throw error!;
    }
  }

  // 성공 시 데이터 반환, 실패 시 기본값 반환
  T getOrElse(T defaultValue) {
    return isSuccess ? data! : defaultValue;
  }

  // 데이터 변환
  ApiResult<R> map<R>(R Function(T) mapper) {
    if (isSuccess) {
      try {
        return ApiResult.success(mapper(data!));
      } catch (e) {
        return ApiResult.failure(ApiException.unknown(e.toString()));
      }
    } else {
      return ApiResult.failure(error!);
    }
  }

  @override
  String toString() {
    return isSuccess ? 'ApiResult.success($data)' : 'ApiResult.failure($error)';
  }
}

// API 예외 클래스 (간단한 버전)
class ApiException implements Exception {
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

  factory ApiException.network(String message) {
    return ApiException(message: message, code: 'NETWORK_ERROR');
  }

  factory ApiException.unauthorized(String message) {
    return ApiException(
      message: message,
      code: 'UNAUTHORIZED',
      statusCode: 401,
    );
  }

  factory ApiException.serverError(String message, int statusCode) {
    return ApiException(
      message: message,
      code: 'SERVER_ERROR',
      statusCode: statusCode,
    );
  }

  factory ApiException.unknown(String message) {
    return ApiException(message: message, code: 'UNKNOWN_ERROR');
  }

  @override
  String toString() {
    return 'ApiException(code: $code, message: $message, statusCode: $statusCode)';
  }
}
