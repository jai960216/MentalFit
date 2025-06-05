import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'token_manager.dart';
import 'network_checker.dart';

class ApiClient {
  static ApiClient? _instance;
  late Dio _dio;
  late TokenManager _tokenManager;
  late NetworkChecker _networkChecker;

  // 싱글톤 패턴
  ApiClient._();

  static Future<ApiClient> getInstance() async {
    if (_instance == null) {
      _instance = ApiClient._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  // 초기화
  Future<void> _initialize() async {
    _tokenManager = await TokenManager.getInstance();
    _networkChecker = NetworkChecker.instance;
    await _networkChecker.initialize();

    _dio = Dio(_getBaseOptions());
    _setupInterceptors();
  }

  // 기본 옵션 설정
  BaseOptions _getBaseOptions() {
    return BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        ApiHeaders.contentType: ApiHeaders.applicationJson,
        ApiHeaders.accept: ApiHeaders.applicationJson,
        ApiHeaders.userAgent: 'MentalFit/1.0.0 (Flutter)',
      },
      responseType: ResponseType.json,
      followRedirects: true,
      maxRedirects: 3,
    );
  }

  // 인터셉터 설정
  void _setupInterceptors() {
    // 1. 로깅 인터셉터 (개발 모드에서만)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (log) => debugPrint('[API] $log'),
        ),
      );
    }

    // 2. 인증 토큰 인터셉터
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );

    // 3. 재시도 인터셉터
    _dio.interceptors.add(_createRetryInterceptor());
  }

  // 요청 전 처리
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 네트워크 연결 확인
    if (!await _networkChecker.isConnected()) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: '인터넷 연결을 확인해주세요',
        ),
      );
      return;
    }

    // 인증이 필요한 엔드포인트에 토큰 추가
    if (_isAuthRequired(options.path)) {
      final authHeader = _tokenManager.getAuthorizationHeader();
      if (authHeader != null) {
        options.headers[ApiHeaders.authorization] = authHeader;
      }
    }

    // 요청 ID 추가 (디버깅용)
    if (kDebugMode) {
      options.headers['X-Request-ID'] =
          DateTime.now().millisecondsSinceEpoch.toString();
    }

    handler.next(options);
  }

  // 응답 후 처리
  Future<void> _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // 응답 데이터 검증
    if (response.statusCode == 200 || response.statusCode == 201) {
      handler.next(response);
    } else {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        ),
      );
    }
  }

  // 에러 처리
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 에러 시 토큰 갱신 시도
    if (error.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken(error.requestOptions);
      if (refreshed) {
        // 토큰 갱신 성공 시 원래 요청 재시도
        try {
          final response = await _dio.fetch(error.requestOptions);
          handler.resolve(response);
          return;
        } catch (e) {
          // 재시도 실패 시 원래 에러 전달
        }
      } else {
        // 토큰 갱신 실패 시 로그아웃 처리
        await _handleLogout();
      }
    }

    handler.next(error);
  }

  // 재시도 인터셉터 생성
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        // 재시도 가능한 에러인지 확인
        if (_shouldRetry(error) && _getRetryCount(error) < 3) {
          _incrementRetryCount(error);

          // 지수 백오프로 재시도
          final delay = Duration(seconds: _getRetryCount(error) * 2);
          await Future.delayed(delay);

          try {
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } catch (e) {
            // 재시도 실패 시 원래 에러 전달
          }
        }

        handler.next(error);
      },
    );
  }

  // === HTTP 메서드들 ===

  // GET 요청
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // POST 요청
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // PUT 요청
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // PATCH 요청
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // DELETE 요청
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // 파일 업로드
  Future<ApiResponse<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    T Function(Map<String, dynamic>)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fieldName: await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {ApiHeaders.contentType: ApiHeaders.multipartFormData},
        ),
        onSendProgress: onSendProgress,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // === 헬퍼 메서드들 ===

  // 응답 처리
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      return ApiResponse.fromJson(responseData, fromJson);
    } else {
      return ApiResponse.success(
        data: responseData as T,
        statusCode: response.statusCode,
      );
    }
  }

  // 에러 처리
  ApiResponse<T> _handleError<T>(dynamic error) {
    final apiException = ApiExceptionFactory.fromException(
      error is Exception ? error : Exception(error.toString()),
    );

    return ApiResponse.error(
      error: apiException.message,
      statusCode: apiException.statusCode,
    );
  }

  // 인증이 필요한 엔드포인트인지 확인
  bool _isAuthRequired(String path) {
    const publicPaths = [
      ApiEndpoints.login,
      ApiEndpoints.register,
      ApiEndpoints.socialLogin,
      ApiEndpoints.healthCheck,
    ];

    return !publicPaths.contains(path);
  }

  // 토큰 갱신 시도
  Future<bool> _tryRefreshToken(RequestOptions requestOptions) async {
    try {
      final refreshToken = _tokenManager.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {ApiHeaders.authorization: 'Bearer $refreshToken'},
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final newAccessToken = responseData['accessToken'] as String;
        final newRefreshToken = responseData['refreshToken'] as String?;

        await _tokenManager.saveAccessToken(newAccessToken);
        if (newRefreshToken != null) {
          await _tokenManager.saveRefreshToken(newRefreshToken);
        }

        // 새 토큰으로 헤더 업데이트
        requestOptions.headers[ApiHeaders.authorization] =
            'Bearer $newAccessToken';

        return true;
      }
    } catch (e) {
      debugPrint('토큰 갱신 실패: $e');
    }

    return false;
  }

  // 로그아웃 처리
  Future<void> _handleLogout() async {
    await _tokenManager.clearTokens();
    // TODO: 로그인 화면으로 이동하는 로직 추가
  }

  // 재시도 가능한 에러인지 확인
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  // 재시도 횟수 조회
  int _getRetryCount(DioException error) {
    return error.requestOptions.extra['retryCount'] ?? 0;
  }

  // 재시도 횟수 증가
  void _incrementRetryCount(DioException error) {
    final currentCount = _getRetryCount(error);
    error.requestOptions.extra['retryCount'] = currentCount + 1;
  }

  // Dio 인스턴스 접근 (고급 사용자용)
  Dio get dio => _dio;
}
