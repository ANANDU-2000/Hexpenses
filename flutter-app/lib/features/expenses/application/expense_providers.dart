import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/no_api_seed_data.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../data/categories_api.dart';

/// Offline-first: Drift is the source of truth; [LedgerSyncService] keeps it fresh.
final expensesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) {
    ref.watch(ledgerSyncServiceProvider);
    return ref.watch(ledgerDatabaseProvider).watchExpensesForList();
  },
);

/// Expenses for one account, derived from the same offline stream.
final expensesForAccountProvider = Provider.autoDispose
    .family<AsyncValue<List<Map<String, dynamic>>>, String>((ref, accountId) {
      return ref
          .watch(expensesProvider)
          .whenData(
            (list) => list.where((e) {
              final aid = e['account'] is Map
                  ? (e['account'] as Map)['id']?.toString()
                  : e['accountId']?.toString();
              return aid == accountId;
            }).toList(),
          );
    });

final categoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      if (kNoApiMode) {
        return List<Map<String, dynamic>>.from(noApiDemoCategories);
      }
      final rows = await ref.watch(categoriesApiProvider).list();
      return rows.where((row) {
        final type = row['type']?.toString();
        return type == null || type.isEmpty || type == 'expense';
      }).toList();
    });
