import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class RecurringApi {
  RecurringApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<dynamic>('/recurring');
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> setActive({
    required String id,
    required bool active,
  }) async {
    final res = await _dio.patch<dynamic>(
      '/recurring/$id/active',
      data: {'active': active},
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> create({
    required double amount,
    required String frequency,
    required String nextDateIso,
    required String categoryId,
    required String title,
    String? note,
  }) async {
    final res = await _dio.post<dynamic>(
      '/recurring',
      data: {
        'amount': amount,
        'frequency': frequency,
        'nextDate': nextDateIso,
        'categoryId': categoryId,
        'title': title,
        'note': ?note,
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }
}

final recurringApiProvider = Provider<RecurringApi>(
  (ref) => RecurringApi(ref.watch(dioProvider)),
);
