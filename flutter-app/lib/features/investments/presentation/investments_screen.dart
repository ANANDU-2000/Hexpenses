import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_skeleton.dart';
import '../../../core/dio_errors.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../../core/widgets/premium_fintech_app_bar.dart';
import '../../../core/widgets/premium_fintech_backdrop.dart';
import '../application/investment_providers.dart';
import '../data/investments_api.dart';

double _easeOutCubic(double t) {
  final inv = 1 - t.clamp(0.0, 1.0);
  return 1 - inv * inv * inv;
}

/// Smooth curve from cost basis → current marks (no historical API yet).
List<FlSpot> _portfolioTrajectorySpots(double invested, double current) {
  const n = 14;
  if (invested <= 0 && current <= 0) {
    return List.generate(n, (i) => FlSpot(i.toDouble(), 0));
  }
  final start = invested > 0 ? invested : current * 0.92;
  final end = current > 0 ? current : invested;
  return List.generate(n, (i) {
    final t = n <= 1 ? 1.0 : i / (n - 1);
    final y = start + (end - start) * _easeOutCubic(t);
    return FlSpot(i.toDouble(), y);
  });
}

class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  static String _kindLabel(String k) {
    switch (k) {
      case 'stock':
        return 'Stock';
      case 'sip':
        return 'SIP';
      case 'crypto':
        return 'Crypto';
      default:
        return 'Other';
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static IconData _iconForKind(String kind) {
    switch (kind) {
      case 'crypto':
        return Icons.currency_bitcoin_rounded;
      case 'sip':
        return Icons.savings_rounded;
      case 'stock':
        return Icons.candlestick_chart_rounded;
      default:
        return Icons.pie_chart_outline_rounded;
    }
  }

  static List<Color> _avatarGradientForKind(String kind) {
    switch (kind) {
      case 'crypto':
        return [
          const Color(0xFFF59E0B),
          const Color(0xFFEA580C),
        ];
      case 'sip':
        return [
          MfPalette.accentSoftPurple,
          const Color(0xFF6366F1),
        ];
      case 'stock':
        return [
          const Color(0xFF22C55E),
          const Color(0xFF059669),
        ];
      default:
        return [
          MfPalette.accentSoftPurple.withValues(alpha: 0.85),
          MfPalette.neonGreenSoft.withValues(alpha: 0.7),
        ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(investmentPortfolioProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: PremiumFintechAppBar.bar(
        context: context,
        title: 'Investments',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: LedgerFab(
        heroTag: 'investments_fab',
        tooltip: 'Add investment',
        onPressed: () => _addHolding(context, ref),
        icon: Icons.add_rounded,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumFintechBackdrop(),
          async.when(
            data: (data) => _InvestmentsLoadedBody(
              data: data,
              onRefresh: () async {
                ref.invalidate(investmentPortfolioProvider);
                await ref.read(investmentPortfolioProvider.future);
              },
              onAddTap: () => _addHolding(context, ref),
              onEditHolding: (h) => _editHolding(context, ref, h),
            ),
            loading: () => const _InvestmentsLoadingBody(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(MfSpace.xxl),
              child: LedgerErrorState(
                title: 'Could not load portfolio',
                message: e is DioException ? dioErrorMessage(e) : e.toString(),
                onRetry: () => ref.invalidate(investmentPortfolioProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addHolding(BuildContext context, WidgetRef ref) {
    _showHoldingSheet(context, ref, null);
  }

  void _editHolding(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> h,
  ) {
    _showHoldingSheet(context, ref, h);
  }

  void _showHoldingSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? existing,
  ) {
    final name = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final invested = TextEditingController(
      text: existing != null
          ? _toDouble(existing['investedAmount']).toString()
          : '',
    );
    final current = TextEditingController(
      text: existing != null
          ? _toDouble(existing['currentValue']).toString()
          : '',
    );
    final note = TextEditingController(
      text: existing?['note']?.toString() ?? '',
    );
    String kind = existing?['kind']?.toString() ?? 'stock';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (context, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'Add holding' : 'Edit holding',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(kind),
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'stock', child: Text('Stock')),
                  DropdownMenuItem(
                    value: 'sip',
                    child: Text('SIP / mutual fund'),
                  ),
                  DropdownMenuItem(value: 'crypto', child: Text('Crypto')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setSt(() => kind = v ?? 'stock'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: invested,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount invested (cost basis)',
                  helperText: 'Total you put in',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: current,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current value',
                  helperText: 'Latest portfolio / market value',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final n = name.text.trim();
                  if (n.isEmpty) return;
                  final inv = double.tryParse(
                    invested.text.replaceAll(',', ''),
                  );
                  final cur = double.tryParse(current.text.replaceAll(',', ''));
                  if (inv == null || cur == null) return;
                  Navigator.pop(ctx);
                  try {
                    final api = ref.read(investmentsApiProvider);
                    if (existing == null) {
                      await api.create(
                        name: n,
                        kind: kind,
                        investedAmount: inv,
                        currentValue: cur,
                        note: note.text.trim().isEmpty
                            ? null
                            : note.text.trim(),
                      );
                    } else {
                      await api.update(
                        id: existing['id']!.toString(),
                        name: n,
                        kind: kind,
                        investedAmount: inv,
                        currentValue: cur,
                        note: note.text.trim(),
                      );
                    }
                    ref.invalidate(investmentPortfolioProvider);
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(dioErrorMessage(e))),
                      );
                    }
                  }
                },
                child: Text(existing == null ? 'Save' : 'Update'),
              ),
              if (existing != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(investmentsApiProvider)
                          .delete(existing['id']!.toString());
                      ref.invalidate(investmentPortfolioProvider);
                    } on DioException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(dioErrorMessage(e))),
                        );
                      }
                    }
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestmentsLoadingBody extends StatelessWidget {
  const _InvestmentsLoadingBody();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 8, MfSpace.xxl, 120),
      children: [
        AppSkeleton(
          borderRadius: BorderRadius.circular(MfRadius.lg),
          child: Container(
            height: 168,
            color: cs.surfaceContainerHigh.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: MfSpace.xl),
        AppSkeleton(
          borderRadius: BorderRadius.circular(MfRadius.lg),
          child: Container(
            height: 200,
            color: cs.surfaceContainerHigh.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(height: MfSpace.xl),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: MfSpace.md),
            child: AppSkeleton(
              borderRadius: BorderRadius.circular(MfRadius.lg),
              child: Container(
                height: 76,
                color: cs.surfaceContainerHigh.withValues(alpha: 0.22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InvestmentsLoadedBody extends StatelessWidget {
  const _InvestmentsLoadedBody({
    required this.data,
    required this.onRefresh,
    required this.onAddTap,
    required this.onEditHolding,
  });

  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddTap;
  final void Function(Map<String, dynamic> h) onEditHolding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summaryRaw = data['summary'];
    final summary = summaryRaw is Map
        ? Map<String, dynamic>.from(summaryRaw)
        : <String, dynamic>{};
    final holdingsRaw = data['holdings'];
    final holdings = holdingsRaw is List
        ? holdingsRaw
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
        : <Map<String, dynamic>>[];

    final totalInv = InvestmentsScreen._toDouble(summary['totalInvested']);
    final totalCur = InvestmentsScreen._toDouble(summary['totalCurrentValue']);
    final pnl = InvestmentsScreen._toDouble(summary['profitLoss']);
    final pnlPct = InvestmentsScreen._toDouble(summary['profitLossPercent']);

    return RefreshIndicator(
      color: MfPalette.neonGreen,
      backgroundColor: cs.surfaceContainerLow,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 8, MfSpace.xxl, 0),
            sliver: SliverToBoxAdapter(
              child: _PortfolioSummaryGradientCard(
                totalInvested: totalInv,
                currentValue: totalCur,
                profitLoss: pnl,
                profitLossPercent: pnlPct,
                holdingCount: holdings.length,
              ),
            ),
          ),
          if (holdings.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                MfSpace.xxl,
                MfSpace.xl,
                MfSpace.xxl,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _PerformanceLineChartCard(
                  spots: _portfolioTrajectorySpots(totalInv, totalCur),
                  linePositive: pnl >= 0,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                MfSpace.xxl,
                MfSpace.xl,
                MfSpace.xxl,
                MfSpace.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: MfPalette.neonGreen,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: MfSpace.md),
                    Text(
                      'Holdings',
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${holdings.length} ${holdings.length == 1 ? 'asset' : 'assets'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                MfSpace.xxl,
                MfSpace.sm,
                MfSpace.xxl,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final h = holdings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: MfSpace.md),
                      child: _HoldingRowCard(
                        holding: h,
                        onTap: () => onEditHolding(h),
                      ),
                    );
                  },
                  childCount: holdings.length,
                ),
              ),
            ),
          ] else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 0, MfSpace.xxl, 100),
                child: _InvestmentsEmptyState(onAddTap: onAddTap),
              ),
            ),
        ],
      ),
    );
  }
}

