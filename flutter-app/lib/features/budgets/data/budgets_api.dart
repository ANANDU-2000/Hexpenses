import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class BudgetsApi {
  BudgetsApi(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> rawListResponse({String? month}) {
    return _dio.get<dynamic>(
      '/budgets',
      queryParameters: {if (month != null && month.isNotEmpty) 'month': month},
    );
  }

  static String monthQueryParam([DateTime? d]) {
    final n = d ?? DateTime.now();
    return '${n.year}-${n.month}';
  }

  Future<List<Map<String, dynamic>>> list({String? month}) async {
    final res = await rawListResponse(month: month);
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> create({
    required String categoryId,
    required double limit,
    String? month,
  }) async {
    final res = await _dio.post<dynamic>(
      '/budgets',
      data: {
        'categoryId': categoryId,
        'limit': limit,
        if (month != null && month.isNotEmpty) 'month': month,
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> update({
    required String id,
    required double limit,
  }) async {
    final res = await _dio.patch<dynamic>(
      '/budgets/$id',
      data: {'limit': limit},
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<void> delete(String id) async {
    await _dio.delete('/budgets/$id');
  }
}

final budgetsApiProvider = Provider<BudgetsApi>(
  (ref) => BudgetsApi(ref.watch(dioProvider)),
);
