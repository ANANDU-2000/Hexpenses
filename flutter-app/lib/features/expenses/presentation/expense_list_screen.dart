import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/app_skeleton.dart';
import '../../../core/design_system/transaction_tile.dart';
import '../../../core/dio_errors.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../application/expense_providers.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key, this.accountId, this.accountName});

  final String? accountId;
  final String? accountName;

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AsyncValue<List<Map<String, dynamic>>> _watchExpenses() {
    return widget.accountId != null
        ? ref.watch(expensesForAccountProvider(widget.accountId!))
        : ref.watch(expensesProvider);
  }

  Future<void> _refresh() async {
    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
  }

  Future<bool?> _showDeleteDialog(BuildContext context, String label) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          label.isEmpty
              ? 'This expense will be removed from your ledger.'
              : 'Delete "$label" from your expense history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    try {
      await ref.read(ledgerSyncServiceProvider).deleteExpenseOffline(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Expense removed'),
        ),
      );
    } on DioException catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(dioErrorMessage(err)),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterExpenses(List<Map<String, dynamic>> list) {
    if (_search.isEmpty) return list;
    return list.where((expense) {
      final category = expense['category'] is Map
          ? (expense['category'] as Map)['name']?.toString() ?? ''
          : '';
      final note = expense['note']?.toString() ?? '';
      final date = expense['date']?.toString() ?? '';
      final amount = expense['amount']?.toString() ?? '';
      final haystack = '$category $note $date $amount'.toLowerCase().replaceAll(
        '\n',
        ' ',
      );
      return haystack.contains(_search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final async = _watchExpenses();

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          widget.accountId != null
              ? (widget.accountName != null
                    ? '${widget.accountName} · expenses'
                    : 'Account expenses')
              : 'Expenses',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MfSpace.lg,
              0,
              MfSpace.lg,
              MfSpace.sm,
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.dmSans(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search expenses…',
                hintStyle: GoogleFonts.dmSans(
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                filled: true,
                fillColor: const Color(0x0AFFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MfRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: cs.onSurface.withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Record spending to populate your ledger, budgets, and insights. Everything stays grouped by category.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          LedgerPageRoutes.fadeSlide<void>(
                            AddExpenseScreen(
                              initialAccountId: widget.accountId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Record your first expense'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(220, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = _filterExpenses(list);
          if (filtered.isEmpty) {
            return RefreshIndicator(
              color: cs.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  MfSpace.xxl,
                  MfSpace.sm,
                  MfSpace.xxl,
                  100,
                ),
                children: const [
                  LedgerEmptyState(
                    title: 'No matching expenses',
                    subtitle:
                        'Try a different search term to find a specific transaction.',
                    icon: Icons.search_off_rounded,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                MfSpace.xxl,
                MfSpace.sm,
                MfSpace.xxl,
                100,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final expense = filtered[i];
                final category = expense['category'] is Map
                    ? (expense['category'] as Map)['name']?.toString() ?? ''
                    : '';
                final rawAmt = expense['amount']?.toString() ?? '0';
                final amountStr = '$kCurrencySymbol$rawAmt';
                final id = expense['id']?.toString() ?? '';
                final letter = category.isNotEmpty
                    ? category.substring(0, 1).toUpperCase()
                    : '?';
                return Padding(
                  padding: const EdgeInsets.only(bottom: MfSpace.md),
                  child: Dismissible(
                    key: ValueKey(id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: MfSpace.xxl),
                      decoration: BoxDecoration(
                        color: MfPalette.expenseRed.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(MfRadius.lg),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: MfPalette.expenseRed,
                      ),
                    ),
                    confirmDismiss: (_) => _showDeleteDialog(
                      context,
                      category.isEmpty ? 'Expense' : category,
                    ),
                    onDismissed: (_) => _delete(id),
                    child: TransactionTile(
                      title: category.isEmpty ? 'Expense' : category,
                      subtitle:
                          expense['note']?.toString().trim().isNotEmpty == true
                          ? expense['note'].toString()
                          : (expense['date']?.toString() ?? ''),
                      amount: amountStr,
                      isExpense: true,
                      avatarColor: MfPalette.expenseRed,
                      avatarLabel: letter,
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
          onRetry: _refresh,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            LedgerPageRoutes.fadeSlide<void>(
              AddExpenseScreen(initialAccountId: widget.accountId),
            ),
          );
        },
        backgroundColor: MfPalette.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add expense',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
