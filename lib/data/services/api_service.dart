import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeout),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {}, // suppress in production
      ),
    );
  }

  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final res = await _dio.post(path, data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: queryParameters);
      return res.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final res = await _dio.put(path, data: data);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return AppException.networkError();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return AppException.unauthorized();
        if (code == 404) return AppException.notFound();
        if (code != null && code >= 500) return AppException.serverError();
        final msg = e.response?.data?['message'] as String?;
        return AppException.unknown(msg ?? 'Request failed ($code)');
      default:
        return AppException.unknown(
            e.message ?? 'An unexpected error occurred');
    }
  }
}
