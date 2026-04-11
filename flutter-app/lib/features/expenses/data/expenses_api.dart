import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class ExpensesApi {
  ExpensesApi(this._dio);

  final Dio _dio;

  /// Raw response for offline sync (handles Nest `{ success, data }` or bare list).
  Future<Response<dynamic>> rawListResponse({String? accountId}) {
    return _dio.get<dynamic>(
      '/expenses',
      queryParameters: {
        if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
      },
    );
  }

  Future<List<Map<String, dynamic>>> list({String? accountId}) async {
    final res = await rawListResponse(accountId: accountId);
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> create({
    required double amount,
    required String categoryId,
    String? subCategoryId,
    required String dateIso,
    String? note,
    String? accountId,
    bool taxable = false,
    String? taxScheme,
    double? taxAmount,
  }) async {
    final res = await _dio.post<dynamic>(
      '/expenses',
      data: {
        'amount': amount,
        'categoryId': categoryId,
        if (subCategoryId != null && subCategoryId.isNotEmpty)
          'subCategoryId': subCategoryId,
        'date': dateIso,
        if (note != null && note.isNotEmpty) 'note': note,
        if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
        'taxable': taxable,
        if (taxable && taxScheme != null) 'taxScheme': taxScheme,
        if (taxable && taxAmount != null) 'taxAmount': taxAmount,
      },
    );
    final raw = res.data;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'];
      if (raw['success'] == true && inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
      return raw;
    }
    return <String, dynamic>{};
  }

  Future<void> delete(String id) async {
    await _dio.delete('/expenses/$id');
  }
}

final expensesApiProvider = Provider<ExpensesApi>(
  (ref) => ExpensesApi(ref.watch(dioProvider)),
);
