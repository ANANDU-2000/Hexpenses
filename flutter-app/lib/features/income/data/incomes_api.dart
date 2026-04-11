import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class IncomesApi {
  IncomesApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list({
    String? startDate,
    String? endDate,
    String? source,
    String? accountId,
  }) async {
    final res = await _dio.get<dynamic>(
      '/incomes',
      queryParameters: {
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        if (source != null && source.isNotEmpty) 'source': source,
        if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
      },
    );
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> create({
    required double amount,
    required String source,
    required String dateIso,
    required String accountId,
    String? note,
  }) async {
    final res = await _dio.post<dynamic>(
      '/incomes',
      data: {
        'amount': amount,
        'source': source,
        'date': dateIso,
        'accountId': accountId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<void> delete(String id) async {
    await _dio.delete('/incomes/$id');
  }
}

final incomesApiProvider = Provider<IncomesApi>(
  (ref) => IncomesApi(ref.watch(dioProvider)),
);
