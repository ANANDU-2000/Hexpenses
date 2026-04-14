import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../api_config.dart';
import '../../api_envelope.dart';
import '../db/ledger_database.dart';
import '../no_api_seed_data.dart';
import '../../../features/accounts/data/accounts_api.dart';
import '../../../features/budgets/data/budgets_api.dart';
import '../../../features/expenses/data/expenses_api.dart';

final ledgerDatabaseProvider = Provider<LedgerDatabase>((ref) {
  final db = LedgerDatabase();
  ref.onDispose(db.close);
  return db;
});

final ledgerSyncServiceProvider = Provider<LedgerSyncService>((ref) {
  final svc = LedgerSyncService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});

/// Pulls remote ledger data into Drift and flushes the outbox when the device is online.
class LedgerSyncService {
  LedgerSyncService(this._ref) {
    _sub = Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  final Ref _ref;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _pullInFlight = false;

  LedgerDatabase get _db => _ref.read(ledgerDatabaseProvider);
  ExpensesApi get _expensesApi => _ref.read(expensesApiProvider);
  AccountsApi get _accountsApi => _ref.read(accountsApiProvider);
  BudgetsApi get _budgetsApi => _ref.read(budgetsApiProvider);

  void dispose() {
    unawaited(_sub?.cancel());
  }

  Future<bool> get _online async {
    final r = await Connectivity().checkConnectivity();
    if (r.isEmpty) return false;
    return !r.contains(ConnectivityResult.none);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (kNoApiMode) return;
    if (!results.contains(ConnectivityResult.none)) {
      unawaited(pullAndFlush());
    }
  }

  Future<void> ensureNoApiSeed() async {
    if (!kNoApiMode) return;
    final existing = await _db.select(_db.cachedAccounts).get();
    if (existing.isNotEmpty) return;
    await _db.upsertAccountFromServer({
      'id': noApiDemoAccountId,
      'name': 'Cash (offline)',
      'type': 'cash',
      'balance': 0,
      'currency': 'INR',
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _db.upsertKv('accounts_summary', jsonEncode(<String, dynamic>{}));
  }

  Future<void> pullAndFlush() async {
    if (kNoApiMode) return;
    if (!await _online) return;
    if (_pullInFlight) return;
    _pullInFlight = true;
    try {
      await Future.wait([_pullExpenses(), _pullAccounts(), _pullBudgets()]);
      await flushOutbox();
    } finally {
      _pullInFlight = false;
    }
  }

  Future<void> _pullExpenses() async {
    final res = await _expensesApi.rawListResponse();
    final list = unwrapApiList(res.data);
    for (final row in list) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (await _db.shouldSkipExpensePull(id)) {
        await _maybeFlagExpenseConflict(id, row);
        continue;
      }
      await _db.upsertExpenseFromServer(row);
    }
  }

  Future<void> _maybeFlagExpenseConflict(
    String id,
    Map<String, dynamic> serverRow,
  ) async {
    final local = await (_db.select(
      _db.cachedExpenses,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (local == null) return;
    final st = LedgerSyncStatus.values[local.syncStatus];
    if (st != LedgerSyncStatus.pendingPush) return;
    final serverAt = LedgerDatabase.parseServerIso(
      serverRow['updatedAt'] as String?,
    );
    final base = local.lastKnownServerAt;
    if (serverAt != null && base != null && serverAt.isAfter(base)) {
      await _db.markExpenseConflict(id, serverRow);
    }
  }

  Future<void> _pullAccounts() async {
    final res = await _accountsApi.rawLedgerResponse();
    dynamic data = res.data;
    if (data is Map && data['success'] == true) {
      data = data['data'];
    }
    final ledger = AccountsLedger.fromResponse(data);
    await _db.upsertKv('accounts_summary', jsonEncode(ledger.summary));
    for (final row in ledger.accounts) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (await _db.shouldSkipAccountPull(id)) continue;
      await _db.upsertAccountFromServer(row);
    }
  }

  Future<void> _pullBudgets() async {
    await pullBudgetsForMonth(BudgetsApi.monthQueryParam());
  }

  Future<void> pullBudgetsForMonth(String monthKey) async {
    if (kNoApiMode) return;
    if (!await _online) return;
    final res = await _budgetsApi.rawListResponse(month: monthKey);
    final list = unwrapApiList(res.data);
    for (final row in list) {
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (await _db.shouldSkipBudgetPull(id)) continue;
      await _db.upsertBudgetFromServer(row, monthKey);
    }
  }

  Future<void> flushOutbox() async {
    if (kNoApiMode) return;
    if (!await _online) return;
    final ops = await _db.pendingOutbox();
    for (final op in ops) {
      try {
        switch (op.opCode) {
          case 'expense.create':
            await _flushExpenseCreate(op);
            break;
          case 'expense.delete':
            await _flushExpenseDelete(op);
            break;
          default:
            await _db.removeOutbox(op.localId);
        }
      } catch (e) {
        await _db.bumpOutboxError(op.localId, op.attempts + 1, e.toString());
      }
    }
  }

  Future<void> _flushExpenseCreate(SyncOutboxData op) async {
    final body = Map<String, dynamic>.from(jsonDecode(op.payloadJson) as Map);
    final tempId = body['tempId'] as String? ?? op.entityId;
    final created = await _expensesApi.create(
      amount: (body['amount'] as num).toDouble(),
      categoryId: body['categoryId'] as String,
      subCategoryId: body['subCategoryId'] as String?,
      dateIso: body['dateIso'] as String,
      note: body['note'] as String?,
      accountId: body['accountId'] as String?,
      taxable: body['taxable'] as bool? ?? false,
      taxScheme: body['taxScheme'] as String?,
      taxAmount: (body['taxAmount'] as num?)?.toDouble(),
    );
    final unwrapped = _unwrapEntity(created);
    await _db.replaceExpenseId(tempId, unwrapped);
    await _db.removeOutbox(op.localId);
  }

  Future<void> _flushExpenseDelete(SyncOutboxData op) async {
    final id = op.entityId;
    await _expensesApi.delete(id);
    await _db.transaction(() async {
      await (_db.delete(
        _db.cachedExpenses,
      )..where((t) => t.id.equals(id))).go();
      await _db.removeOutbox(op.localId);
    });
  }

  Map<String, dynamic> _unwrapEntity(Map<String, dynamic> raw) {
    if (raw['success'] == true && raw['data'] is Map) {
      return Map<String, dynamic>.from(raw['data'] as Map);
    }
    return raw;
  }

  static const _uuid = Uuid();

  Future<void> createExpenseOffline({
    required double amount,
    required String categoryId,
    String? categoryName,
    String? subCategoryId,
    required String dateIso,
    String? note,
    String? accountId,
    bool taxable = false,
    String? taxScheme,
    double? taxAmount,
  }) async {
    final tempId = 'local_${_uuid.v4()}';
    final payload = <String, dynamic>{
      'id': tempId,
      'amount': amount.toString(),
      'categoryId': categoryId,
      'category': {'id': categoryId, 'name': categoryName ?? ''},
      if (accountId != null) 'account': {'id': accountId},
      'date': dateIso,
      if (note != null) 'note': note,
      if (accountId != null) 'accountId': accountId,
      if (!kNoApiMode) '_offlinePending': true,
    };
    if (kNoApiMode) {
      final now = DateTime.now().toUtc();
      await _db
          .into(_db.cachedExpenses)
          .insert(
            CachedExpensesCompanion.insert(
              id: tempId,
              payloadJson: jsonEncode(payload),
              syncStatus: LedgerSyncStatus.synced.index,
              clientRevisionAt: now,
              lastKnownServerAt: const Value.absent(),
              expenseSortDate: LedgerDatabase.expenseSortDateFromPayload(
                payload,
              ),
            ),
          );
      return;
    }
    await _db.insertPendingExpense(id: tempId, payload: payload);
    await _db.enqueueOutbox(
      opCode: 'expense.create',
      entityId: tempId,
      payload: {
        'tempId': tempId,
        'amount': amount,
        'categoryId': categoryId,
        if (subCategoryId != null) 'subCategoryId': subCategoryId,
        'dateIso': dateIso,
        if (note != null) 'note': note,
        if (accountId != null) 'accountId': accountId,
        'taxable': taxable,
        if (taxScheme != null) 'taxScheme': taxScheme,
        if (taxAmount != null) 'taxAmount': taxAmount,
      },
      idempotencyKey: _uuid.v4(),
    );
    if (await _online) await flushOutbox();
  }

  Future<void> deleteExpenseOffline(String id) async {
    if (kNoApiMode) {
      await _db.transaction(() async {
        await (_db.delete(
          _db.cachedExpenses,
        )..where((t) => t.id.equals(id))).go();
        await (_db.delete(
          _db.syncOutbox,
        )..where((t) => t.entityId.equals(id))).go();
      });
      return;
    }
    if (id.startsWith('local_')) {
      await _db.transaction(() async {
        await (_db.delete(
          _db.cachedExpenses,
        )..where((t) => t.id.equals(id))).go();
        await (_db.delete(
          _db.syncOutbox,
        )..where((t) => t.entityId.equals(id))).go();
      });
      return;
    }
    await _db.markExpensePendingDelete(id);
    await _db.enqueueOutbox(
      opCode: 'expense.delete',
      entityId: id,
      payload: const {},
      idempotencyKey: _uuid.v4(),
    );
    if (await _online) await flushOutbox();
  }
}
