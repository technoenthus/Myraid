class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const AppException({
    required this.message,
    this.code,
    this.statusCode,
  });

  factory AppException.unauthorized() => const AppException(
        message: 'Session expired. Please log in again.',
        code: 'UNAUTHORIZED',
        statusCode: 401,
      );

  factory AppException.networkError() => const AppException(
        message: 'No internet connection. Please check your network.',
        code: 'NETWORK_ERROR',
      );

  factory AppException.serverError() => const AppException(
        message: 'Server error. Please try again later.',
        code: 'SERVER_ERROR',
      );

  factory AppException.notFound() => const AppException(
        message: 'Resource not found.',
        code: 'NOT_FOUND',
        statusCode: 404,
      );

  factory AppException.unknown(String message) => AppException(
        message: message,
        code: 'UNKNOWN',
      );

  @override
  String toString() => message;
}
