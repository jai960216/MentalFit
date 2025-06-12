import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'token_manager.dart';

class ApiClient {
  static ApiClient? _instance;
  late Dio _dio;
  late TokenManager _tokenManager;

  ApiClient._();

  static Future<ApiClient> getInstance() async {
    if (_instance == null) {
      _instance = ApiClient._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _tokenManager = await TokenManager.getInstance();

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // 로깅 인터셉터 (개발 모드)
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

    // 인증 토큰 인터셉터
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 토큰이 필요한 요청에 Authorization 헤더 추가
          if (_isAuthRequired(options.path)) {
            final authHeader = await _tokenManager.getAuthorizationHeader();
            if (authHeader != null) {
              options.headers['Authorization'] = authHeader;
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // 401 에러 시 토큰 갱신 시도
          if (error.response?.statusCode == 401) {
            // 여기서는 간단하게 로그아웃 처리
            await _tokenManager.clearTokens();
          }
          handler.next(error);
        },
      ),
    );
  }

  bool _isAuthRequired(String path) {
    // 인증이 필요 없는 엔드포인트들
    const publicPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/social',
      '/auth/reset-password',
    ];

    return !publicPaths.any((publicPath) => path.contains(publicPath));
  }

  // === HTTP 메서드들 ===
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // === 파일 업로드 메서드 추가 ===
  Future<ApiResponse<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fileName,
    Map<String, dynamic>? data,
    String fileField = 'file',
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        fileField: await MultipartFile.fromFile(filePath, filename: fileName),
        if (data != null) ...data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // === 응답 처리 ===
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (fromJson != null && response.data != null) {
        try {
          final data = fromJson(response.data as Map<String, dynamic>);
          return ApiResponse.success(data);
        } catch (e) {
          return ApiResponse.error('데이터 파싱 오류: $e');
        }
      } else {
        return ApiResponse.success(response.data as T);
      }
    } else {
      return ApiResponse.error('서버 오류: ${response.statusCode}');
    }
  }

  ApiResponse<T> _handleError<T>(dynamic error) {
    String errorMessage = '알 수 없는 오류가 발생했습니다.';

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = '연결 시간이 초과되었습니다.';
          break;
        case DioExceptionType.connectionError:
          errorMessage = '네트워크 연결을 확인해주세요.';
          break;
        case DioExceptionType.badResponse:
          errorMessage = '서버 응답 오류: ${error.response?.statusCode}';
          break;
        default:
          errorMessage = '네트워크 오류가 발생했습니다.';
      }
    }

    debugPrint('API 오류: $errorMessage');
    return ApiResponse.error(errorMessage);
  }
}
