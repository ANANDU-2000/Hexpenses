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
    final res = await _dio.get<dynamic>(
      '/notifications',
      queryParameters: {
        if (category case final String c when c.isNotEmpty) 'category': c,
        if (unreadOnly == true) 'unreadOnly': 'true',
        if (limit case final int l) 'limit': l,
      },
    );
    final body = unwrapApiMap(res.data) ?? {};
    final raw = body['notifications'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> markRead(String id) async {
    final res = await _dio.patch<dynamic>('/notifications/$id/read');
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<void> markAllRead() async {
    await _dio.post<void>('/notifications/mark-all-read');
  }
}

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.watch(dioProvider)),
);
