import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/premium_fab.dart';
import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../../core/widgets/premium_fintech_app_bar.dart';
import '../../../core/widgets/premium_fintech_backdrop.dart';
import '../../expenses/application/expense_providers.dart';
import '../application/budget_providers.dart';
import '../data/budgets_api.dart';

String _prettyMonthLabel(String monthKey) {
  final parts = monthKey.split('-');
  if (parts.length < 2) return monthKey;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (y == null || m == null) return monthKey;
  return DateFormat.yMMMM().format(DateTime(y, m));
}

double _parseMoney(dynamic raw) =>
    double.tryParse(raw?.toString() ?? '0') ?? 0;

class _MonthOverview {
  const _MonthOverview({
    required this.totalLimit,
    required this.totalSpent,
    required this.totalRemaining,
  });

  final double totalLimit;
  final double totalSpent;
  final double totalRemaining;
}

_MonthOverview _computeOverview(List<Map<String, dynamic>> rows) {
  var lim = 0.0;
  var sp = 0.0;
  for (final r in rows) {
    lim += _parseMoney(r['limit']);
    sp += _parseMoney(r['spent']);
  }
  return _MonthOverview(
    totalLimit: lim,
    totalSpent: sp,
    totalRemaining: lim - sp,
  );
}

Color _barGradientStart(double spent, double limit, bool exceeded) {
  if (exceeded || (limit > 0 && spent >= limit)) {
    return MfPalette.expenseRed;
  }
  final ratio = limit > 0 ? spent / limit : 0.0;
  if (ratio >= 0.9) return MfPalette.warningAmber;
  if (ratio >= 0.65) return const Color(0xFFF59E0B);
  return MfPalette.incomeGreen;
}

