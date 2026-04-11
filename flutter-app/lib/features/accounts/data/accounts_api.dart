import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class AccountsLedger {
  const AccountsLedger({required this.accounts, required this.summary});

  final List<Map<String, dynamic>> accounts;
  final Map<String, dynamic> summary;

  factory AccountsLedger.fromJson(Map<String, dynamic> json) {
    final raw = json['accounts'];
    final list = raw is List
        ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];
    final s = json['summary'];
    return AccountsLedger(
      accounts: list,
      summary: s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{},
    );
  }

  /// Backward-compatible: bare array, shaped ledger map, or `{ success, data }`.
  factory AccountsLedger.fromResponse(dynamic data) {
    dynamic resolved = data;
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      if (m['success'] == true && m['data'] != null) {
        resolved = m['data'];
      }
    }
    if (resolved is List) {
      return AccountsLedger(
        accounts: resolved
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        summary: const {},
      );
    }
    if (resolved is Map) {
      return AccountsLedger.fromJson(Map<String, dynamic>.from(resolved));
    }
    return const AccountsLedger(accounts: [], summary: {});
  }
}

class AccountsApi {
  AccountsApi(this._dio);

  final Dio _dio;

  Future<Response<dynamic>> rawLedgerResponse() =>
      _dio.get<dynamic>('/accounts');

  Future<AccountsLedger> fetchLedger() async {
    final res = await rawLedgerResponse();
    return AccountsLedger.fromResponse(res.data);
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String type,
    double? initialBalance,
  }) async {
    final res = await _dio.post<dynamic>(
      '/accounts',
      data: {'name': name, 'type': type, 'initialBalance': ?initialBalance},
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<AccountsLedger> transfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String? note,
  }) async {
    final res = await _dio.post<dynamic>(
      '/accounts/transfer',
      data: {
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return AccountsLedger.fromResponse(res.data);
  }
}

final accountsApiProvider = Provider<AccountsApi>(
  (ref) => AccountsApi(ref.watch(dioProvider)),
);
