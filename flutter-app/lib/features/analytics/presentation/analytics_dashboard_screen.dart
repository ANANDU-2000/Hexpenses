import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../expenses/application/expense_providers.dart'
    show categoriesProvider, expensesProvider;
import '../../income/application/income_providers.dart';
import '../application/analytics_providers.dart';
import 'drilldown_analytics_screen.dart';

/// Dark analytics view: weekly bars, expense/income toggle, category cards.
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  bool _incomeMode = false;

  static const _bg = Color(0xFF0D0D0D);
  static const _card = Color(0xFF161616);
  static const _border = Color(0x1AFFFFFF);

  Future<void> _refresh() async {
    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
    ref.invalidate(expensesProvider);
    ref.invalidate(incomesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final weekly = ref.watch(weeklyAnalyticsProvider);
    final breakdown = ref.watch(analyticsCategoryMonthProvider);
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          'Analytics',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Drill-down explorer',
            icon: const Icon(Icons.hub_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DrilldownAnalyticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: MfPalette.neonGreen,
        backgroundColor: _card,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            MfSpace.xxl,
            MfSpace.sm,
            MfSpace.xxl,
            MfSpace.xxxl,
          ),
          children: [
            Text(
              'This week',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: MfSpace.md),
            _ModeToggle(
              incomeMode: _incomeMode,
              onExpense: () => setState(() => _incomeMode = false),
              onIncome: () => setState(() => _incomeMode = true),
            ),
            const SizedBox(height: MfSpace.lg),
            weekly.when(
              data: (snap) => _WeeklyChartCard(
                snapshot: snap,
                incomeMode: _incomeMode,
              ),
              loading: () => const _AnalyticsLoadingBlock(height: 260),
              error: (e, _) => LedgerErrorState(
                title: 'Could not load activity',
                message: e is Exception ? e.toString() : '$e',
                onRetry: _refresh,
              ),
            ),
            const SizedBox(height: MfSpace.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'By category',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'This month',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MfSpace.lg),
            breakdown.when(
              data: (rows) => categories.when(
                data: (cats) => _CategorySection(
                  breakdown: rows,
                  categories: cats,
                ),
                loading: () => const _AnalyticsLoadingBlock(height: 120),
                error: (e, _) => Text(
                  e is DioException ? dioErrorMessage(e) : '$e',
                  style: GoogleFonts.inter(color: MfPalette.expenseRed),
                ),
              ),
              loading: () => const _AnalyticsLoadingBlock(height: 200),
              error: (e, _) => LedgerErrorState(
                title: 'Could not load categories',
                message:
                    e is DioException ? dioErrorMessage(e) : e.toString(),
                onRetry: _refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.incomeMode,
    required this.onExpense,
    required this.onIncome,
  });

  final bool incomeMode;
  final VoidCallback onExpense;
  final VoidCallback onIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _AnalyticsDashboardScreenState._card,
        borderRadius: BorderRadius.circular(MfRadius.xl),
        border: Border.all(color: _AnalyticsDashboardScreenState._border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TogglePill(
              label: 'Expense',
              selected: !incomeMode,
              accent: MfPalette.expenseRed,
              onTap: onExpense,
            ),
          ),
          Expanded(
            child: _TogglePill(
              label: 'Income',
              selected: incomeMode,
              accent: MfPalette.incomeGreen,
              onTap: onIncome,
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        child: AnimatedContainer(
          duration: MfMotion.fast,
          curve: MfMotion.curve,
          padding: const EdgeInsets.symmetric(vertical: MfSpace.md),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(MfRadius.lg),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? accent : Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({
    required this.snapshot,
    required this.incomeMode,
  });

  final WeeklyAnalyticsSnapshot snapshot;
  final bool incomeMode;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final values =
        incomeMode ? snapshot.incomeByDay : snapshot.expenseByDay;
    final maxY = values.fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxY > 0 ? maxY * 1.18 : 1.0;
    final rodColor = incomeMode ? MfPalette.incomeGreen : MfPalette.expenseRed;

    return Container(
      decoration: BoxDecoration(
        color: _AnalyticsDashboardScreenState._card,
        borderRadius: BorderRadius.circular(MfRadius.xl),
        border: Border.all(color: _AnalyticsDashboardScreenState._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: rodColor.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        MfSpace.md,
        MfSpace.lg,
        MfSpace.lg,
        MfSpace.lg,
      ),
      child: SizedBox(
        height: 240,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: top,
            groupsSpace: 10,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF242428),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final i = group.x.toInt();
                  if (i < 0 || i >= 7) return null;
                  return BarTooltipItem(
                    '${_labels[i]}\n${MfCurrency.formatInr(rod.toY)}',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= 7) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _labels[i],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: top <= 1 ? 1 : top / 4,
                  getTitlesWidget: (v, _) {
                    if (v > top * 1.01) return const SizedBox();
                    final n = v;
                    final t = n >= 100000
                        ? '${(n / 100000).toStringAsFixed(n >= 1000000 ? 0 : 1)}L'
                        : n >= 1000
                            ? '${(n / 1000).toStringAsFixed(0)}k'
                            : n.toInt().toString();
                    return Text(
                      t,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: top <= 1 ? 0.5 : top / 4,
              getDrawingHorizontalLine: (v) => FlLine(
                color: Colors.white.withValues(alpha: 0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        rodColor.withValues(alpha: 0.35),
                        rodColor,
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.breakdown,
    required this.categories,
  });

  final List<Map<String, dynamic>> breakdown;
  final List<Map<String, dynamic>> categories;

  String _nameForId(String id) {
    for (final c in categories) {
      if (c['id']?.toString() == id) {
        return c['name']?.toString() ?? id;
      }
    }
    if (id == 'unknown') return 'Uncategorised';
    return id;
  }

  static const _palette = [
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFFA855F7),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(MfSpace.xxl),
        decoration: BoxDecoration(
          color: _AnalyticsDashboardScreenState._card,
          borderRadius: BorderRadius.circular(MfRadius.lg),
          border: Border.all(color: _AnalyticsDashboardScreenState._border),
        ),
        child: Center(
          child: Text(
            'No category data yet. Add expenses to see breakdown.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.5),
              height: 1.4,
            ),
          ),
        ),
      );
    }

    final sorted = [...breakdown]..sort((a, b) {
        final da = double.tryParse(a['total']?.toString() ?? '0') ?? 0;
        final db = double.tryParse(b['total']?.toString() ?? '0') ?? 0;
        return db.compareTo(da);
      });

    final top = sorted.take(8).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - MfSpace.md) / 2;
        return Wrap(
          spacing: MfSpace.md,
          runSpacing: MfSpace.md,
          children: List.generate(top.length, (i) {
            final row = top[i];
            final id = row['categoryId']?.toString() ?? 'unknown';
            final label = _nameForId(id);
            final amount = MfCurrency.formatInr(row['total']);
            final dot = _palette[i % _palette.length];
            return SizedBox(
              width: w.clamp(140.0, double.infinity),
              child: _CategorySummaryCard(
                label: label,
                amount: amount,
                accent: dot,
              ),
            );
          }),
        );
      },
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  const _CategorySummaryCard({
    required this.label,
    required this.amount,
    required this.accent,
  });

  final String label;
  final String amount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MfSpace.lg),
      decoration: BoxDecoration(
        color: _AnalyticsDashboardScreenState._card,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        border: Border.all(color: _AnalyticsDashboardScreenState._border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MfSpace.sm),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.md),
          Text(
            amount,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder block while analytics data loads.
class _AnalyticsLoadingBlock extends StatelessWidget {
  const _AnalyticsLoadingBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _AnalyticsDashboardScreenState._card,
        borderRadius: BorderRadius.circular(MfRadius.xl),
        border: Border.all(color: _AnalyticsDashboardScreenState._border),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: MfPalette.neonGreen.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
