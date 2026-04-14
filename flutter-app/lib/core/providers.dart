import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_base_resolve.dart';
import 'api_envelope.dart';
import 'storage/token_storage.dart';

/// Override in `main()` after `TokenStorage.create()`.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError('tokenStorageProvider must be overridden');
});

/// Dedupe concurrent refresh calls (many APIs 401 at once after access JWT expires).
Future<bool>? _refreshAccessTokenInFlight;

Future<bool> _refreshAccessToken(TokenStorage storage) {
  _refreshAccessTokenInFlight ??= _doRefreshAccessToken(storage).whenComplete(() {
    _refreshAccessTokenInFlight = null;
  });
  return _refreshAccessTokenInFlight!;
}

Future<bool> _doRefreshAccessToken(TokenStorage storage) async {
  final refresh = storage.refresh;
  if (refresh == null || refresh.isEmpty) return false;
  try {
    final client = Dio(
      BaseOptions(
        baseUrl: resolveApiBase(),
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    final res = await client.post<dynamic>(
      '/token/refresh',
      data: {'refreshToken': refresh},
    );
    final data = unwrapApiMap(res.data) ?? <String, dynamic>{};
    final access = data['access'] as String? ?? '';
    final newRefresh = data['refresh'] as String? ?? '';
    final sessionId = data['sessionId'] as String?;
    if (access.isEmpty) return false;
    await storage.saveTokens(
      access: access,
      refresh: newRefresh.isNotEmpty ? newRefresh : refresh,
      sessionId: sessionId,
    );
    return true;
  } catch (_) {
    await storage.clear();
    return false;
  }
}

bool _isAuthPathNoRetry(String path) {
  return path.contains('/token/refresh') ||
      path.contains('/auth/login') ||
      path.contains('/auth/register');
}

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
      onError: (err, handler) async {
        if (err.response?.statusCode != 401) {
          return handler.next(err);
        }
        final path = err.requestOptions.path;
        if (_isAuthPathNoRetry(path)) {
          return handler.next(err);
        }
        final ok = await _refreshAccessToken(storage);
        if (!ok) {
          return handler.next(err);
        }
        try {
          final opts = err.requestOptions;
          final access = storage.access;
          if (access == null || access.isEmpty) {
            return handler.next(err);
          }
          opts.headers['Authorization'] = 'Bearer $access';
          final sid = storage.sessionId;
          if (sid != null && sid.isNotEmpty) {
            opts.headers['X-Session-Id'] = sid;
          } else {
            opts.headers.remove('X-Session-Id');
          }
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {
          return handler.next(err);
        }
      },
    ),
  );
  return dio;
});
