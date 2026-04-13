import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/dio_errors.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../../core/widgets/premium_fintech_app_bar.dart';
import '../../../core/widgets/premium_fintech_backdrop.dart';
import '../application/vehicle_providers.dart';
import '../data/vehicles_api.dart';

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

String _vehicleTypeLabel(String? raw) {
  switch (raw) {
    case 'bike':
      return 'Bike';
    case 'other':
      return 'Vehicle';
    case 'car':
    default:
      return 'Car';
  }
}

IconData _vehicleTypeIcon(String? raw) {
  switch (raw) {
    case 'bike':
      return Icons.two_wheeler_rounded;
    case 'other':
      return Icons.local_shipping_rounded;
    case 'car':
    default:
      return Icons.directions_car_filled_rounded;
  }
}

/// Aggregate straight-line book value (60-month life) per calendar month.
List<FlSpot> _depreciationBookSpots(
  List<Map<String, dynamic>> vehicles,
  int monthSpan,
) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month - monthSpan, 1);
  const lifeMonths = 60.0;
  final spots = <FlSpot>[];
  for (var i = 0; i <= monthSpan; i++) {
    final monthDate = DateTime(start.year, start.month + i, 1);
    var sumBook = 0.0;
    for (final v in vehicles) {
      final purchase = _parseDate(v['purchaseDate']);
      final cost = _toDouble(v['purchasePrice']) ?? 0;
      if (purchase == null || cost <= 0) continue;
      final purchaseMonth = DateTime(purchase.year, purchase.month, 1);
      if (monthDate.isBefore(purchaseMonth)) continue;
      final ageMonths = math.max(
        0,
        (monthDate.difference(purchaseMonth).inDays / 30.44).floorToDouble(),
      );
      final dep = (cost / lifeMonths) * ageMonths;
      sumBook += math.max(0, cost - dep);
    }
    spots.add(FlSpot(i.toDouble(), sumBook));
  }
  return spots;
}

