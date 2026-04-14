import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

enum _QuickRange { none, lastMonth, last90, custom }

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedMonthKey;
  int? _highlightedPieIndex;
  _QuickRange _quickRange = _QuickRange.none;
  DateTime? _customStart;
  DateTime? _customEnd;

  Future<void> _refresh() async {
    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customStart != null && _customEnd != null
        ? DateTimeRange(start: _customStart!, end: _customEnd!)
        : DateTimeRange(
            start: now.subtract(const Duration(days: 29)),
            end: now,
          );
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF49D6FF),
              surface: Color(0xFF121722),
              onSurface: Color(0xFFF4F7FF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (range == null || !mounted) return;
    setState(() {
      _quickRange = _QuickRange.custom;
      _customStart = range.start;
      _customEnd = range.end;
      _highlightedPieIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: _AnalyticsColors.background,
      body: Stack(
        children: [
          const _AnalyticsBackdrop(),
          SafeArea(
            bottom: false,
            child: expensesAsync.when(
              data: (expenses) {
                final entries = expenses.map(_ExpenseEntry.fromMap).toList()
                  ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

                final monthKeys =
                    entries.map((entry) => entry.monthKey).toSet().toList()
                      ..sort((a, b) => b.compareTo(a));

                if (monthKeys.isEmpty) {
                  monthKeys.add(_monthKey(DateTime.now()));
                }

                final selectedMonthKey = monthKeys.contains(_selectedMonthKey)
                    ? _selectedMonthKey!
                    : monthKeys.first;
                final monthLabel = _formatMonthLabel(selectedMonthKey);
                final ym = _buildExpenseQuery(
                  selectedMonthKey: selectedMonthKey,
                  quick: _quickRange,
                  customStart: _customStart,
                  customEnd: _customEnd,
                );
                final loadingPeriodSubtitle = _periodSubtitleBeforeLoad(
                  selectedMonthKey: selectedMonthKey,
                  quick: _quickRange,
                  customStart: _customStart,
                  customEnd: _customEnd,
                );
                final mvpAsync = ref.watch(expenseMvpProvider(ym));

                return mvpAsync.when(
                  data: (mvp) {
                    final periodLabel = () {
                      final p = mvp['period']?.toString().trim();
                      if (p != null && p.isNotEmpty) return p;
                      return monthLabel;
                    }();
                    final selectedEntries = entries
                        .where((e) => _entryMatchesQuery(e, ym))
                        .toList()
                      ..sort((a, b) => b.sortDate.compareTo(a.sortDate));

                    final pie = mvp['chart'] is Map
                        ? Map<String, dynamic>.from(mvp['chart']['pie'] as Map)
                        : <String, dynamic>{};
                    final pieLabels = (pie['labels'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        <String>[];
                    final pieValues = (pie['values'] as List<dynamic>?)
                            ?.map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
                            .toList() ??
                        <double>[];
                    final monthTotal = double.tryParse(
                          mvp['thisMonthExpenses']?.toString() ?? '0',
                        ) ??
                        0;
                    final allTime = mvp['totalSpentAllTime']?.toString() ?? '0';

                    final bar = mvp['chart'] is Map &&
                            (mvp['chart'] as Map)['monthlyExpenses'] is Map
                        ? Map<String, dynamic>.from(
                            (mvp['chart'] as Map)['monthlyExpenses'] as Map,
                          )
                        : <String, dynamic>{};
                    final barLabels = (bar['labels'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        <String>[];
                    final barValues = (bar['values'] as List<dynamic>?)
                            ?.map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
                            .toList() ??
                        <double>[];

                    final breakdownRaw = mvp['categoryBreakdownMonth'];
                    final breakdown = breakdownRaw is List
                        ? breakdownRaw
                            .map((e) => Map<String, dynamic>.from(e as Map))
                            .toList()
                        : <Map<String, dynamic>>[];

                    final vehicle = mvp['vehicle'] is Map
                        ? Map<String, dynamic>.from(mvp['vehicle'] as Map)
                        : <String, dynamic>{};

                    return RefreshIndicator(
                      color: const Color(0xFF49D6FF),
                      backgroundColor: const Color(0xFF121722),
                      onRefresh: () async {
                        await _refresh();
                        ref.invalidate(expenseMvpProvider(ym));
                      },
                      child: ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          MfSpace.xl,
                          MfSpace.md,
                          MfSpace.xl,
                          132,
                        ),
                        children: [
                          _AnalyticsHeader(
                            canPop: canPop,
                            monthKeys: monthKeys,
                            selectedMonthKey: selectedMonthKey,
                            periodSubtitle: periodLabel,
                            quickRange: _quickRange,
                            onBack: () => Navigator.of(context).maybePop(),
                            onMonthChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedMonthKey = value;
                                _quickRange = _QuickRange.none;
                                _highlightedPieIndex = null;
                              });
                            },
                            onThisMonth: () {
                              setState(() {
                                _selectedMonthKey = _monthKey(DateTime.now());
                                _quickRange = _QuickRange.none;
                                _highlightedPieIndex = null;
                              });
                            },
                            onLastMonth: () {
                              setState(() {
                                _quickRange = _QuickRange.lastMonth;
                                _highlightedPieIndex = null;
                              });
                            },
                            onLast90: () {
                              setState(() {
                                _quickRange = _QuickRange.last90;
                                _highlightedPieIndex = null;
                              });
                            },
                            onCustomRange: () {
                              _pickCustomRange();
                            },
                          ),
                          const SizedBox(height: MfSpace.lg),
                          _MvpSummaryStrip(
                            periodLabel: periodLabel,
                            monthTotal: monthTotal,
                            allTime: allTime,
                          ),
                          const SizedBox(height: MfSpace.xl),
                          _MvpCategoryPieCard(
                            monthLabel: periodLabel,
                            labels: pieLabels,
                            values: pieValues,
                            monthTotal: monthTotal,
                            highlightedIndex: _highlightedPieIndex,
                            onSliceTap: (i) {
                              setState(() {
                                _highlightedPieIndex = i;
                              });
                            },
                          ),
                          const SizedBox(height: MfSpace.xl),
                          _MvpMonthlyExpenseBarCard(
                            barLabels: barLabels,
                            barValues: barValues,
                          ),
                          const SizedBox(height: MfSpace.xl),
                          _VehicleCostCard(vehicle: vehicle),
                          const SizedBox(height: MfSpace.xl),
                          if (breakdown.isEmpty)
                            _EmptyAnalyticsCard(
                              monthLabel: periodLabel,
                              onAddExpense: () {
                                Navigator.of(context).push(
                                  LedgerPageRoutes.fadeSlide<void>(
                                    const AddExpenseScreen(),
                                  ),
                                );
                              },
                            )
                          else ...[
                            Text(
                              'Categories',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: MfSpace.md),
                            ...breakdown.asMap().entries.map(
                              (e) {
                                final i = e.key;
                                final row = e.value;
                                final catTotal =
                                    double.tryParse(row['total']?.toString() ?? '0') ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: MfSpace.sm),
                                  child: _MvpCategoryRow(
                                    name: row['name']?.toString() ?? '',
                                    total: row['total']?.toString() ?? '0',
                                    periodTotal: monthTotal,
                                    categoryAmount: catTotal,
                                    color: _mvpPiePalette[i % _mvpPiePalette.length],
                                  ),
                                );
                              },
                            ),
                          ],
                          if (selectedEntries.isNotEmpty) ...[
                            const SizedBox(height: MfSpace.xl),
                            Text(
                              'Recent in period',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: MfSpace.md),
                            ...selectedEntries.take(6).map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: MfSpace.sm,
                                    ),
                                    child: _MvpRecentRow(entry: e),
                                  ),
                                ),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      MfSpace.xl,
                      MfSpace.md,
                      MfSpace.xl,
                      132,
                    ),
                    children: [
                      _AnalyticsHeader(
                        canPop: canPop,
                        monthKeys: monthKeys,
                        selectedMonthKey: selectedMonthKey,
                        periodSubtitle: loadingPeriodSubtitle,
                        quickRange: _quickRange,
                        onBack: () => Navigator.of(context).maybePop(),
                        onMonthChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedMonthKey = value;
                            _quickRange = _QuickRange.none;
                          });
                        },
                        onThisMonth: () {
                          setState(() {
                            _selectedMonthKey = _monthKey(DateTime.now());
                            _quickRange = _QuickRange.none;
                          });
                        },
                        onLastMonth: () {
                          setState(() => _quickRange = _QuickRange.lastMonth);
                        },
                        onLast90: () {
                          setState(() => _quickRange = _QuickRange.last90);
                        },
                        onCustomRange: () {
                          _pickCustomRange();
                        },
                      ),
                      const SizedBox(height: MfSpace.xl),
                      const _LoadingChartCard(),
                    ],
                  ),
                  error: (e, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      MfSpace.xl,
                      MfSpace.md,
                      MfSpace.xl,
                      132,
                    ),
                    children: [
                      _AnalyticsHeader(
                        canPop: canPop,
                        monthKeys: monthKeys,
                        selectedMonthKey: selectedMonthKey,
                        periodSubtitle: loadingPeriodSubtitle,
                        quickRange: _quickRange,
                        onBack: () => Navigator.of(context).maybePop(),
                        onMonthChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedMonthKey = value;
                            _quickRange = _QuickRange.none;
                          });
                        },
                        onThisMonth: () {
                          setState(() {
                            _selectedMonthKey = _monthKey(DateTime.now());
                            _quickRange = _QuickRange.none;
                          });
                        },
                        onLastMonth: () {
                          setState(() => _quickRange = _QuickRange.lastMonth);
                        },
                        onLast90: () {
                          setState(() => _quickRange = _QuickRange.last90);
                        },
                        onCustomRange: () {
                          _pickCustomRange();
                        },
                      ),
                      const SizedBox(height: MfSpace.xl),
                      _ErrorAnalyticsCard(message: e.toString()),
                    ],
                  ),
                );
              },
              loading: () => _AnalyticsScaffoldState(
                canPop: canPop,
                quickRange: _quickRange,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    MfSpace.xl,
                    MfSpace.md,
                    MfSpace.xl,
                    132,
                  ),
                  children: const [
                    _LoadingHeader(),
                    SizedBox(height: MfSpace.xl),
                    _LoadingChartCard(),
                    SizedBox(height: MfSpace.xl),
                    _LoadingTransactions(),
                  ],
                ),
              ),
              error: (error, _) => RefreshIndicator(
                color: const Color(0xFF49D6FF),
                backgroundColor: const Color(0xFF121722),
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    MfSpace.xl,
                    MfSpace.md,
                    MfSpace.xl,
                    132,
                  ),
                  children: [
                    _AnalyticsHeader(
                      canPop: canPop,
                      monthKeys: const [],
                      selectedMonthKey: null,
                      periodSubtitle: 'Connect to load analytics',
                      quickRange: _quickRange,
                      onBack: () => Navigator.of(context).maybePop(),
                      onMonthChanged: (_) {},
                      onThisMonth: () {},
                      onLastMonth: () {},
                      onLast90: () {},
                      onCustomRange: () {},
                    ),
                    const SizedBox(height: MfSpace.xl),
                    _ErrorAnalyticsCard(message: error.toString()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _ymd(DateTime d) {
  final l = d.toLocal();
  final y = l.year.toString().padLeft(4, '0');
  final m = l.month.toString().padLeft(2, '0');
  final day = l.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

ExpenseMvpQuery _queryPickMonth(String key) {
  final p = key.split('-');
  if (p.length < 2) {
    final n = DateTime.now();
    return (year: n.year, month: n.month, fromYmd: null, toYmd: null);
  }
  return (
    year: int.parse(p[0]),
    month: int.parse(p[1]),
    fromYmd: null,
    toYmd: null,
  );
}

ExpenseMvpQuery _buildExpenseQuery({
  required String selectedMonthKey,
  required _QuickRange quick,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final now = DateTime.now();
  switch (quick) {
    case _QuickRange.none:
      return _queryPickMonth(selectedMonthKey);
    case _QuickRange.lastMonth:
      final firstThisMonth = DateTime(now.year, now.month, 1);
      final lastDayPrev = firstThisMonth.subtract(const Duration(days: 1));
      final start = DateTime(lastDayPrev.year, lastDayPrev.month, 1);
      return (
        year: lastDayPrev.year,
        month: lastDayPrev.month,
        fromYmd: _ymd(start),
        toYmd: _ymd(lastDayPrev),
      );
    case _QuickRange.last90:
      final end = DateTime(now.year, now.month, now.day);
      final start = end.subtract(const Duration(days: 89));
      return (
        year: end.year,
        month: end.month,
        fromYmd: _ymd(start),
        toYmd: _ymd(end),
      );
    case _QuickRange.custom:
      if (customStart == null || customEnd == null) {
        return _queryPickMonth(selectedMonthKey);
      }
      var a = DateTime(
        customStart.year,
        customStart.month,
        customStart.day,
      );
      var b = DateTime(customEnd.year, customEnd.month, customEnd.day);
      if (a.isAfter(b)) {
        final t = a;
        a = b;
        b = t;
      }
      return (
        year: b.year,
        month: b.month,
        fromYmd: _ymd(a),
        toYmd: _ymd(b),
      );
  }
}

bool _entryMatchesQuery(_ExpenseEntry entry, ExpenseMvpQuery q) {
  final d = entry.date;
  if (d == null) return false;
  final dl = DateTime(d.year, d.month, d.day);
  if (q.fromYmd != null && q.toYmd != null) {
    final fs = DateTime.tryParse('${q.fromYmd}T00:00:00');
    final te = DateTime.tryParse('${q.toYmd}T00:00:00');
    if (fs != null && te != null) {
      final endExcl = te.add(const Duration(days: 1));
      return !dl.isBefore(fs) && dl.isBefore(endExcl);
    }
  }
  return dl.year == q.year && dl.month == q.month;
}

String _periodSubtitleBeforeLoad({
  required String selectedMonthKey,
  required _QuickRange quick,
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final q = _buildExpenseQuery(
    selectedMonthKey: selectedMonthKey,
    quick: quick,
    customStart: customStart,
    customEnd: customEnd,
  );
  if (q.fromYmd != null && q.toYmd != null) {
    return '${q.fromYmd} → ${q.toYmd}';
  }
  return _formatMonthLabel(selectedMonthKey);
}

const _mvpPiePalette = <Color>[
  Color(0xFFFFB26B),
  Color(0xFF67E7FF),
  Color(0xFFFF8FD8),
  Color(0xFF63FFCB),
  Color(0xFFFFE36D),
  Color(0xFFADB7FF),
  Color(0xFFFF8A65),
  Color(0xFF81C784),
];

class _MvpSummaryStrip extends StatelessWidget {
  const _MvpSummaryStrip({
    required this.periodLabel,
    required this.monthTotal,
    required this.allTime,
  });

  final String periodLabel;
  final double monthTotal;
  final String allTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnalyticsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period total',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AnalyticsColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(monthTotal),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _AnalyticsColors.text,
                  ),
                ),
                Text(
                  periodLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: MfSpace.md),
        Expanded(
          child: _AnalyticsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All-time spent',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _AnalyticsColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(
                    double.tryParse(allTime) ?? 0,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _AnalyticsColors.text,
                  ),
                ),
                Text(
                  'Workspace expenses',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MvpCategoryPieCard extends StatelessWidget {
  const _MvpCategoryPieCard({
    required this.monthLabel,
    required this.labels,
    required this.values,
    required this.monthTotal,
    required this.highlightedIndex,
    required this.onSliceTap,
  });

  final String monthLabel;
  final List<String> labels;
  final List<double> values;
  final double monthTotal;
  final int? highlightedIndex;
  final ValueChanged<int?> onSliceTap;

  @override
  Widget build(BuildContext context) {
    final nonZero = <int>[];
    for (var i = 0; i < values.length; i++) {
      if (values[i] > 0) nonZero.add(i);
    }
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category split',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            monthLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _AnalyticsColors.muted,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  duration: MfMotion.medium,
                  curve: MfMotion.curve,
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 3,
                    centerSpaceRadius: 78,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        final touched = response?.touchedSection;
                        if (!event.isInterestedForInteractions ||
                            touched == null ||
                            touched.touchedSectionIndex < 0) {
                          onSliceTap(null);
                          return;
                        }
                        final idx = nonZero[touched.touchedSectionIndex];
                        onSliceTap(idx);
                      },
                    ),
                    sections: nonZero.isEmpty
                        ? [
                            PieChartSectionData(
                              value: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                              radius: 70,
                              showTitle: false,
                            ),
                          ]
                        : List.generate(nonZero.length, (j) {
                            final i = nonZero[j];
                            final v = values[i];
                            final share = monthTotal <= 0
                                ? 0.0
                                : (v / monthTotal) * 100;
                            final selected = highlightedIndex == i;
                            return PieChartSectionData(
                              value: v,
                              color: _mvpPiePalette[i % _mvpPiePalette.length],
                              radius: selected ? 84 : 72,
                              title: share >= 8 ? '${share.round()}%' : '',
                              titleStyle: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              borderSide: const BorderSide(
                                color: Color(0xFF0A0D13),
                                width: 2,
                              ),
                            );
                          }),
                  ),
                ),
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.68),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(monthTotal),
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _AnalyticsColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MfSpace.md),
          Wrap(
            spacing: MfSpace.sm,
            runSpacing: MfSpace.sm,
            children: List.generate(labels.length, (i) {
              if (values.length <= i || values[i] <= 0) {
                return const SizedBox.shrink();
              }
              final active = highlightedIndex == i;
              return Chip(
                label: Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _AnalyticsColors.text,
                  ),
                ),
                backgroundColor: _mvpPiePalette[i % _mvpPiePalette.length]
                    .withValues(alpha: active ? 0.35 : 0.18),
                side: BorderSide(
                  color: active
                      ? _mvpPiePalette[i % _mvpPiePalette.length]
                      : _AnalyticsColors.border,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _MvpMonthlyExpenseBarCard extends StatelessWidget {
  const _MvpMonthlyExpenseBarCard({
    required this.barLabels,
    required this.barValues,
  });

  final List<String> barLabels;
  final List<double> barValues;

  @override
  Widget build(BuildContext context) {
    final maxV = barValues.isEmpty
        ? 1.0
        : barValues.reduce((a, b) => a > b ? a : b);
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly expense trend',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.md),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxV > 0 ? maxV * 1.15 : 1,
                barGroups: List.generate(
                  barLabels.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: i < barValues.length ? barValues[i] : 0,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF2F7BFF),
                            Color(0xFF67E7FF),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= barLabels.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            barLabels[i],
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
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
                  horizontalInterval: maxV > 0 ? maxV / 4 : 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
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
  }
}

class _VehicleCostCard extends StatelessWidget {
  const _VehicleCostCard({required this.vehicle});

  final Map<String, dynamic> vehicle;

  @override
  Widget build(BuildContext context) {
    final has = vehicle['hasVehicles'] == true;
    final total = vehicle['vehicleExpenseTotalAllTime']?.toString() ?? '0';
    final hint = vehicle['emptyHint']?.toString();
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle costs',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          if (!has)
            Text(
              hint ?? 'No vehicles yet — add one under Profile.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _AnalyticsColors.muted,
                height: 1.4,
              ),
            )
          else
            Text(
              'Logged vehicle expenses (all time): ${_formatCurrency(double.tryParse(total) ?? 0)}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _AnalyticsColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

class _MvpCategoryRow extends StatelessWidget {
  const _MvpCategoryRow({
    required this.name,
    required this.total,
    required this.periodTotal,
    required this.categoryAmount,
    required this.color,
  });

  final String name;
  final String total;
  final double periodTotal;
  final double categoryAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final share = periodTotal > 0 ? (categoryAmount / periodTotal) * 100 : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MfSpace.lg, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AnalyticsColors.border),
      ),
      child: Row(
        children: [
          _CategoryShareDonut(
            amount: categoryAmount,
            periodTotal: periodTotal,
            color: color,
          ),
          const SizedBox(width: MfSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _AnalyticsColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${share.clamp(0, 100).toStringAsFixed(share >= 10 ? 0 : 1)}% of period',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _AnalyticsColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(double.tryParse(total) ?? 0),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF49D6FF),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryShareDonut extends StatelessWidget {
  const _CategoryShareDonut({
    required this.amount,
    required this.periodTotal,
    required this.color,
  });

  final double amount;
  final double periodTotal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    if (periodTotal <= 0 || amount <= 0) {
      return SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: const Center(
            child: Icon(
              Icons.pie_chart_outline_rounded,
              size: 22,
              color: _AnalyticsColors.muted,
            ),
          ),
        ),
      );
    }
    final rest = periodTotal - amount;
    final sections = rest <= 0.0001
        ? <PieChartSectionData>[
            PieChartSectionData(
              value: amount,
              color: color,
              radius: 11,
              showTitle: false,
            ),
          ]
        : <PieChartSectionData>[
            PieChartSectionData(
              value: amount,
              color: color,
              radius: 11,
              showTitle: false,
            ),
            PieChartSectionData(
              value: rest,
              color: Colors.white.withValues(alpha: 0.1),
              radius: 11,
              showTitle: false,
            ),
          ];
    return SizedBox(
      width: size,
      height: size,
      child: PieChart(
        PieChartData(
          startDegreeOffset: -90,
          sectionsSpace: 0,
          centerSpaceRadius: 14,
          sections: sections,
        ),
      ),
    );
  }
}

class _MvpRecentRow extends StatelessWidget {
  const _MvpRecentRow({required this.entry});

  final _ExpenseEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MfSpace.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AnalyticsColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _AnalyticsColors.text,
                  ),
                ),
                Text(
                  entry.rawCategory,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _AnalyticsColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatExpenseCurrency(entry.amount),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFF8FD8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseEntry {
  const _ExpenseEntry({
    required this.amount,
    required this.title,
    required this.description,
    required this.rawCategory,
    required this.date,
  });

  final double amount;
  final String title;
  final String description;
  final String rawCategory;
  final DateTime? date;

  DateTime get sortDate => date ?? DateTime.fromMillisecondsSinceEpoch(0);
  String get monthKey => _monthKey(date ?? DateTime.now());

  factory _ExpenseEntry.fromMap(Map<String, dynamic> raw) {
    final amount = _expenseAmount(raw['amount']);
    final note = raw['note']?.toString().trim() ?? '';
    final rawCategory = _rawCategory(raw);
    final date = _expenseDate(raw['date']);
    final title = note.isNotEmpty
        ? note
        : rawCategory.isNotEmpty
        ? rawCategory
        : 'Expense';
    final details = <String>[
      if (note.isNotEmpty && rawCategory.isNotEmpty) rawCategory,
      if (date != null) DateFormat('d MMM').format(date.toLocal()),
    ];

    return _ExpenseEntry(
      amount: amount,
      title: title,
      description: details.isEmpty ? 'Ledger entry' : details.join(' • '),
      rawCategory: rawCategory,
      date: date,
    );
  }
}

abstract final class _AnalyticsColors {
  static const background = Color(0xFF060910);
  static const backgroundDeep = Color(0xFF0B1020);
  static const panel = Color(0xD9151A24);
  static const panelAlt = Color(0xCC111722);
  static const text = Color(0xFFF4F7FF);
  static const muted = Color(0xFF93A0B8);
  static const border = Color(0x1FFFFFFF);
}

double _expenseAmount(dynamic raw) {
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

DateTime? _expenseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

String _rawCategory(Map<String, dynamic> expense) {
  final category = expense['category'];
  if (category is Map) {
    final name = category['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
  }

  final categoryName = expense['categoryName']?.toString().trim() ?? '';
  if (categoryName.isNotEmpty) return categoryName;

  return expense['category']?.toString().trim() ?? '';
}

String _monthKey(DateTime date) => DateFormat('yyyy-MM').format(date.toLocal());

String _formatMonthLabel(String key) {
  final parsed = DateTime.tryParse('$key-01');
  if (parsed == null) return key;
  return DateFormat('MMMM yyyy').format(parsed);
}

String _formatCurrency(num value) {
  final digits = value == value.roundToDouble() ? 0 : 2;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: MfCurrency.symbol,
    decimalDigits: digits,
  ).format(value);
}

String _formatExpenseCurrency(num value) => '-${_formatCurrency(value)}';

class _AnalyticsBackdrop extends StatelessWidget {
  const _AnalyticsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _AnalyticsColors.background,
                _AnalyticsColors.backgroundDeep,
                Color(0xFF04060B),
              ],
            ),
          ),
        ),
        _GlowOrb(
          top: -80,
          right: -30,
          size: 230,
          colors: [
            const Color(0xFF49D6FF).withValues(alpha: 0.24),
            const Color(0xFF49D6FF).withValues(alpha: 0),
          ],
        ),
        _GlowOrb(
          top: 120,
          left: -90,
          size: 240,
          colors: [
            const Color(0xFFFF5E7E).withValues(alpha: 0.18),
            const Color(0xFFFF5E7E).withValues(alpha: 0),
          ],
        ),
        _GlowOrb(
          bottom: 90,
          right: -80,
          size: 250,
          colors: [
            const Color(0xFFFFD65C).withValues(alpha: 0.18),
            const Color(0xFFFFD65C).withValues(alpha: 0),
          ],
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.colors,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: colors),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({
    required this.canPop,
    required this.monthKeys,
    required this.selectedMonthKey,
    required this.periodSubtitle,
    required this.quickRange,
    required this.onBack,
    required this.onMonthChanged,
    required this.onThisMonth,
    required this.onLastMonth,
    required this.onLast90,
    required this.onCustomRange,
  });

  final bool canPop;
  final List<String> monthKeys;
  final String? selectedMonthKey;
  final String periodSubtitle;
  final _QuickRange quickRange;
  final VoidCallback onBack;
  final ValueChanged<String?> onMonthChanged;
  final VoidCallback onThisMonth;
  final VoidCallback onLastMonth;
  final VoidCallback onLast90;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    final nowKey = _monthKey(DateTime.now());
    final thisMonthChipSelected =
        quickRange == _QuickRange.none &&
        selectedMonthKey != null &&
        selectedMonthKey == nowKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canPop) ...[
              _HeaderIconButton(onTap: onBack),
              const SizedBox(width: MfSpace.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports & analytics',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.1,
                      color: _AnalyticsColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    periodSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: _AnalyticsColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (monthKeys.isNotEmpty && selectedMonthKey != null)
              _MonthSelector(
                monthKeys: monthKeys,
                value: selectedMonthKey!,
                onChanged: onMonthChanged,
              ),
          ],
        ),
        const SizedBox(height: MfSpace.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _RangeChip(
                label: 'This month',
                selected: thisMonthChipSelected,
                onTap: onThisMonth,
              ),
              _RangeChip(
                label: 'Last month',
                selected: quickRange == _QuickRange.lastMonth,
                onTap: onLastMonth,
              ),
              _RangeChip(
                label: '90 days',
                selected: quickRange == _QuickRange.last90,
                onTap: onLast90,
              ),
              _RangeChip(
                label: 'Custom',
                selected: quickRange == _QuickRange.custom,
                onTap: onCustomRange,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: MfSpace.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? const Color(0xFF49D6FF).withValues(alpha: 0.65)
                    : _AnalyticsColors.border,
              ),
              color: selected
                  ? const Color(0xFF49D6FF).withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? _AnalyticsColors.text : _AnalyticsColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _AnalyticsColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: _AnalyticsColors.text,
          ),
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.monthKeys,
    required this.value,
    required this.onChanged,
  });

  final List<String> monthKeys;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AnalyticsColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: false,
          dropdownColor: const Color(0xFF121722),
          borderRadius: BorderRadius.circular(18),
          iconEnabledColor: _AnalyticsColors.text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _AnalyticsColors.text,
          ),
          items: monthKeys
              .map(
                (monthKey) => DropdownMenuItem(
                  value: monthKey,
                  child: Text(
                    _formatMonthLabel(monthKey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
      ),
    );
  }
}

