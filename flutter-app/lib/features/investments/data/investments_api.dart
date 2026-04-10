import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class InvestmentsApi {
  InvestmentsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> fetchPortfolio() async {
    final res = await _dio.get<dynamic>('/investments');
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String kind,
    required double investedAmount,
    required double currentValue,
    String? note,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/investments',
      data: {
        'name': name,
        'kind': kind,
        'investedAmount': investedAmount,
        'currentValue': currentValue,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return Map<String, dynamic>.from(res.data!);
  }

  Future<Map<String, dynamic>> update({
    required String id,
    String? name,
    String? kind,
    double? investedAmount,
    double? currentValue,
    String? note,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (kind != null) data['kind'] = kind;
    if (investedAmount != null) data['investedAmount'] = investedAmount;
    if (currentValue != null) data['currentValue'] = currentValue;
    if (note != null) data['note'] = note;
    final res = await _dio.patch<dynamic>('/investments/$id', data: data);
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/investments/$id');
  }
}

final investmentsApiProvider = Provider<InvestmentsApi>((ref) => InvestmentsApi(ref.watch(dioProvider)));
