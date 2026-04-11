import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<({String access, String refresh, String? sessionId})> login(
    String email,
    String password,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    return _tokensFrom(res.data);
  }

  Future<({String access, String refresh, String? sessionId})> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    return _tokensFrom(res.data);
  }

  ({String access, String refresh, String? sessionId}) _tokensFrom(
    Map<String, dynamic>? raw,
  ) {
    final data = unwrapApiMap(raw) ?? raw ?? <String, dynamic>{};
    final access = data['access'] as String? ?? '';
    final refresh = data['refresh'] as String? ?? '';
    final sessionId = data['sessionId'] as String?;
    if (access.isEmpty) throw StateError('No access token in response');
    return (access: access, refresh: refresh, sessionId: sessionId);
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);