class _AnalyticsPanel extends StatelessWidget {
  const _AnalyticsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _AnalyticsColors.border),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_AnalyticsColors.panel, _AnalyticsColors.panelAlt],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(MfSpace.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AnalyticsScaffoldState extends StatelessWidget {
  const _AnalyticsScaffoldState({
    required this.canPop,
    required this.quickRange,
    required this.child,
  });

  final bool canPop;
  final _QuickRange quickRange;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MfSpace.xl,
            MfSpace.md,
            MfSpace.xl,
            0,
          ),
          child: _AnalyticsHeader(
            canPop: canPop,
            monthKeys: const [],
            selectedMonthKey: null,
            periodSubtitle: 'Loading your ledger…',
            quickRange: quickRange,
            onBack: () => Navigator.of(context).maybePop(),
            onMonthChanged: (_) {},
            onThisMonth: () {},
            onLastMonth: () {},
            onLast90: () {},
            onCustomRange: () {},
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({
    required this.monthLabel,
    required this.onAddExpense,
  });

  final String monthLabel;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel(
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF49D6FF).withValues(alpha: 0.24),
                  const Color(0xFFFF8FD8).withValues(alpha: 0.24),
                ],
              ),
            ),
            child: const Icon(
              Icons.pie_chart_rounded,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'No expenses in $monthLabel',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'Add a few transactions to light up the chart.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _AnalyticsColors.muted,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          FilledButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add expense'),
          ),
        ],
      ),
    );
  }
}

class _ErrorAnalyticsCard extends StatelessWidget {
  const _ErrorAnalyticsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5E7E).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFFF8DA2),
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'Analytics unavailable',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _AnalyticsColors.text,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: _AnalyticsColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 220,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 170,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 132,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ],
    );
  }
}

class _LoadingChartCard extends StatelessWidget {
  const _LoadingChartCard();

  @override
  Widget build(BuildContext context) {
    return const _AnalyticsPanel(
      child: SizedBox(
        height: 520,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF49D6FF)),
        ),
      ),
    );
  }
}

class _LoadingTransactions extends StatelessWidget {
  const _LoadingTransactions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : MfSpace.md),
          child: Container(
            height: 128,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _AnalyticsColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
