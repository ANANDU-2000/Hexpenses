import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class CategoriesApi {
  CategoriesApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<dynamic>('/categories');
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> createCategory(String name) async {
    final res = await _dio.post<dynamic>('/categories', data: {'name': name});
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }
}

final categoriesApiProvider = Provider<CategoriesApi>(
  (ref) => CategoriesApi(ref.watch(dioProvider)),
);
