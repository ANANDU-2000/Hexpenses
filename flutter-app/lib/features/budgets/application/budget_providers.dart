import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/sync/ledger_sync_service.dart';

/// Budget rows for a month — served from Drift after sync.
final budgetsForMonthProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, monthKey) {
      ref.watch(ledgerSyncServiceProvider);
      return ref.watch(ledgerDatabaseProvider).watchBudgetsForMonth(monthKey);
    });
