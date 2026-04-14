import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/money_flow_tokens.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../domain/analytics_filter.dart';
import 'analytics_filter_sheet.dart';

/// Full drill-down: Category → Subcategory → Type → Entity with shared charts.
class DrilldownAnalyticsScreen extends ConsumerStatefulWidget {
  const DrilldownAnalyticsScreen({super.key, this.initial});

  final AnalyticsFilter? initial;

  @override
  ConsumerState<DrilldownAnalyticsScreen> createState() =>
      _DrilldownAnalyticsScreenState();
}

class _DrilldownAnalyticsScreenState
    extends ConsumerState<DrilldownAnalyticsScreen> {
  late AnalyticsFilter _filter;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _filter = widget.initial ??
        AnalyticsFilter(year: n.year, month: n.month);
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_filter.year ?? DateTime.now().year,
          (_filter.month ?? DateTime.now().month) - 1),
      firstDate: DateTime(2018),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _filter = AnalyticsFilter(
        year: picked.year,
        month: picked.month,
        categoryId: _filter.categoryId,
        subCategoryId: _filter.subCategoryId,
        expenseTypeId: _filter.expenseTypeId,
        spendEntityId: _filter.spendEntityId,
        paymentMode: _filter.paymentMode,
      );
    });
  }

  void _onPieTap(int index, Map<String, dynamic> pie) {
    final ids = (pie['ids'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final level = pie['level']?.toString() ?? '';
    if (index < 0 || index >= ids.length) return;
    final id = ids[index];
    if (id.startsWith('__')) return;
    setState(() {
      switch (level) {
        case 'category':
          _filter = _filter.withCategoryDrill(id);
          break;
        case 'subcategory':
          _filter = _filter.withSubCategoryDrill(id);
          break;
        case 'expenseType':
          _filter = _filter.withExpenseTypeDrill(id);
          break;
        case 'entity':
          _filter = _filter.withSpendEntityDrill(id);
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(analyticsDrilldownProvider(_filter));

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        title: Text(
          'Drill-down analytics',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: () async {
              final next = await showAnalyticsFilterSheet(
                context,
                current: _filter,
              );
              if (next != null && mounted) {
                setState(() => _filter = next);
              }
            },
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Month',
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          TextButton(
            onPressed: () {
              final n = DateTime.now();
              setState(() {
                _filter = AnalyticsFilter(year: n.year, month: n.month);
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: async.when(
        data: (data) {
          final pie = data['pie'] is Map
              ? Map<String, dynamic>.from(data['pie'] as Map)
              : <String, dynamic>{};
          final chart = data['chart'] is Map
              ? Map<String, dynamic>.from(data['chart'] as Map)
              : <String, dynamic>{};
          final monthly = chart['monthlyBar'] is Map
              ? Map<String, dynamic>.from(chart['monthlyBar'] as Map)
              : <String, dynamic>{};
          final line = chart['lineTrend'] is Map
              ? Map<String, dynamic>.from(chart['lineTrend'] as Map)
              : <String, dynamic>{};
          final stacked = chart['stackedCategoryMonth'] is Map
              ? Map<String, dynamic>.from(
                  chart['stackedCategoryMonth'] as Map,
                )
              : <String, dynamic>{};

          final labels = (pie['labels'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final values = (pie['values'] as List?)
                  ?.map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
                  .toList() ??
              <double>[];
          final total = double.tryParse(data['total']?.toString() ?? '0') ?? 0;

          return ListView(
            padding: const EdgeInsets.all(MfSpace.xl),
            children: [
              Text(
                data['period']?.toString() ?? '',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: MfSpace.sm),
              Text(
                NumberFormat.currency(symbol: '₹', decimalDigits: 0)
                    .format(total),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Avg ${data['average']} · ${data['count']} buckets',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: MfSpace.xl),
              Text(
                'Composition (${pie['level']})',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: MfSpace.md),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    sections: List.generate(labels.length, (i) {
                      final v = i < values.length ? values[i] : 0.0;
                      final share = total > 0 ? v / total : 0;
                      return PieChartSectionData(
                        value: v <= 0 ? 0.0001 : v,
                        title: share > 0.05 ? '${(share * 100).round()}%' : '',
                        radius: 58,
                        titleStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        color: Color.lerp(
                          const Color(0xFF49D6FF),
                          const Color(0xFFFF8FD8),
                          i / (labels.length.clamp(1, 99)),
                        )!,
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: MfSpace.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(labels.length, (i) {
                  return ActionChip(
                    label: Text(labels[i]),
                    onPressed: () => _onPieTap(i, pie),
                  );
                }),
              ),
              const SizedBox(height: MfSpace.xl),
              Text(
                'Monthly bars',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: MfSpace.md),
              _MiniBarChart(raw: monthly),
              const SizedBox(height: MfSpace.xl),
              Text(
                'Trend line',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: MfSpace.md),
              _MiniLineChart(raw: line),
              const SizedBox(height: MfSpace.xl),
              Text(
                'Stacked by category (month)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: MfSpace.md),
              _StackedPreview(raw: stacked),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.raw});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    final labels = (raw['labels'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final values = (raw['values'] as List?)
            ?.map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
            .toList() ??
        <double>[];
    if (labels.isEmpty) {
      return const Text('No data', style: TextStyle(color: Colors.white54));
    }
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxV * 1.1,
          barGroups: List.generate(
            labels.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: i < values.length ? values[i] : 0,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                  color: const Color(0xFF49D6FF),
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
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Text(
                    labels[i],
                    style: GoogleFonts.inter(fontSize: 9, color: Colors.white54),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({required this.raw});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    final labels = (raw['labels'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final values = (raw['values'] as List?)
            ?.map((e) => (e is num) ? e.toDouble() : double.tryParse(e.toString()) ?? 0)
            .toList() ??
        <double>[];
    if (labels.isEmpty) {
      return const Text('No data', style: TextStyle(color: Colors.white54));
    }
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                values.length,
                (i) => FlSpot(i.toDouble(), values[i]),
              ),
              color: const Color(0xFFE6FF4D),
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}

class _StackedPreview extends StatelessWidget {
  const _StackedPreview({required this.raw});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    final series = (raw['series'] as List?) ?? [];
    if (series.isEmpty) {
      return Text(
        'No stacked series (add more categories / months)',
        style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
      );
    }
    return Column(
      children: series.map((s) {
        final m = Map<String, dynamic>.from(s as Map);
        final name = m['name']?.toString() ?? '';
        final vals = (m['values'] as List?)
                ?.map((e) => (e is num) ? e.toDouble() : 0.0)
                .toList() ??
            <double>[];
        final sum = vals.fold<double>(0, (a, b) => a + b);
        return ListTile(
          title: Text(name, style: const TextStyle(color: Colors.white)),
          trailing: Text(
            NumberFormat.compact().format(sum),
            style: const TextStyle(color: Color(0xFF49D6FF)),
          ),
        );
      }).toList(),
    );
  }
}
