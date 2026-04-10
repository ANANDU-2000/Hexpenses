import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_base_resolve.dart';
import 'storage/token_storage.dart';

/// Override in `main()` after `TokenStorage.create()`.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError('tokenStorageProvider must be overridden');
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: resolveApiBase(),
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = storage.access;
        if (t != null && t.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        final sid = storage.sessionId;
        if (sid != null && sid.isNotEmpty) {
          options.headers['X-Session-Id'] = sid;
        }
        return handler.next(options);
      },
    ),
  );
  return dio;
});
