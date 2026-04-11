import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class NotificationsApi {
  NotificationsApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list({
    String? category,
    bool? unreadOnly,
    int? limit,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (unreadOnly == true) 'unreadOnly': 'true',
        'limit': ?limit,
      },
    );
    final body = unwrapApiMap(res.data) ?? res.data ?? {};
    final raw = body['notifications'];
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> markRead(String id) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/notifications/$id/read',
    );
    return unwrapApiMap(res.data) ?? res.data ?? {};
  }

  Future<void> markAllRead() async {
    await _dio.post<void>('/notifications/mark-all-read');
  }
}

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(dioProvider)),
);
