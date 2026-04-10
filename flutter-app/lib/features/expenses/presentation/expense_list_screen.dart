import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/design_system/app_skeleton.dart';
import '../../../core/design_system/transaction_tile.dart';
import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../application/expense_providers.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key, this.accountId, this.accountName});

  final String? accountId;
  final String? accountName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = accountId != null
        ? ref.watch(expensesForAccountProvider(accountId!))
        : ref.watch(expensesProvider);

    Future<void> refresh() async {
      await ref.read(ledgerSyncServiceProvider).pullAndFlush();
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: accountId != null
          ? AppBar(
              title: Text(accountName != null ? '$accountName · expenses' : 'Account expenses'),
            )
          : AppBar(title: const Text('Expenses')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return LedgerEmptyState(
              title: 'No expenses yet',
              subtitle:
                  'Record spending to populate your ledger, budgets, and insights. Everything stays grouped by category.',
              icon: Icons.receipt_long_outlined,
              actionLabel: 'Add expense',
              onAction: () {
                Navigator.of(context).push(
                  LedgerPageRoutes.fadeSlide<void>(
                    AddExpenseScreen(initialAccountId: accountId),
                  ),
                );
              },
            );
          }
          return RefreshIndicator(
            color: cs.primary,
            onRefresh: refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(MfSpace.xxl, MfSpace.sm, MfSpace.xxl, 88),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final e = list[i];
                final cat = (e['category'] is Map) ? (e['category'] as Map)['name']?.toString() ?? '' : '';
                final amt = e['amount']?.toString() ?? '0';
                final id = e['id']?.toString() ?? '';
                final letter = cat.isNotEmpty ? cat.substring(0, 1).toUpperCase() : '?';
                return Padding(
                  padding: const EdgeInsets.only(bottom: MfSpace.md),
                  child: TransactionTile(
                    title: cat.isEmpty ? 'Expense' : cat,
                    subtitle: e['note']?.toString().trim().isNotEmpty == true
                        ? e['note'].toString()
                        : (e['date']?.toString() ?? ''),
                    amountLabel: '-$amt',
                    leadingLabel: letter,
                    isExpense: true,
                    animationIndex: i,
                    endAction: IconButton(
                      icon: Icon(Icons.delete_outline, color: cs.onSurface.withValues(alpha: 0.45)),
                      onPressed: () async {
                        try {
                          await ref.read(ledgerSyncServiceProvider).deleteExpenseOffline(id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Expense removed'),
                              ),
                            );
                          }
                        } on DioException catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(dioErrorMessage(err)),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Padding(
              padding: EdgeInsets.all(MfSpace.xxl),
              child: TransactionListSkeleton(count: 8),
            ),
        error: (e, _) => LedgerErrorState(
          title: 'Couldn’t load expenses',
          message: e is DioException ? dioErrorMessage(e) : e.toString(),
          onRetry: refresh,
        ),
      ),
      floatingActionButton: LedgerFab(
        tooltip: 'Add expense',
        onPressed: () {
          Navigator.of(context).push(
            LedgerPageRoutes.fadeSlide<void>(
              AddExpenseScreen(initialAccountId: accountId),
            ),
          );
        },
        icon: Icons.add,
      ),
    );
  }
}
