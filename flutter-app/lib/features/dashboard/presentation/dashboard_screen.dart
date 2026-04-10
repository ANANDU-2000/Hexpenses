import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/theme/ledger_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../application/dashboard_providers.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../income/application/income_providers.dart';
import '../../income/presentation/add_income_screen.dart';
import 'dashboard_quick_access.dart';

/// Fintech accent colors (paired with theme).
const _incomeGreen = Color(0xFF0D9F6E);
const _expenseRose = Color(0xFFE11D48);
const _savingsViolet = Color(0xFF6D28D9);
const _heroGradientStart = Color(0xFF000B60);
const _heroGradientEnd = Color(0xFF1E3A5F);

Map<String, String> _categoryIdToName(WidgetRef ref) {
  final list = ref.watch(expensesProvider).value ?? const <Map<String, dynamic>>[];
  final m = <String, String>{};
  for (final e in list) {
    final c = e['category'];
    if (c is Map) {
      final id = c['id']?.toString();
      final n = c['name']?.toString();
      if (id != null && n != null && n.isNotEmpty) m[id] = n;
    }
  }
  return m;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static String _monthShort(String key) {
    final p = key.split('-');
    if (p.length < 2) return key;
    final mi = int.tryParse(p[1]) ?? 1;
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[(mi - 1).clamp(0, 11)];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.sizeOf(context);
    const maxContent = 720.0;
    final hPad = mq.width > maxContent + 32 ? (mq.width - maxContent) / 2 : 16.0;
    final overview = ref.watch(dashboardOverviewProvider);
    final breakdown = ref.watch(categoryBreakdownProvider);
    final expenses = ref.watch(expensesProvider);
    final incomes = ref.watch(incomesProvider);

    void refreshAll() {
      unawaited(ref.read(ledgerSyncServiceProvider).pullAndFlush());
      ref.invalidate(dashboardOverviewProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(categoryBreakdownProvider);
      ref.invalidate(incomesProvider);
    }

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () async {
        await ref.read(ledgerSyncServiceProvider).pullAndFlush();
        ref.invalidate(dashboardOverviewProvider);
        ref.invalidate(monthlySummaryProvider);
        ref.invalidate(categoryBreakdownProvider);
        ref.invalidate(incomesProvider);
        await ref.read(dashboardOverviewProvider.future);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(hPad, LedgerGap.sm, hPad, 88),
        children: [
          overview.when(
            data: (dash) {
              final nw = dash['netWorth'];
              final nwMap = nw is Map ? Map<String, dynamic>.from(nw) : <String, dynamic>{};
              final tmRaw = dash['thisMonth'];
              final tm = tmRaw is Map ? Map<String, dynamic>.from(tmRaw) : <String, dynamic>{};
              final trendRaw = dash['savingsTrend'];
              final trend = trendRaw is List
                  ? trendRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                  : <Map<String, dynamic>>[];
              return AnimatedSwitcher(
                duration: LedgerMotion.medium,
                switchInCurve: LedgerMotion.curve,
                switchOutCurve: LedgerMotion.curve,
                child: Column(
                  key: ValueKey('dash-${trend.length}-${nwMap['netWorth']}'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NetWorthHero(netWorth: nwMap),
                    const SizedBox(height: LedgerGap.lg),
                    _MetricCardsRow(thisMonth: tm),
                    const SizedBox(height: LedgerGap.lg),
                    const DashboardQuickAccess(),
                    const SizedBox(height: LedgerGap.xl),
                    _FintechSectionTitle(title: 'Income vs expenses', subtitle: 'Last ${trend.length} months'),
                    const SizedBox(height: LedgerGap.md),
                    _IncomeExpenseChart(
                      trend: trend,
                      monthLabel: _monthShort,
                      incomeColor: _incomeGreen,
                      expenseColor: _expenseRose,
                    ),
                    const SizedBox(height: LedgerGap.sm),
                    _ChartLegend(
                      items: [
                        _LegendItem(color: _incomeGreen, label: 'Income'),
                        _LegendItem(color: _expenseRose, label: 'Expenses'),
                      ],
                    ),
                    const SizedBox(height: LedgerGap.md),
                    _FintechSectionTitle(title: 'Savings trend', subtitle: 'Monthly net (income − expenses)'),
                    const SizedBox(height: LedgerGap.md),
                    _SavingsTrendChart(
                      trend: trend,
                      monthLabel: _monthShort,
                      lineColor: _savingsViolet,
                    ),
                  ],
                ),
              );
            },
            loading: () => const LedgerDashboardSkeleton(),
            error: (e, _) => LedgerErrorState(
              title: 'Couldn’t load dashboard',
              message: e.toString(),
              onRetry: refreshAll,
            ),
          ),
          const SizedBox(height: LedgerGap.sm),
          breakdown.when(
            data: (rows) {
              final catNames = _categoryIdToName(ref);
              if (rows.isEmpty) {
                return LedgerEmptyState(
                  title: 'No spending categories yet',
                  subtitle: 'Once you log expenses, you’ll see which categories drive your month.',
                  icon: Icons.pie_chart_outline_rounded,
                );
              }
              final sorted = [...rows]..sort((a, b) {
                  final da = double.tryParse(a['total']?.toString() ?? '0') ?? 0;
                  final db = double.tryParse(b['total']?.toString() ?? '0') ?? 0;
                  return db.compareTo(da);
                });
              final top = sorted.take(5).toList();
              final maxV = top
                  .map((e) => double.tryParse(e['total']?.toString() ?? '0') ?? 0)
                  .fold<double>(0, (a, b) => a > b ? a : b);
              return _FintechCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top spending',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: LedgerGap.sm),
                    Text(
                      'This month’s largest expense categories',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: LedgerGap.lg),
                    SizedBox(
                      height: 208,
                      child: BarChart(
                        BarChartData(
                          maxY: maxV > 0 ? maxV * 1.12 : 1,
                          barGroups: List.generate(
                            top.length,
                            (i) => BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: double.tryParse(top[i]['total']?.toString() ?? '0') ?? 0,
                                  width: 18,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      cs.primary.withValues(alpha: 0.2),
                                      cs.primary,
                                      cs.primaryContainer,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => cs.surfaceContainerHigh,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final i = group.x.toInt();
                                if (i < 0 || i >= top.length) return null;
                                final id = top[i]['categoryId']?.toString() ?? '';
                                final name = catNames[id] ?? id;
                                return BarTooltipItem(
                                  '$name\n${rod.toY.toStringAsFixed(0)}',
                                  GoogleFonts.inter(color: cs.onSurface, fontSize: 11),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= top.length) return const SizedBox();
                                  final id = top[i]['categoryId']?.toString() ?? '';
                                  final raw = catNames[id] ?? id;
                                  final short = raw.length > 8 ? '${raw.substring(0, 7)}…' : raw;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      short,
                                      style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.55)),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (v, _) => Text(
                                  v.toInt().toString(),
                                  style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.45)),
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxV > 0 ? maxV / 4 : 1,
                            getDrawingHorizontalLine: (v) => FlLine(
                              color: cs.outlineVariant.withValues(alpha: 0.12),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(vertical: LedgerGap.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FintechSectionTitle(title: 'Top spending', subtitle: 'Loading categories…'),
                  const SizedBox(height: LedgerGap.md),
                  const LedgerChartSkeleton(height: 208),
                ],
              ),
            ),
            error: (e, _) => LedgerErrorState(
              title: 'Couldn’t load chart',
              message: e.toString(),
              onRetry: refreshAll,
            ),
          ),
          const SizedBox(height: LedgerGap.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent expenses',
                style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AddIncomeScreen()));
                    },
                    child: Text('Income', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _incomeGreen)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()));
                    },
                    icon: Icon(Icons.add, size: 20, color: cs.primary),
                    label: Text('Expense', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: cs.primary)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: LedgerGap.sm),
          expenses.when(
            data: (list) {
              final recent = list.take(8).toList();
              if (recent.isEmpty) {
                return LedgerEmptyState(
                  title: 'No expenses this period',
                  subtitle: 'Add a transaction to see it here and feed your charts.',
                  icon: Icons.receipt_long_outlined,
                  actionLabel: 'Add expense',
                  onAction: () {
                    Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()));
                  },
                );
              }
              return Column(
                children: recent.map((e) {
                  final id = e['id']?.toString() ?? '';
                  final amt = e['amount']?.toString() ?? '0';
                  final cat = (e['category'] is Map) ? (e['category'] as Map)['name']?.toString() ?? '' : '';
                  final d = e['date']?.toString() ?? '';
                  final letter = cat.isNotEmpty ? cat.substring(0, 1).toUpperCase() : '?';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: LedgerGap.md),
                    child: _FintechCard(
                      padding: const EdgeInsets.symmetric(horizontal: LedgerGap.lg, vertical: 14),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'dashboard-exp-avatar-$id',
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      cs.primary.withValues(alpha: 0.85),
                                      cs.primaryContainer,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  letter,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: LedgerGap.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat.isEmpty ? 'Expense' : cat,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: LedgerGap.xs),
                                Text(
                                  d.length >= 10 ? d.substring(0, 10) : d,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Hero(
                            tag: 'dashboard-exp-amt-$id',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                amt,
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: LedgerGap.xxl),
              child: LedgerExpenseListSkeleton(count: 5),
            ),
            error: (e, _) => LedgerErrorState(
              title: 'Couldn’t load expenses',
              message: e.toString(),
              onRetry: refreshAll,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent income',
                style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AddIncomeScreen()));
                },
                child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _incomeGreen)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          incomes.when(
            data: (list) {
              final recent = list.take(6).toList();
              if (recent.isEmpty) {
                return LedgerEmptyState(
                  title: 'No income logged',
                  subtitle: 'Track salary or other inflows to see cash flow next to spending.',
                  icon: Icons.savings_outlined,
                  actionLabel: 'Add income',
                  onAction: () {
                    Navigator.of(context).push(LedgerPageRoutes.fadeSlide<void>(const AddIncomeScreen()));
                  },
                );
              }
              return Column(
                children: recent.map((e) {
                  final amt = e['amount']?.toString() ?? '0';
                  final src = e['source']?.toString() ?? '';
                  final d = e['date']?.toString() ?? '';
                  final label = src.isEmpty ? 'Income' : '${src[0].toUpperCase()}${src.substring(1)}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FintechCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(
                                  d.length >= 10 ? d.substring(0, 10) : d,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            amt,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _incomeGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: LedgerGap.lg),
              child: LedgerExpenseListSkeleton(count: 4),
            ),
            error: (e, _) => LedgerErrorState(
              title: 'Couldn’t load income',
              message: e.toString(),
              onRetry: refreshAll,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.label,
                    style: GoogleFonts.inter(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FintechSectionTitle extends StatelessWidget {
  const _FintechSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _FintechCard extends StatelessWidget {
  const _FintechCard({required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _NetWorthHero extends StatelessWidget {
  const _NetWorthHero({required this.netWorth});

  final Map<String, dynamic> netWorth;

  @override
  Widget build(BuildContext context) {
    final total = netWorth['netWorth']?.toString() ?? '—';
    final bank = netWorth['bankAndCash']?.toString() ?? '0';
    final inv = netWorth['investments']?.toString() ?? '0';
    final credit = netWorth['creditCardDebt']?.toString() ?? '0';
    final liab = netWorth['otherLiabilities']?.toString() ?? '0';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_heroGradientStart, _heroGradientEnd],
              ),
            ),
            child: SizedBox(height: 200, width: double.infinity),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net worth',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Hero(
                  tag: 'ledger-networth-hero',
                  child: Material(
                    color: Colors.transparent,
                    child: Text(
                      total,
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Accounts + investments − liabilities',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroChip(label: 'Bank & cash', value: bank),
                    _HeroChip(label: 'Investments', value: inv),
                    _HeroChip(label: 'Credit', value: credit),
                    _HeroChip(label: 'Loans', value: liab),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCardsRow extends StatelessWidget {
  const _MetricCardsRow({required this.thisMonth});

  final Map<String, dynamic> thisMonth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final income = thisMonth['totalIncome']?.toString() ?? '0';
    final expense = thisMonth['totalExpenses']?.toString() ?? '0';
    final savings = thisMonth['netSavings']?.toString() ?? thisMonth['netCashFlow']?.toString() ?? '0';

    Widget tile(String title, String value, Color accent) {
      return Expanded(
        child: _FintechCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            tile('Income', income, _incomeGreen),
            const SizedBox(width: 10),
            tile('Expenses', expense, _expenseRose),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            tile('Net savings', savings, cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: _FintechCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Month',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      thisMonth['month']?.toString() ?? '—',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({
    required this.trend,
    required this.monthLabel,
    required this.incomeColor,
    required this.expenseColor,
  });

  final List<Map<String, dynamic>> trend;
  final String Function(String) monthLabel;
  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (trend.isEmpty) {
      return _FintechCard(
        child: Text('Not enough history yet.', style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final incomes = trend.map((t) => double.tryParse(t['income']?.toString() ?? '0') ?? 0).toList();
    final expenses = trend.map((t) => double.tryParse(t['expenses']?.toString() ?? '0') ?? 0).toList();
    final maxY = [
      ...incomes,
      ...expenses,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxY > 0 ? maxY * 1.15 : 1.0;

    return _FintechCard(
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: top,
            groupsSpace: 8,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => cs.surfaceContainerHigh,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final i = group.x.toInt();
                  if (i < 0 || i >= trend.length) return null;
                  final label = rodIndex == 0 ? 'Income' : 'Expenses';
                  return BarTooltipItem(
                    '$label\n${rod.toY}',
                    GoogleFonts.inter(color: cs.onSurface, fontSize: 11),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= trend.length) return const SizedBox();
                    final m = trend[i]['month']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        monthLabel(m),
                        style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.55)),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Text(
                    v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString(),
                    style: GoogleFonts.inter(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: top / 4,
              getDrawingHorizontalLine: (v) => FlLine(
                color: cs.outlineVariant.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(trend.length, (i) {
              return BarChartGroupData(
                x: i,
                groupVertically: false,
                barRods: [
                  BarChartRodData(
                    toY: incomes[i],
                    width: 7,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        incomeColor.withValues(alpha: 0.35),
                        incomeColor,
                      ],
                    ),
                  ),
                  BarChartRodData(
                    toY: expenses[i],
                    width: 7,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        expenseColor.withValues(alpha: 0.35),
                        expenseColor,
                      ],
                    ),
                  ),
                ],
                barsSpace: 6,
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SavingsTrendChart extends StatelessWidget {
  const _SavingsTrendChart({
    required this.trend,
    required this.monthLabel,
    required this.lineColor,
  });

  final List<Map<String, dynamic>> trend;
  final String Function(String) monthLabel;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (trend.isEmpty) {
      return _FintechCard(
        child: Text('Not enough history yet.', style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    final nets = trend.map((t) => double.tryParse(t['netSavings']?.toString() ?? '0') ?? 0).toList();
    var minY = nets.reduce((a, b) => a < b ? a : b);
    var maxY = nets.reduce((a, b) => a > b ? a : b);
    final span = (maxY - minY).abs();
    final pad = span > 1e-6 ? span * 0.15 : 1.0;
    minY -= pad;
    maxY += pad;

    return _FintechCard(
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: cs.outlineVariant.withValues(alpha: 0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= trend.length) return const SizedBox();
                    final m = trend[i]['month']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        monthLabel(m),
                        style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.55)),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, _) => Text(
                    v.abs() >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.toInt().toString(),
                    style: GoogleFonts.inter(fontSize: 9, color: cs.onSurface.withValues(alpha: 0.45)),
                  ),
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  trend.length,
                  (i) => FlSpot(i.toDouble(), nets[i]),
                ),
                isCurved: true,
                curveSmoothness: 0.35,
                color: lineColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                    radius: 3.5,
                    color: lineColor,
                    strokeWidth: 2,
                    strokeColor: cs.surfaceContainerLowest,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      lineColor.withValues(alpha: 0.25),
                      lineColor.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => cs.surfaceContainerHigh,
                getTooltipItems: (touchedSpots) => touchedSpots
                    .map(
                      (s) => LineTooltipItem(
                        s.y.toStringAsFixed(0),
                        GoogleFonts.inter(color: cs.onSurface, fontSize: 11),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