double _totalReportedValue(List<Map<String, dynamic>> vehicles) {
  var t = 0.0;
  for (final v in vehicles) {
    final cur = _toDouble(v['currentValue']);
    final pur = _toDouble(v['purchasePrice']);
    t += cur ?? pur ?? 0;
  }
  return t;
}

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(vehiclesListProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: PremiumFintechAppBar.bar(
        context: context,
        title: 'Vehicles',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: LedgerFab(
        heroTag: 'vehicles_fab',
        tooltip: 'Add vehicle',
        onPressed: () => _openAddVehicle(context, ref),
        icon: Icons.add_rounded,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumFintechBackdrop(),
          async.when(
            data: (list) => RefreshIndicator(
              color: MfPalette.neonGreen,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
              onRefresh: () async {
                ref.invalidate(vehiclesListProvider);
                await ref.read(vehiclesListProvider.future);
              },
              child: list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        MfSpace.xxl,
                        24,
                        MfSpace.xxl,
                        120,
                      ),
                      children: [
                        _VehiclesEmptyState(
                          onAdd: () => _openAddVehicle(context, ref),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            MfSpace.xxl,
                            8,
                            MfSpace.xxl,
                            MfSpace.md,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: _TotalAssetValueCard(
                              total: _totalReportedValue(list),
                              count: list.length,
                            ),
                          ),
                        ),
                        if (_depreciationBookSpots(list, 12).isNotEmpty &&
                            list.any(
                              (v) =>
                                  _parseDate(v['purchaseDate']) != null &&
                                  (_toDouble(v['purchasePrice']) ?? 0) > 0,
                            ))
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              MfSpace.xxl,
                              0,
                              MfSpace.xxl,
                              MfSpace.md,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _DepreciationChartCard(
                                bookSpots: _depreciationBookSpots(list, 12),
                                reportedTotal: _totalReportedValue(list),
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            MfSpace.xxl,
                            MfSpace.sm,
                            MfSpace.xxl,
                            4,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: MfPalette.accentSoftPurple,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                const SizedBox(width: MfSpace.md),
                                Text(
                                  'Your vehicles',
                                  style: GoogleFonts.manrope(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface,
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
                                final v = list[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: MfSpace.md),
                                  child: _VehicleAssetCard(
                                    vehicle: v,
                                    onTap: () => _openVehicleDetail(
                                      context,
                                      ref,
                                      v,
                                    ),
                                  ),
                                );
                              },
                              childCount: list.length,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(MfSpace.xxl),
              child: LedgerErrorState(
                title: 'Could not load vehicles',
                message: e is DioException ? dioErrorMessage(e) : e.toString(),
                onRetry: () => ref.invalidate(vehiclesListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddVehicle(BuildContext context, WidgetRef ref) {
    _VehicleFormSheet.show(context, ref);
  }

  void _openVehicleDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> vehicle,
  ) {
    _VehicleDetailSheet.show(context, ref, vehicle);
  }
}

class _TotalAssetValueCard extends StatelessWidget {
  const _TotalAssetValueCard({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MfRadius.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F172A),
            MfPalette.accentSoftPurple.withValues(alpha: 0.75),
            const Color(0xFF1E293B),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: MfPalette.accentSoftPurple.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(MfSpace.xl),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(MfSpace.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(MfRadius.md),
              ),
              child: Icon(
                Icons.pie_chart_outline_rounded,
                color: MfPalette.neonGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: MfSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL ASSET VALUE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    MfCurrency.formatInr(total),
                    style: GoogleFonts.manrope(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? 'vehicle' : 'vehicles'} in garage',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.72),
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

class _InsuranceBadge extends StatelessWidget {
  const _InsuranceBadge({required this.expiry});

  final DateTime? expiry;

  @override
  Widget build(BuildContext context) {
    if (expiry == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: MfSpace.sm, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(
                alpha: 0.85,
              ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              'Insurance —',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      );
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(expiry!.year, expiry!.month, expiry!.day);
    final days = end.difference(today).inDays;
    final expired = end.isBefore(today);
    final soon = !expired && days <= 30;

    final Color bg;
    final Color fg;
    final String label;
    if (expired) {
      bg = MfPalette.expenseRed.withValues(alpha: 0.15);
      fg = MfPalette.expenseRed;
      label = 'Expired';
    } else if (soon) {
      bg = MfPalette.warningAmber.withValues(alpha: 0.18);
      fg = MfPalette.warningAmber;
      label = 'Renews soon';
    } else {
      bg = MfPalette.incomeGreen.withValues(alpha: 0.15);
      fg = MfPalette.incomeGreen;
      label = 'Insured';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MfSpace.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleAssetCard extends StatelessWidget {
  const _VehicleAssetCard({
    required this.vehicle,
    required this.onTap,
  });

  final Map<String, dynamic> vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = vehicle['name']?.toString() ?? '';
    final number = vehicle['number']?.toString() ?? '';
    final type = vehicle['vehicleType']?.toString() ?? 'car';
    final purchase = _parseDate(vehicle['purchaseDate']);
    final cur = _toDouble(vehicle['currentValue']);
    final pur = _toDouble(vehicle['purchasePrice']);
    final displayValue = cur ?? pur;
    final insuranceExpiry = _parseDate(vehicle['insuranceExpiryDate']);

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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MfRadius.md),
                  gradient: LinearGradient(
                    colors: [
                      MfPalette.accentSoftPurple,
                      MfPalette.accentSoftPurple.withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Icon(
                  _vehicleTypeIcon(type),
                  color: Colors.white,
                  size: 28,
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_vehicleTypeLabel(type)} · $number',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.52),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.lg),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.payments_outlined,
                  label: 'Value',
                  value: displayValue != null
                      ? MfCurrency.formatInr(displayValue)
                      : '—',
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.event_available_outlined,
                  label: 'Purchased',
                  value: purchase != null
                      ? DateFormat.yMMMd().format(purchase.toLocal())
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.md),
          _InsuranceBadge(expiry: insuranceExpiry),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.85)),
        const SizedBox(width: MfSpace.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.48),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepreciationChartCard extends StatelessWidget {
  const _DepreciationChartCard({
    required this.bookSpots,
    required this.reportedTotal,
  });

  final List<FlSpot> bookSpots;
  final double reportedTotal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (bookSpots.isEmpty) return const SizedBox.shrink();

    final ys = bookSpots.map((s) => s.y).toList();
    var minY = ys.reduce(math.min);
    var maxY = ys.reduce(math.max);
    if (reportedTotal > 0) {
      minY = math.min(minY, reportedTotal);
      maxY = math.max(maxY, reportedTotal);
    }
    final span = (maxY - minY).abs();
    final pad = span > 1e-6 ? span * 0.1 : 1.0;
    minY = math.max(0, minY - pad);
    maxY += pad;

    final flatSpots = bookSpots
        .map((s) => FlSpot(s.x, reportedTotal))
        .toList();

    return AppCard(
      glass: true,
      padding: const EdgeInsets.fromLTRB(MfSpace.lg, MfSpace.lg, MfSpace.lg, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.area_chart_rounded, color: cs.primary, size: 20),
              const SizedBox(width: MfSpace.sm),
              Expanded(
                child: Text(
                  'Depreciation (book value)',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Straight-line over 60 months from purchase price. '
            'Dashed = total reported value today.',
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.35,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: MfSpace.md),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: cs.outlineVariant.withValues(alpha: 0.16),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: math.max(1, bookSpots.length / 4).floorToDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.round();
                        if (i != 0 && i != bookSpots.length - 1) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            i == 0 ? 'Past' : 'Now',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) {
                        final abs = v.abs();
                        final t = abs >= 100000
                            ? '${(abs / 100000).toStringAsFixed(1)}L'
                            : abs >= 1000
                            ? '${(abs / 1000).toStringAsFixed(0)}k'
                            : v.toInt().toString();
                        return Text(
                          t,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: cs.onSurface.withValues(alpha: 0.4),
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
                    spots: bookSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: MfPalette.accentSoftPurple,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          MfPalette.accentSoftPurple.withValues(alpha: 0.22),
                          MfPalette.accentSoftPurple.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                  if (reportedTotal > 0)
                    LineChartBarData(
                      spots: flatSpots,
                      isCurved: false,
                      color: MfPalette.neonGreen.withValues(alpha: 0.85),
                      barWidth: 2,
                      dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                    ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        cs.surfaceContainerHigh.withValues(alpha: 0.95),
                    getTooltipItems: (touched) => touched.map((t) {
                      return LineTooltipItem(
                        MfCurrency.formatInr(t.y),
                        GoogleFonts.manrope(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehiclesEmptyState extends StatelessWidget {
  const _VehiclesEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(MfSpace.xxl),
      child: Column(
        children: [
          const _VehiclesEmptyIllustration(width: 200),
          const SizedBox(height: MfSpace.xl),
          Icon(
            Icons.directions_car_filled_rounded,
            size: 32,
            color: MfPalette.accentSoftPurple,
          ),
          const SizedBox(height: MfSpace.md),
          Text(
            'No vehicles added',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'Track cars and bikes with value, purchase date, and insurance status.',
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
            label: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }
}

class _VehiclesEmptyIllustration extends StatelessWidget {
  const _VehiclesEmptyIllustration({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.48;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(painter: _VehiclesEmptyPainter()),
    );
  }
}

class _VehiclesEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.28, w * 0.76, h * 0.42),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [
            MfPalette.accentSoftPurple.withValues(alpha: 0.35),
            MfPalette.neonGreen.withValues(alpha: 0.12),
          ],
        ).createShader(r.outerRect),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    // Simple car silhouette
    final car = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.22, h * 0.38, w * 0.56, h * 0.22),
          const Radius.circular(8),
        ),
      );
    canvas.drawPath(car, Paint()..color = Colors.white.withValues(alpha: 0.2));
    canvas.drawCircle(Offset(w * 0.32, h * 0.62), w * 0.055, Paint()..color = const Color(0xFF334155));
    canvas.drawCircle(Offset(w * 0.68, h * 0.62), w * 0.055, Paint()..color = const Color(0xFF334155));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Add or edit vehicle asset fields + running cost entry.
class _VehicleDetailSheet {
  static void show(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> v,
  ) {
    final id = v['id']?.toString() ?? '';
    final name = TextEditingController(text: v['name']?.toString() ?? '');
    final number = TextEditingController(text: v['number']?.toString() ?? '');
    String type = v['vehicleType']?.toString() ?? 'car';
    final purchase = _parseDate(v['purchaseDate']);
    final purchasePrice = _toDouble(v['purchasePrice']);
    final currentVal = _toDouble(v['currentValue']);
    final ins = _parseDate(v['insuranceExpiryDate']);
    final purchaseCtrl = TextEditingController(
      text: purchasePrice != null ? purchasePrice.toString() : '',
    );
    final currentCtrl = TextEditingController(
      text: currentVal != null ? currentVal.toString() : '',
    );
    DateTime? purchaseD = purchase;
    DateTime? insD = ins;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  name.text.isEmpty ? 'Vehicle' : name.text,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: number,
                  decoration: const InputDecoration(labelText: 'Plate / number'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(type),
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'car', child: Text('Car')),
                    DropdownMenuItem(value: 'bike', child: Text('Bike')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (x) => setSt(() => type = x ?? 'car'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Purchase date'),
                  subtitle: Text(
                    purchaseD != null
                        ? DateFormat.yMMMd().format(purchaseD!.toLocal())
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final x = await showDatePicker(
                      context: context,
                      initialDate: purchaseD ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (x != null) setSt(() => purchaseD = x);
                  },
                ),
                TextField(
                  controller: purchaseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purchase price',
                    hintText: 'Cost when bought',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Current estimated value',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Insurance expiry'),
                  subtitle: Text(
                    insD != null
                        ? DateFormat.yMMMd().format(insD!.toLocal())
                        : 'Not set',
                  ),
                  trailing: const Icon(Icons.shield_outlined),
                  onTap: () async {
                    final x = await showDatePicker(
                      context: context,
                      initialDate: insD ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (x != null) setSt(() => insD = x);
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty || number.text.trim().isEmpty) {
                      return;
                    }
                    double? pp;
                    if (purchaseCtrl.text.trim().isEmpty) {
                      pp = null;
                    } else {
                      pp = double.tryParse(purchaseCtrl.text.replaceAll(',', ''));
                      if (pp == null) return;
                    }
                    double? cv;
                    if (currentCtrl.text.trim().isEmpty) {
                      cv = null;
                    } else {
                      cv = double.tryParse(currentCtrl.text.replaceAll(',', ''));
                      if (cv == null) return;
                    }
                    try {
                      await ref.read(vehiclesApiProvider).updateVehicle(
                            id: id,
                            name: name.text.trim(),
                            number: number.text.trim(),
                            vehicleType: type,
                            purchaseDate: purchaseD,
                            purchasePrice: pp,
                            currentValue: cv,
                            insuranceExpiryDate: insD,
                          );
                      ref.invalidate(vehiclesListProvider);
                      if (context.mounted) Navigator.pop(ctx);
                    } on DioException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(dioErrorMessage(e))),
                        );
                      }
                    }
                  },
                  child: const Text('Save changes'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _VehicleCostSheet.show(context, ref, id);
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Add running cost'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleFormSheet {
  static void show(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final number = TextEditingController();
    String type = 'car';
    final purchaseCtrl = TextEditingController();
    final currentCtrl = TextEditingController();
    DateTime? purchaseD;
    DateTime? insD;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add vehicle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: number,
                  decoration: const InputDecoration(labelText: 'Plate / number'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(type),
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Car / Bike'),
                  items: const [
                    DropdownMenuItem(value: 'car', child: Text('Car')),
                    DropdownMenuItem(value: 'bike', child: Text('Bike')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (x) => setSt(() => type = x ?? 'car'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Purchase date (optional)'),
                  subtitle: Text(
                    purchaseD != null
                        ? DateFormat.yMMMd().format(purchaseD!.toLocal())
                        : 'Tap to set',
                  ),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final x = await showDatePicker(
                      context: context,
                      initialDate: purchaseD ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (x != null) setSt(() => purchaseD = x);
                  },
                ),
                TextField(
                  controller: purchaseCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Purchase price (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Current value (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Insurance expiry (optional)'),
                  subtitle: Text(
                    insD != null
                        ? DateFormat.yMMMd().format(insD!.toLocal())
                        : 'Tap to set',
                  ),
                  trailing: const Icon(Icons.shield_outlined),
                  onTap: () async {
                    final x = await showDatePicker(
                      context: context,
                      initialDate: insD ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (x != null) setSt(() => insD = x);
                  },
                ),
                const SizedBox(height: 20),
                LedgerPrimaryGradientButton(
                  onPressed: () async {
                    if (name.text.trim().isEmpty || number.text.trim().isEmpty) {
                      return;
                    }
                    double? pp;
                    if (purchaseCtrl.text.trim().isEmpty) {
                      pp = null;
                    } else {
                      pp = double.tryParse(purchaseCtrl.text.replaceAll(',', ''));
                      if (pp == null) return;
                    }
                    double? cv;
                    if (currentCtrl.text.trim().isEmpty) {
                      cv = null;
                    } else {
                      cv = double.tryParse(currentCtrl.text.replaceAll(',', ''));
                      if (cv == null) return;
                    }
                    try {
                      await ref.read(vehiclesApiProvider).create(
                            name: name.text.trim(),
                            number: number.text.trim(),
                            vehicleType: type,
                            purchaseDate: purchaseD,
                            purchasePrice: pp,
                            currentValue: cv,
                            insuranceExpiryDate: insD,
                          );
                      ref.invalidate(vehiclesListProvider);
                      if (context.mounted) Navigator.pop(ctx);
                    } on DioException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(dioErrorMessage(e))),
                        );
                      }
                    }
                  },
                  child: const Text('Add Vehicle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleCostSheet {
  static void show(BuildContext context, WidgetRef ref, String vehicleId) {
    final type = TextEditingController(text: 'fuel');
    final amount = TextEditingController();
    DateTime d = DateTime.now();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: type,
                decoration: const InputDecoration(
                  labelText: 'Type (fuel, service…)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date ${d.toLocal().toString().split(' ').first}'),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final x = await showDatePicker(
                    context: context,
                    initialDate: d,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (x != null) setSt(() => d = x);
                },
              ),
              const SizedBox(height: 12),
              LedgerPrimaryGradientButton(
                onPressed: () async {
                  final a = double.tryParse(amount.text.trim());
                  if (a == null) return;
                  try {
                    await ref.read(vehiclesApiProvider).addCost(
                          vehicleId: vehicleId,
                          type: type.text.trim(),
                          amount: a,
                          dateIso: d.toUtc().toIso8601String(),
                        );
                    ref.invalidate(vehiclesListProvider);
                    if (context.mounted) Navigator.pop(ctx);
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(dioErrorMessage(e))),
                      );
                    }
                  }
                },
                child: const Text('Add cost'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