class _PortfolioSummaryGradientCard extends StatelessWidget {
  const _PortfolioSummaryGradientCard({
    required this.totalInvested,
    required this.currentValue,
    required this.profitLoss,
    required this.profitLossPercent,
    required this.holdingCount,
  });

  final double totalInvested;
  final double currentValue;
  final double profitLoss;
  final double profitLossPercent;
  final int holdingCount;

  @override
  Widget build(BuildContext context) {
    final up = profitLoss >= 0;
    final pnlColor = up ? MfPalette.incomeGreen : MfPalette.expenseRed;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MfRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1B4B),
            MfPalette.accentSoftPurple.withValues(alpha: 0.85),
            const Color(0xFF0F172A),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: MfPalette.accentSoftPurple.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MfRadius.xl),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -20,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MfPalette.neonGreen.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(MfSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 22,
                      ),
                      const SizedBox(width: MfSpace.sm),
                      Text(
                        'Portfolio summary',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                      const Spacer(),
                      if (holdingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MfSpace.md,
                            vertical: MfSpace.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$holdingCount positions',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: MfSpace.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricBlock(
                          label: 'Total invested',
                          value: MfCurrency.formatInr(totalInvested),
                          emphasized: false,
                        ),
                      ),
                      Expanded(
                        child: _MetricBlock(
                          label: 'Current value',
                          value: MfCurrency.formatInr(currentValue),
                          emphasized: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MfSpace.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MfSpace.lg,
                      vertical: MfSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(MfRadius.lg),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          up
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: pnlColor,
                          size: 22,
                        ),
                        const SizedBox(width: MfSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profit / loss',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${profitLoss >= 0 ? '+' : ''}${MfCurrency.formatInr(profitLoss)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: pnlColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MfSpace.md,
                            vertical: MfSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: pnlColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(MfRadius.md),
                          ),
                          child: Text(
                            '${profitLoss >= 0 ? '+' : ''}${profitLossPercent.toStringAsFixed(1)}%',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: pnlColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.emphasized,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: emphasized ? 19 : 16,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: emphasized ? 1 : 0.88),
            height: 1.15,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PerformanceLineChartCard extends StatelessWidget {
  const _PerformanceLineChartCard({
    required this.spots,
    required this.linePositive,
  });

  final List<FlSpot> spots;
  final bool linePositive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ys = spots.map((s) => s.y).toList();
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    final span = (maxY - minY).abs();
    final pad = span > 1e-6 ? span * 0.12 : math.max(minY * 0.05, 1.0);
    minY -= pad;
    maxY += pad;

    final lineColor = linePositive ? MfPalette.incomeGreen : MfPalette.expenseRed;

    return AppCard(
      glass: true,
      padding: const EdgeInsets.fromLTRB(MfSpace.lg, MfSpace.lg, MfSpace.lg, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 20,
                color: MfPalette.accentSoftPurple,
              ),
              const SizedBox(width: MfSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio trajectory',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Smoothed curve from total invested → current value. '
                      'Not live market history.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        height: 1.35,
                        color: cs.onSurface.withValues(alpha: 0.52),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.md),
          SizedBox(
            height: 188,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: cs.outlineVariant.withValues(alpha: 0.18),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: math.max(1, spots.length / 4).floorToDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i != 0 && i != spots.length - 1) {
                          return const SizedBox();
                        }
                        final label = i == 0 ? 'Start' : 'Now';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.48),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) {
                        final abs = v.abs();
                        final t = abs >= 100000
                            ? '${(abs / 100000).toStringAsFixed(1)}L'
                            : abs >= 1000
                            ? '${(abs / 1000).toStringAsFixed(1)}k'
                            : v.toInt().toString();
                        return Text(
                          t,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: cs.onSurface.withValues(alpha: 0.42),
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, b, i) {
                        final show = i == 0 || i == spots.length - 1;
                        if (!show) {
                          return FlDotCirclePainter(
                            radius: 0,
                            color: Colors.transparent,
                            strokeWidth: 0,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 4,
                          color: lineColor,
                          strokeWidth: 2,
                          strokeColor: cs.surfaceContainerLowest,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.28),
                          lineColor.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        cs.surfaceContainerHigh.withValues(alpha: 0.94),
                    getTooltipItems: (touched) {
                      return touched.map((t) {
                        return LineTooltipItem(
                          MfCurrency.formatInr(t.y),
                          GoogleFonts.manrope(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoldingRowCard extends StatelessWidget {
  const _HoldingRowCard({
    required this.holding,
    required this.onTap,
  });

  final Map<String, dynamic> holding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = holding['name']?.toString() ?? '';
    final kind = holding['kind']?.toString() ?? 'other';
    final cur = InvestmentsScreen._toDouble(holding['currentValue']);
    final pct = InvestmentsScreen._toDouble(holding['profitLossPercent']);
    final up = pct >= 0;
    final pctColor = up ? MfPalette.incomeGreen : MfPalette.expenseRed;
    final grads = InvestmentsScreen._avatarGradientForKind(kind);

    return AppCard(
      glass: true,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: MfSpace.lg,
        vertical: MfSpace.md,
      ),
      child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MfRadius.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: grads,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: grads.last.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  InvestmentsScreen._iconForKind(kind),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline_rounded,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          InvestmentsScreen._kindLabel(kind),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MfCurrency.formatInr(cur),
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MfSpace.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pctColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          up
                              ? Icons.arrow_outward_rounded
                              : Icons.south_west_rounded,
                          size: 14,
                          color: pctColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${up ? '+' : ''}${pct.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: pctColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

class _InvestmentsEmptyState extends StatelessWidget {
  const _InvestmentsEmptyState({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - t)),
              child: AppCard(
                glass: true,
                padding: const EdgeInsets.all(MfSpace.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _InvestmentsEmptyIllustration(width: 200),
                    const SizedBox(height: MfSpace.xl),
                    Icon(
                      Icons.stacked_line_chart_rounded,
                      size: 28,
                      color: MfPalette.accentSoftPurple,
                    ),
                    const SizedBox(height: MfSpace.md),
                    Text(
                      'No investments yet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: MfSpace.sm),
                    Text(
                      'Track stocks, SIPs, and crypto in one place. '
                      'Add your first holding to see portfolio value and performance.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.45,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: MfSpace.xl),
                    FilledButton.icon(
                      onPressed: onAddTap,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Investment'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Finance / crypto themed: growth line, bars, coin.
class _InvestmentsEmptyIllustration extends StatelessWidget {
  const _InvestmentsEmptyIllustration({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.55;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(
        painter: _InvestmentsEmptyPainter(),
      ),
    );
  }
}

class _InvestmentsEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final barPaint = Paint()..style = PaintingStyle.fill;

    // Soft panel
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.84, h * 0.62),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = LinearGradient(
          colors: [
            MfPalette.accentSoftPurple.withValues(alpha: 0.25),
            MfPalette.neonGreen.withValues(alpha: 0.08),
          ],
        ).createShader(panel.outerRect),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.2),
    );

    // Mini bars
    final heights = [0.35, 0.55, 0.42, 0.68, 0.5];
    final bw = w * 0.07;
    for (var i = 0; i < heights.length; i++) {
      final x = w * 0.18 + i * (bw + w * 0.04);
      final bh = h * heights[i] * 0.35;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, h * 0.55 - bh, bw, bh),
        const Radius.circular(4),
      );
      barPaint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          MfPalette.accentSoftPurple.withValues(alpha: 0.9),
          MfPalette.neonGreen.withValues(alpha: 0.5),
        ],
      ).createShader(rect.outerRect);
      canvas.drawRRect(rect, barPaint);
    }

    // Uptrend line
    final linePath = Path()
      ..moveTo(w * 0.2, h * 0.72)
      ..quadraticBezierTo(w * 0.45, h * 0.35, w * 0.82, h * 0.22);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = MfPalette.neonGreen.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );

    // Coin
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.2),
      w * 0.065,
      Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.2),
      w * 0.065,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
