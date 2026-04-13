import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_skeleton.dart';
import '../../../core/design_system/premium_fab.dart';
import '../../../core/design_system/transaction_tile.dart';
import '../../../core/dio_errors.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../application/expense_providers.dart';
import 'add_expense_screen.dart';

enum _SortMode { newest, highest }

double _expenseAmount(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

DateTime? _expenseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

String _expenseCategory(Map<String, dynamic> expense) {
  if (expense['category'] is Map) {
    return (expense['category'] as Map)['name']?.toString() ?? 'Expense';
  }
  return 'Expense';
}

String _formatExpenseCurrency(dynamic raw) {
  final value = _expenseAmount(raw);
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: MfCurrency.symbol,
    decimalDigits: value == value.roundToDouble() ? 0 : 2,
  ).format(value);
}

class _ExpenseCommand {
  const _ExpenseCommand({
    required this.textQuery,
    required this.category,
    required this.minAmount,
    required this.maxAmount,
    required this.from,
    required this.toExclusive,
    required this.sortMode,
    required this.chips,
  });

  final String textQuery;
  final String? category;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? from;
  final DateTime? toExclusive;
  final _SortMode sortMode;
  final List<String> chips;

  String get summary {
    if (chips.isEmpty) return 'All expenses ordered by newest activity.';
    return chips.join('  •  ');
  }

  bool matches(Map<String, dynamic> expense) {
    final categoryName = _expenseCategory(expense);
    final note = expense['note']?.toString() ?? '';
    final date = _expenseDate(expense['date']);
    final amount = _expenseAmount(expense['amount']);

    if (category != null &&
        categoryName.toLowerCase() != category!.toLowerCase()) {
      return false;
    }
    if (minAmount != null && amount < minAmount!) return false;
    if (maxAmount != null && amount > maxAmount!) return false;
    if (from != null && (date == null || date.isBefore(from!))) return false;
    if (toExclusive != null && (date == null || !date.isBefore(toExclusive!))) {
      return false;
    }
    if (textQuery.isNotEmpty) {
      final haystack =
          '$categoryName $note ${expense['date']} ${expense['amount']}'
              .toLowerCase()
              .replaceAll('\n', ' ');
      if (!haystack.contains(textQuery)) return false;
    }
    return true;
  }

  static _ExpenseCommand parse(String input, List<String> categories) {
    final trimmed = input.trim();
    var working = trimmed.toLowerCase();
    String? category;
    double? minAmount;
    double? maxAmount;
    DateTime? from;
    DateTime? toExclusive;
    String? dateLabel;
    var sortMode = _SortMode.newest;
    final chips = <String>[];

    void consume(String phrase) {
      working = working.replaceAll(phrase, ' ');
    }

    final betweenMatch = RegExp(
      r'between\s+(\d+(?:\.\d+)?)\s+(?:and|to)\s+(\d+(?:\.\d+)?)',
    ).firstMatch(working);
    if (betweenMatch != null) {
      minAmount = double.tryParse(betweenMatch.group(1)!);
      maxAmount = double.tryParse(betweenMatch.group(2)!);
      chips.add(
        'Between ${MfCurrency.symbol}${minAmount?.toStringAsFixed(0)} and ${MfCurrency.symbol}${maxAmount?.toStringAsFixed(0)}',
      );
      consume(betweenMatch.group(0)!);
    }

    final overMatch = RegExp(
      r'(?:over|above|more than)\s+(\d+(?:\.\d+)?)',
    ).firstMatch(working);
    if (overMatch != null) {
      minAmount = double.tryParse(overMatch.group(1)!);
      chips.add('Over ${MfCurrency.symbol}${minAmount?.toStringAsFixed(0)}');
      consume(overMatch.group(0)!);
    }

    final underMatch = RegExp(
      r'(?:under|below|less than)\s+(\d+(?:\.\d+)?)',
    ).firstMatch(working);
    if (underMatch != null) {
      maxAmount = double.tryParse(underMatch.group(1)!);
      chips.add('Under ${MfCurrency.symbol}${maxAmount?.toStringAsFixed(0)}');
      consume(underMatch.group(0)!);
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    if (working.contains('today')) {
      from = todayStart;
      toExclusive = todayStart.add(const Duration(days: 1));
      dateLabel = 'Today';
      consume('today');
    } else if (working.contains('yesterday')) {
      from = todayStart.subtract(const Duration(days: 1));
      toExclusive = todayStart;
      dateLabel = 'Yesterday';
      consume('yesterday');
    } else if (working.contains('last 7 days')) {
      from = todayStart.subtract(const Duration(days: 6));
      toExclusive = todayStart.add(const Duration(days: 1));
      dateLabel = 'Last 7 days';
      consume('last 7 days');
    } else if (working.contains('this week')) {
      final start = todayStart.subtract(Duration(days: now.weekday - 1));
      from = start;
      toExclusive = todayStart.add(const Duration(days: 1));
      dateLabel = 'This week';
      consume('this week');
    } else if (working.contains('this month')) {
      from = thisMonthStart;
      toExclusive = DateTime(now.year, now.month + 1, 1);
      dateLabel = 'This month';
      consume('this month');
    } else if (working.contains('last month')) {
      from = lastMonthStart;
      toExclusive = thisMonthStart;
      dateLabel = 'Last month';
      consume('last month');
    }

    if (dateLabel != null) chips.add(dateLabel);

    final sortedCategories = [...categories]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final candidate in sortedCategories) {
      final lower = candidate.toLowerCase();
      if (working.contains(lower)) {
        category = candidate;
        chips.add(candidate);
        consume(lower);
        break;
      }
    }

    if (working.contains('highest') ||
        working.contains('largest') ||
        working.contains('biggest') ||
        working.contains('top')) {
      sortMode = _SortMode.highest;
      chips.add('Highest first');
      working = working
          .replaceAll('highest', ' ')
          .replaceAll('largest', ' ')
          .replaceAll('biggest', ' ')
          .replaceAll('top', ' ');
    }

    final textQuery = working.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (textQuery.isNotEmpty) {
      chips.insert(0, '"$textQuery"');
    }

    return _ExpenseCommand(
      textQuery: textQuery,
      category: category,
      minAmount: minAmount,
      maxAmount: maxAmount,
      from: from,
      toExclusive: toExclusive,
      sortMode: sortMode,
      chips: chips,
    );
  }
}

