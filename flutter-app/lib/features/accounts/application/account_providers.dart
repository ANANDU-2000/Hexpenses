import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/sync/ledger_sync_service.dart';
import '../data/accounts_api.dart';

/// Offline-first ledger: accounts + summary from Drift (populated by [LedgerSyncService]).
final accountsProvider = StreamProvider.autoDispose<AccountsLedger>((ref) {
  ref.watch(ledgerSyncServiceProvider);
  final db = ref.watch(ledgerDatabaseProvider);
  return db.watchAccountsPayloads().asyncMap((accounts) async {
    final raw = await db.readKv('accounts_summary');
    Map<String, dynamic> summary = {};
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) summary = Map<String, dynamic>.from(decoded);
    }
    return AccountsLedger(accounts: accounts, summary: summary);
  });
});