Color _barGradientEnd(Color start) {
  return start.withValues(alpha: 0.38);
}

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late String _monthKey;

  @override
  void initState() {
    super.initState();
    _monthKey = BudgetsApi.monthQueryParam();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ledgerSyncServiceProvider).pullBudgetsForMonth(_monthKey);
    });
  }

  void _shiftMonth(int delta) {
    final parts = _monthKey.split('-');
    var y = int.tryParse(parts[0]) ?? DateTime.now().year;
    var m =
        int.tryParse(parts.length > 1 ? parts[1] : '${DateTime.now().month}') ??
            DateTime.now().month;
    m += delta;
    while (m < 1) {
      m += 12;
      y -= 1;
    }
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    setState(() => _monthKey = '$y-$m');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ledgerSyncServiceProvider).pullBudgetsForMonth(_monthKey);
    });
  }

  Future<void> _pull() async {
    await ref.read(ledgerSyncServiceProvider).pullBudgetsForMonth(_monthKey);
  }

  Future<void> _openAdd() async {
    final cats = ref.read(categoriesProvider);
    await cats.when(
      data: (list) async {
        final expenseCats = list
            .where((c) => c['type']?.toString() == 'expense')
            .toList();
        if (expenseCats.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Create an expense category first.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        String? catId = expenseCats.first['id']?.toString();
        final limitCtrl = TextEditingController(text: '200');
        final saved = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: StatefulBuilder(
                builder: (context, setSt) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'New budget',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey(catId),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          initialValue: catId,
                          items: expenseCats
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c['id']?.toString(),
                                  child: Text(c['name']?.toString() ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setSt(() => catId = v),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: limitCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Monthly limit',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Month: ${_prettyMonthLabel(_monthKey)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        LedgerPrimaryGradientButton(
                          onPressed: () {
                            final lim =
                                double.tryParse(limitCtrl.text.trim()) ?? 0;
                            if (catId == null || lim <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Pick a category and enter a positive limit.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context, true);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
        if (saved != true || catId == null) return;
        final lim = double.tryParse(limitCtrl.text.trim());
        if (lim == null || lim <= 0) return;
        try {
          await ref.read(budgetsApiProvider).create(
                categoryId: catId!,
                limit: lim,
                month: _monthKey,
              );
          await _pull();
        } on DioException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(dioErrorMessage(e)),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      loading: () async {},
      error: (_, _) async {},
    );
  }

  Future<void> _openEdit(Map<String, dynamic> r) async {
    final id = r['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final name = r['categoryName']?.toString() ?? 'Category';
    final currentLimit = _parseMoney(r['limit']);
    final limitCtrl = TextEditingController(
      text: currentLimit == currentLimit.roundToDouble()
          ? currentLimit.toStringAsFixed(0)
          : currentLimit.toString(),
    );

    final action = await showModalBottomSheet<_BudgetSheetAction>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit budget',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: limitCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Monthly limit',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Month: ${_prettyMonthLabel(_monthKey)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                LedgerPrimaryGradientButton(
                  onPressed: () {
                    final lim = double.tryParse(limitCtrl.text.trim()) ?? 0;
                    if (lim <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a positive limit.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, _BudgetSheetAction.save(lim));
                  },
                  child: const Text('Save changes'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, _BudgetSheetAction.delete()),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    'Delete budget',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (action == null) return;

    if (action is _DeleteBudgetAction) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete budget?'),
          content: Text('Remove the budget for “$name” in ${_prettyMonthLabel(_monthKey)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      try {
        await ref.read(budgetsApiProvider).delete(id);
        await _pull();
      } on DioException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(dioErrorMessage(e)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
      return;
    }

    if (action is _SaveBudgetAction) {
      try {
        await ref.read(budgetsApiProvider).update(
              id: id,
              limit: action.limit,
            );
        await _pull();
      } on DioException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(dioErrorMessage(e)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(budgetsForMonthProvider(_monthKey));

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: PremiumFintechAppBar.bar(
        context: context,
        title: 'Budgets',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.only(bottom: MfSpace.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: MfPalette.textPrimary,
                  onPressed: () => _shiftMonth(-1),
                  tooltip: 'Previous month',
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: Text(
                    _prettyMonthLabel(_monthKey),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: MfPalette.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: MfPalette.textPrimary,
                  onPressed: () => _shiftMonth(1),
                  tooltip: 'Next month',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumFintechBackdrop(),
          RefreshIndicator(
            color: MfPalette.neonGreen,
            backgroundColor: cs.surfaceContainerHigh,
            onRefresh: _pull,
            child: async.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _BudgetEmptyBody(onAdd: _openAdd),
                      ),
                    ],
                  );
                }
                final overview = _computeOverview(rows);
                final overallPct = overview.totalLimit > 0
                    ? (overview.totalSpent / overview.totalLimit).clamp(0.0, 1.0)
                    : 0.0;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        MfSpace.xxl,
                        MfSpace.sm,
                        MfSpace.xxl,
                        MediaQuery.paddingOf(context).bottom + 100,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _MonthlyOverviewCard(
                            overview: overview,
                            overallProgress: overallPct,
                            exceeded: overview.totalSpent > overview.totalLimit &&
                                overview.totalLimit > 0,
                          ),
                          const SizedBox(height: MfSpace.xl),
                          Text(
                            'By category',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: cs.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: MfSpace.md),
                          ...rows.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: MfSpace.md),
                              child: _CategoryBudgetCard(
                                row: r,
                                onTap: () => _openEdit(r),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const _BudgetLoadingBody(),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(MfSpace.xxl),
                child: LedgerErrorState(
                  title: 'Could not load budgets',
                  message:
                      e is DioException ? dioErrorMessage(e) : e.toString(),
                  onRetry: _pull,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: MoneyFlowPremiumExtendedFab(
        heroTag: 'budget_add_fab',
        tooltip: 'Add budget',
        icon: Icons.add_rounded,
        label: 'Add budget',
        onPressed: _openAdd,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

sealed class _BudgetSheetAction {
  const _BudgetSheetAction();
  factory _BudgetSheetAction.save(double limit) = _SaveBudgetAction;
  factory _BudgetSheetAction.delete() = _DeleteBudgetAction;
}

class _SaveBudgetAction extends _BudgetSheetAction {
  const _SaveBudgetAction(this.limit);
  final double limit;
}

class _DeleteBudgetAction extends _BudgetSheetAction {
  const _DeleteBudgetAction();
}

class _MonthlyOverviewCard extends StatelessWidget {
  const _MonthlyOverviewCard({
    required this.overview,
    required this.overallProgress,
    required this.exceeded,
  });

  final _MonthOverview overview;
  final double overallProgress;
  final bool exceeded;

  @override
  Widget build(BuildContext context) {
    final start = _barGradientStart(
      overview.totalSpent,
      overview.totalLimit,
      exceeded,
    );
    final end = _barGradientEnd(start);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MfSpace.xl),
      decoration: heroCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY OVERVIEW',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: MfSpace.md),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: 'Budgeted',
                  value: MfCurrency.formatInr(overview.totalLimit),
                ),
              ),
              Expanded(
                child: _OverviewStat(
                  label: 'Spent',
                  value: MfCurrency.formatInr(overview.totalSpent),
                  emphasize: true,
                ),
              ),
              Expanded(
                child: _OverviewStat(
                  label: 'Left',
                  value: MfCurrency.formatInr(overview.totalRemaining),
                  negative: overview.totalRemaining < 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'Overall usage',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          _GradientProgressBar(
            value: overallProgress,
            startColor: start,
            endColor: end,
            trackColor: Colors.white.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.negative = false,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: Colors.white.withValues(alpha: 0.52),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
            fontSize: emphasize ? 17 : 14,
            color: negative
                ? MfPalette.expenseRed.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.98),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  const _GradientProgressBar({
    required this.value,
    required this.startColor,
    required this.endColor,
    required this.trackColor,
  });

  final double value;
  final Color startColor;
  final Color endColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      height: 8,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [startColor, endColor],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({
    required this.row,
    required this.onTap,
  });

  final Map<String, dynamic> row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = row['categoryName']?.toString() ?? '';
    final limit = _parseMoney(row['limit']);
    final spent = _parseMoney(row['spent']);
    final exceeded = row['exceeded'] == true;
    final pctRaw = _parseMoney(row['percentUsed']);
    final ratio = limit > 0 ? spent / limit : 0.0;
    final barValue = ratio.clamp(0.0, 1.0);
    final start = _barGradientStart(spent, limit, exceeded);
    final end = _barGradientEnd(start);

    return AppCard(
      glass: true,
      onTap: onTap,
      padding: const EdgeInsets.all(MfSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (exceeded)
                Container(
                  margin: const EdgeInsets.only(left: MfSpace.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: MfSpace.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: MfPalette.expenseRed.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: MfPalette.expenseRed.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'Over',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MfPalette.expenseRed,
                    ),
                  ),
                ),
              Icon(
                Icons.edit_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.md),
          _GradientProgressBar(
            value: barValue,
            startColor: start,
            endColor: end,
            trackColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          const SizedBox(height: MfSpace.md),
          Row(
            children: [
              Expanded(
                child: _MoneyLine(
                  label: 'Used',
                  amount: MfCurrency.formatInr(spent),
                  color: cs.onSurface.withValues(alpha: 0.88),
                ),
              ),
              Expanded(
                child: _MoneyLine(
                  label: 'Limit',
                  amount: MfCurrency.formatInr(limit),
                  color: cs.onSurface.withValues(alpha: 0.88),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.xs),
          Text(
            exceeded
                ? '${pctRaw.toStringAsFixed(0)}% of budget — over limit'
                : '${pctRaw.toStringAsFixed(0)}% used',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: exceeded
                  ? MfPalette.expenseRed
                  : cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    required this.label,
    required this.amount,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String amount;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _BudgetEmptyBody extends StatelessWidget {
  const _BudgetEmptyBody({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MfSpace.xxl,
        MfSpace.xxxl,
        MfSpace.xxl,
        MediaQuery.paddingOf(context).bottom + 100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LedgerBudgetEmptyIllustration(width: 200),
          const SizedBox(height: MfSpace.xl),
          Text(
            'No budgets set',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: MfSpace.md),
          Text(
            'Set a monthly cap per category. We will track spending and warn you before you go over.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: MfSpace.xl),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add budget'),
          ),
        ],
      ),
    );
  }
}

class _BudgetLoadingBody extends StatelessWidget {
  const _BudgetLoadingBody();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        MfSpace.xxl,
        MfSpace.md,
        MfSpace.xxl,
        MediaQuery.paddingOf(context).bottom + 88,
      ),
      children: [
        Container(
          height: 168,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(MfRadius.xl),
          ),
        ),
        const SizedBox(height: MfSpace.xl),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: MfSpace.md),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(MfRadius.lg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty budgets: target rings + bar hint.
class LedgerBudgetEmptyIllustration extends StatelessWidget {
  const LedgerBudgetEmptyIllustration({super.key, this.width = 168});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.58;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(painter: _BudgetEmptyPainter()),
    );
  }
}

class _BudgetEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w * 0.5, h * 0.48);
    final r0 = w * 0.28;
    for (var i = 0; i < 3; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8 - i * 0.6
        ..color = [
          MfPalette.accentSoftPurple.withValues(alpha: 0.55 - i * 0.12),
          MfPalette.neonGreen.withValues(alpha: 0.45 - i * 0.1),
          MfPalette.incomeGreen.withValues(alpha: 0.35 - i * 0.08),
        ][i];
      canvas.drawCircle(c, r0 - i * (w * 0.055), paint);
    }

    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.78, w * 0.64, h * 0.1),
      const Radius.circular(99),
    );
    canvas.drawRRect(
      bar,
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );
    final fill = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.78, w * 0.38, h * 0.1),
      const Radius.circular(99),
    );
    canvas.drawRRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [
            MfPalette.incomeGreen,
            MfPalette.incomeGreen.withValues(alpha: 0.4),
          ],
        ).createShader(fill.outerRect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
