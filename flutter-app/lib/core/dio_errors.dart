import 'package:dio/dio.dart';

import 'api_base_resolve.dart';

/// User-facing text for common Dio failures (e.g. backend not running).
String dioErrorMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      final base = resolveApiBase();
      return 'Cannot reach the API at $base. '
          'Start the backend: cd nest-backend && npm run start:dev '
          '(listening on port 4000). '
          'If the server exits on startup, fix DATABASE_URL in nest-backend/.env (Prisma P1000 = bad Postgres credentials). '
          'Web: edit window.MONEYFLOW_API_BASE in web/index.html. '
          'Other platforms: flutter run --dart-define=API_BASE=http://YOUR_HOST:PORT/api';
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Request timed out. Check your network and that the API is running.';
    case DioExceptionType.badResponse:
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final m = data['message'];
        return m is List ? m.join(', ') : m.toString();
      }
      return e.response?.statusMessage ?? 'Server error (${e.response?.statusCode})';
    default:
      break;
  }
  return e.message ?? 'Something went wrong';
}