class ExpenseListScreen extends ConsumerStatefulWidget {
  const ExpenseListScreen({super.key, this.accountId, this.accountName});

  final String? accountId;
  final String? accountName;

  @override
  ConsumerState<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends ConsumerState<ExpenseListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

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
              : 'Delete "$label" from your history?',
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

  void _applyQuery(String value) {
    setState(() {
      _query = value.trim();
      _searchController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = _watchExpenses();
    final title = widget.accountId != null
        ? (widget.accountName != null
              ? '${widget.accountName} expenses'
              : 'Account expenses')
        : 'Transaction search';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: mfPremiumCanvasGradient),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        MfPalette.accentSoftPurple.withValues(alpha: 0.14),
                        MfPalette.accentSoftPurple.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: async.when(
                data: (list) => _LoadedExpenseView(
                  title: title,
                  accountId: widget.accountId,
                  query: _query,
                  searchController: _searchController,
                  expenses: list,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  onApplyQuery: _applyQuery,
                  onRefresh: _refresh,
                  onConfirmDelete: (label) => _showDeleteDialog(context, label),
                  onDelete: _delete,
                ),
                loading: () => const _LoadingExpenseView(),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(MfSpace.xxl),
                  child: LedgerErrorState(
                    title: 'We could not load your expenses',
                    message: error is DioException
                        ? dioErrorMessage(error)
                        : error.toString(),
                    onRetry: _refresh,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: MoneyFlowPremiumExtendedFab(
        heroTag: 'expense_list_add',
        tooltip: 'Add expense',
        onPressed: () {
          Navigator.of(context).push(
            LedgerPageRoutes.fadeSlide<void>(
              AddExpenseScreen(initialAccountId: widget.accountId),
            ),
          );
        },
        icon: Icons.add_rounded,
        label: 'Add expense',
      ),
    );
  }
}

class _LoadedExpenseView extends StatelessWidget {
  const _LoadedExpenseView({
    required this.title,
    required this.accountId,
    required this.query,
    required this.searchController,
    required this.expenses,
    required this.onChanged,
    required this.onApplyQuery,
    required this.onRefresh,
    required this.onConfirmDelete,
    required this.onDelete,
  });

  final String title;
  final String? accountId;
  final String query;
  final TextEditingController searchController;
  final List<Map<String, dynamic>> expenses;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onApplyQuery;
  final Future<void> Function() onRefresh;
  final Future<bool?> Function(String label) onConfirmDelete;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories =
        expenses
            .map(_expenseCategory)
            .toSet()
            .where((name) => name.trim().isNotEmpty)
            .toList()
          ..sort();
    final command = _ExpenseCommand.parse(query, categories);
    final filtered = expenses.where(command.matches).toList()
      ..sort((a, b) {
        if (command.sortMode == _SortMode.highest) {
          return _expenseAmount(
            b['amount'],
          ).compareTo(_expenseAmount(a['amount']));
        }
        final bd = _expenseDate(b['date']) ?? DateTime(1970);
        final ad = _expenseDate(a['date']) ?? DateTime(1970);
        return bd.compareTo(ad);
      });
    final total = filtered.fold<double>(
      0,
      (sum, expense) => sum + _expenseAmount(expense['amount']),
    );
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      final category = _expenseCategory(expense);
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + _expenseAmount(expense['amount']);
    }
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MfSpace.xxl,
            MfSpace.lg,
            MfSpace.xxl,
            MfSpace.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use plain language like "coffee last month over 200" to filter your ledger.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.45,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: MfSpace.lg),
              AppCard(
                glass: true,
                padding: const EdgeInsets.fromLTRB(
                  MfSpace.lg,
                  MfSpace.md,
                  MfSpace.lg,
                  MfSpace.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(MfRadius.md),
                      ),
                      child: Icon(
                        Icons.mic_external_on_rounded,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: MfSpace.md),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onChanged,
                        style: GoogleFonts.inter(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText:
                              'Ask: "food this month", "over 1000", or "coffee yesterday"',
                          hintStyle: GoogleFonts.inter(
                            color: cs.onSurface.withValues(alpha: 0.42),
                          ),
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      IconButton(
                        onPressed: () => onApplyQuery(''),
                        icon: Icon(
                          Icons.close_rounded,
                          color: cs.onSurface.withValues(alpha: 0.52),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: MfSpace.md),
              Wrap(
                spacing: MfSpace.sm,
                runSpacing: MfSpace.sm,
                children: [
                  ActionChip(
                    label: const Text('Last 7 days'),
                    onPressed: () => onApplyQuery('last 7 days'),
                  ),
                  ActionChip(
                    label: const Text('This month'),
                    onPressed: () => onApplyQuery('this month'),
                  ),
                  ActionChip(
                    label: const Text('Over 1000'),
                    onPressed: () => onApplyQuery('over 1000'),
                  ),
                  ...topCategories
                      .take(3)
                      .map(
                        (entry) => ActionChip(
                          label: Text(entry.key),
                          onPressed: () => onApplyQuery(entry.key),
                        ),
                      ),
                ],
              ),
              if (command.chips.isNotEmpty) ...[
                const SizedBox(height: MfSpace.md),
                Wrap(
                  spacing: MfSpace.sm,
                  runSpacing: MfSpace.sm,
                  children: command.chips
                      .map((chip) => Chip(label: Text(chip)))
                      .toList(),
                ),
              ],
              const SizedBox(height: MfSpace.md),
              AppCard(
                glass: true,
                padding: const EdgeInsets.all(MfSpace.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                            style: GoogleFonts.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            command.summary,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.45,
                              color: cs.onSurface.withValues(alpha: 0.62),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MfSpace.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MfSpace.md,
                        vertical: MfSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _formatExpenseCurrency(total),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: cs.primary,
            onRefresh: onRefresh,
            child: filtered.isEmpty
                ? _EmptyExpenseResults(
                    hasAnyExpenses: expenses.isNotEmpty,
                    onAddExpense: () {
                      Navigator.of(context).push(
                        LedgerPageRoutes.fadeSlide<void>(
                          AddExpenseScreen(initialAccountId: accountId),
                        ),
                      );
                    },
                    onClearSearch: () => onApplyQuery(''),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      MfSpace.xxl,
                      0,
                      MfSpace.xxl,
                      120,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final expense = filtered[index];
                      final category = _expenseCategory(expense);
                      final amount = _formatExpenseCurrency(expense['amount']);
                      final id = expense['id']?.toString() ?? '';
                      final avatar = category.isNotEmpty
                          ? category.substring(0, 1).toUpperCase()
                          : '?';
                      final note = expense['note']?.toString().trim() ?? '';
                      final date = _expenseDate(expense['date']);
                      final subtitle = note.isNotEmpty
                          ? note
                          : date != null
                          ? DateFormat('EEE, d MMM yyyy').format(date)
                          : 'Logged transaction';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: MfSpace.md),
                        child: Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: MfSpace.xxl),
                            decoration: BoxDecoration(
                              color: MfPalette.expenseRed.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(MfRadius.lg),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: MfPalette.expenseRed,
                            ),
                          ),
                          confirmDismiss: (_) => onConfirmDelete(category),
                          onDismissed: (_) => onDelete(id),
                          child: TransactionTile(
                            title: category,
                            subtitle: subtitle,
                            amount: amount,
                            isExpense: true,
                            avatarColor: MfPalette.expenseRed,
                            avatarLabel: avatar,
                            animationIndex: index,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _EmptyExpenseResults extends StatelessWidget {
  const _EmptyExpenseResults({
    required this.hasAnyExpenses,
    required this.onAddExpense,
    required this.onClearSearch,
  });

  final bool hasAnyExpenses;
  final VoidCallback onAddExpense;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 0, MfSpace.xxl, 120),
      children: [
        LedgerEmptyState(
          title: hasAnyExpenses
              ? 'No matches for that command'
              : 'No expenses yet',
          subtitle: hasAnyExpenses
              ? 'Try broadening the phrase, removing an amount cap, or switching to a category chip.'
              : 'Record spending to unlock search, anomaly alerts, and richer reports.',
          icon: hasAnyExpenses
              ? Icons.search_off_rounded
              : Icons.receipt_long_outlined,
          actionLabel: hasAnyExpenses ? 'Clear search' : 'Add expense',
          onAction: hasAnyExpenses ? onClearSearch : onAddExpense,
        ),
      ],
    );
  }
}

class _LoadingExpenseView extends StatelessWidget {
  const _LoadingExpenseView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MfSpace.xxl,
        MfSpace.xxl,
        MfSpace.xxl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 220,
            height: 34,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(MfRadius.md),
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          AppCard(
            glass: true,
            child: SizedBox(
              height: 66,
              child: AppSkeleton(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(MfRadius.lg),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          const TransactionListSkeleton(count: 6),
        ],
      ),
    );
  }
}
