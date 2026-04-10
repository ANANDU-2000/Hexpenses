import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class InsuranceApi {
  InsuranceApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await _dio.get<List<dynamic>>('/insurance/policies');
    return (res.data ?? []).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String type,
    required double premium,
    required String startDate,
    required String expiryDate,
  }) async {
    final res = await _dio.post<dynamic>(
      '/insurance/policies',
      data: {
        'name': name,
        'type': type,
        'premium': premium,
        'startDate': startDate,
        'expiryDate': expiryDate,
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }
}

final insuranceApiProvider = Provider<InsuranceApi>((ref) => InsuranceApi(ref.watch(dioProvider)));
