import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static List<Color> _sectionColors(ColorScheme cs) => [
    cs.primary,
    cs.primaryContainer,
    cs.tertiary,
    cs.secondary,
    cs.error,
    cs.inverseSurface,
  ];

  static String _formatMonthLabel(String key) {
    final parts = key.split('-');
    if (parts.length < 2) return key;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final index = month - 1;
    if (index < 0 || index >= months.length) return key;
    return '${months[index]} $year';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final summary = ref.watch(monthlySummaryProvider);
    final tax = ref.watch(taxSummaryProvider);
    final breakdown = ref.watch(categoryBreakdownProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: cs.primary,
          onRefresh: () async {
            await ref.read(ledgerSyncServiceProvider).pullAndFlush();
            ref.invalidate(monthlySummaryProvider);
            ref.invalidate(dashboardOverviewProvider);
            ref.invalidate(categoryBreakdownProvider);
            ref.invalidate(taxSummaryProvider);
            await ref.read(monthlySummaryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              summary.when(
                data: (m) => LedgerActionLayer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This month',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReportStatRow(
                        label: 'Income',
                        value: m['totalIncome']?.toString() ?? '0',
                        color: cs.tertiary,
                      ),
                      const SizedBox(height: 6),
                      _ReportStatRow(
                        label: 'Expenses',
                        value: m['totalExpenses']?.toString() ?? '0',
                        color: cs.error,
                      ),
                      const SizedBox(height: 10),
                      _ReportStatRow(
                        label: 'Cash flow',
                        value: m['netCashFlow']?.toString() ?? '0',
                        color: cs.primary,
                      ),
                      Text(
                        _formatMonthLabel(m['month']?.toString() ?? ''),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Income by source',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ..._incomeBySourceRows(context, m['incomeBySource']),
                    ],
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Something went wrong. Please try refreshing.',
                  style: TextStyle(color: cs.error),
                ),
              ),
              const SizedBox(height: 16),
              tax.when(
                data: (t) => LedgerSectionLayer(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GST / VAT (this month)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      Text(
                        _formatMonthLabel(t['period']?.toString() ?? ''),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (ctx) {
                          final tot = t['totals'];
                          final tm = tot is Map
                              ? Map<String, dynamic>.from(tot)
                              : <String, dynamic>{};
                          final count =
                              int.tryParse(
                                tm['taxableExpenseCount']?.toString() ?? '0',
                              ) ??
                              0;
                          if (count == 0) {
                            return Text(
                              'No taxable expenses this month. Mark expenses when adding them.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ReportStatRow(
                                label: 'Total expense (incl. tax)',
                                value:
                                    tm['totalTaxableExpenseAmount']
                                        ?.toString() ??
                                    '0',
                                color: cs.onSurface,
                              ),
                              const SizedBox(height: 6),
                              _ReportStatRow(
                                label: 'Total tax',
                                value: tm['totalTaxAmount']?.toString() ?? '0',
                                color: cs.tertiary,
                              ),
                              const SizedBox(height: 6),
                              _ReportStatRow(
                                label: 'Net (excl. tax)',
                                value:
                                    tm['totalNetExcludingTax']?.toString() ??
                                    '0',
                                color: cs.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'By regime',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              ..._taxBySchemeRows(context, t['byScheme']),
                              const SizedBox(height: 12),
                              Text(
                                'Taxable lines',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              ..._taxLineRows(context, t['lines']),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Something went wrong. Please try refreshing.',
                  style: TextStyle(color: cs.error),
                ),
              ),
              const SizedBox(height: 16),
              breakdown.when(
                data: (rows) {
                  if (rows.isEmpty) {
                    return const _ReportsEmptyState();
                  }
                  final sorted = [...rows]
                    ..sort((a, b) {
                      final da =
                          double.tryParse(a['total']?.toString() ?? '0') ?? 0;
                      final db =
                          double.tryParse(b['total']?.toString() ?? '0') ?? 0;
                      return db.compareTo(da);
                    });
                  final values = sorted
                      .take(6)
                      .map(
                        (e) =>
                            double.tryParse(e['total']?.toString() ?? '0') ?? 0,
                      )
                      .toList();
                  final sum = values.fold<double>(0, (a, b) => a + b);
                  if (sum <= 0) {
                    return const _ReportsEmptyState();
                  }
                  final palette = _sectionColors(cs);
                  return LedgerSectionLayer(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 28,
                          sections: List.generate(values.length, (i) {
                            final v = values[i];
                            final pct = v / sum * 100;
                            final c = palette[i % palette.length];
                            return PieChartSectionData(
                              value: v,
                              title: '${pct.toStringAsFixed(0)}%',
                              radius: 52,
                              color: c,
                              titleStyle: GoogleFonts.inter(
                                fontSize: 11,
                                color: c.computeLuminance() > 0.55
                                    ? cs.onSurface
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) =>
                    const Text('Something went wrong. Please try refreshing.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _taxBySchemeRows(BuildContext context, dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return [Text('-', style: Theme.of(context).textTheme.bodySmall)];
    }
    final cs = Theme.of(context).colorScheme;
    return raw.map<Widget>((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final label = map['label']?.toString() ?? map['scheme']?.toString() ?? '';
      final tax = map['totalTax']?.toString() ?? '0';
      final net = map['netExcludingTax']?.toString() ?? '0';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    'Net $net',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              tax,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: cs.tertiary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  static List<Widget> _taxLineRows(BuildContext context, dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return [Text('-', style: Theme.of(context).textTheme.bodySmall)];
    }
    final cs = Theme.of(context).colorScheme;
    return raw.take(20).map<Widget>((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final date = map['date']?.toString().split('T').first ?? '';
      final cat = map['categoryName']?.toString() ?? '';
      final scheme = map['taxSchemeLabel']?.toString() ?? '';
      final tax = map['taxAmount']?.toString() ?? '0';
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '$date · $scheme',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Text(
              tax,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  static List<Widget> _incomeBySourceRows(BuildContext context, dynamic raw) {
    if (raw is! List) {
      return [Text('-', style: Theme.of(context).textTheme.bodySmall)];
    }
    final cs = Theme.of(context).colorScheme;
    if (raw.isEmpty) {
      return [
        Text('No income entries', style: Theme.of(context).textTheme.bodySmall),
      ];
    }
    return raw.map<Widget>((row) {
      final map = row as Map;
      final src = map['source']?.toString() ?? '';
      final total = map['total']?.toString() ?? '0';
      final label = src.isEmpty
          ? '-'
          : '${src[0].toUpperCase()}${src.substring(1)}';
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              total,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions this month',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Add expenses or income to generate your report.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add expense'),
          ),
        ],
      ),
    );
  }
}

class _ReportStatRow extends StatelessWidget {
  const _ReportStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }
}
