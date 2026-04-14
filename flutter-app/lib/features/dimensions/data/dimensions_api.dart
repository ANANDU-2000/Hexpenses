import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class DimensionsApi {
  DimensionsApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> expenseTypes(String subCategoryId) async {
    final res = await _dio.get<dynamic>(
      '/dimensions/expense-types',
      queryParameters: {'subCategoryId': subCategoryId},
    );
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> createExpenseType({
    required String subCategoryId,
    required String name,
  }) async {
    final res = await _dio.post<dynamic>(
      '/dimensions/expense-types',
      data: {'subCategoryId': subCategoryId, 'name': name},
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> spendEntities({
    String? categoryId,
    String? subCategoryId,
  }) async {
    final res = await _dio.get<dynamic>(
      '/dimensions/entities',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (subCategoryId != null) 'subCategoryId': subCategoryId,
      },
    );
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> createSpendEntity({
    required String categoryId,
    required String subCategoryId,
    required String name,
    String kind = 'other',
    String? vehicleId,
  }) async {
    final res = await _dio.post<dynamic>(
      '/dimensions/entities',
      data: {
        'categoryId': categoryId,
        'subCategoryId': subCategoryId,
        'name': name,
        'kind': kind,
        if (vehicleId != null) 'vehicleId': vehicleId,
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }
}

final dimensionsApiProvider = Provider<DimensionsApi>(
  (ref) => DimensionsApi(ref.watch(dioProvider)),
);
