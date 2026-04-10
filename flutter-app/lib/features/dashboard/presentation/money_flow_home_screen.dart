import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/app_skeleton.dart';
import '../../../core/design_system/transaction_tile.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/providers.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../expenses/application/expense_providers.dart';
import '../../expenses/presentation/add_expense_screen.dart';
import '../../income/presentation/add_income_screen.dart';
import '../../insights/application/insights_providers.dart';
import '../../whatsapp/application/whatsapp_status_provider.dart';
import '../../whatsapp/presentation/whatsapp_connect_screen.dart';
import '../application/dashboard_providers.dart';

String _greetingFirstName(WidgetRef ref) {
  final email = ref.read(tokenStorageProvider).userEmail;
  if (email == null || email.isEmpty) return 'there';
  final local = email.split('@').first;
  if (local.isEmpty) return 'there';
  return local[0].toUpperCase() + local.substring(1);
}

String _monthShortLabel(String key) {
  final p = key.split('-');
  if (p.length < 2) return key;
  final mi = int.tryParse(p[1]) ?? 1;
  const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return names[(mi - 1).clamp(0, 11)];
}

/// Premium home: greeting, balance, quick actions, chart, AI insight, recent tx + WhatsApp.
class MoneyFlowHomeScreen extends ConsumerWidget {
  const MoneyFlowHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final overview = ref.watch(dashboardOverviewProvider);
    final expenses = ref.watch(expensesProvider);
    final insights = ref.watch(aiInsightsProvider);
    final wa = ref.watch(whatsappLinkStatusProvider);
    final name = _greetingFirstName(ref);

    Future<void> refresh() async {
      unawaited(ref.read(ledgerSyncServiceProvider).pullAndFlush());
      ref.invalidate(dashboardOverviewProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(categoryBreakdownProvider);
      ref.invalidate(expensesProvider);
      ref.invalidate(aiInsightsProvider);
      ref.invalidate(whatsappLinkStatusProvider);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () async {
          await refresh();
          await ref.read(dashboardOverviewProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(MfSpace.xxl, MfSpace.xl, MfSpace.xxl, MfSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello $name',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: MfSpace.xs),
                      Text(
                        'Here is your MoneyFlow overview',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: MfSpace.xxl),
                      overview.when(
                        data: (dash) {
                          final nw = dash['netWorth'];
                          final nwMap = nw is Map ? Map<String, dynamic>.from(nw) : <String, dynamic>{};
                          final raw = nwMap['netWorth'];
                          final balance = raw?.toString() ?? '—';
                          final label = nwMap['label']?.toString() ?? 'Total balance';
                          return _BalanceHighlight(label: label, balance: balance, cs: cs);
                        },
                        loading: () => const DashboardHeaderSkeleton(),
                        error: (Object? error, StackTrace stackTrace) => AppCard(
                          glass: true,
                          child: Text(
                            'Could not load balance',
                            style: GoogleFonts.inter(color: cs.error),
                          ),
                        ),
                      ),
                      const SizedBox(height: MfSpace.xxl),
                      const _QuickActions(),
                      const SizedBox(height: MfSpace.xxl),
                      overview.when(
                        data: (dash) {
                          final trendRaw = dash['savingsTrend'];
                          final trend = trendRaw is List
                              ? trendRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
                              : <Map<String, dynamic>>[];
                          if (trend.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Income vs expenses', style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: MfSpace.sm),
                              Text(
                                'Last ${trend.length} months',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: MfSpace.lg),
                              SizedBox(
                                height: 220,
                                child: _TrendBarChart(trend: trend, cs: cs),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox(
                          height: 220,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (Object? error, StackTrace stackTrace) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: MfSpace.xxl),
                      insights.when(
                        data: (payload) {
                          final text = payload.monthlyFinancialSummary.trim();
                          if (text.isEmpty) return const SizedBox.shrink();
                          return _AiInsightCard(text: text, cs: cs);
                        },
                        loading: () => AppCard(
                          glass: true,
                          padding: const EdgeInsets.all(MfSpace.xl),
                          child: SizedBox(
                            height: 72,
                            child: AppSkeleton(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(MfRadius.sm),
                                ),
                              ),
                            ),
                          ),
                        ),
                        error: (Object? error, StackTrace stackTrace) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: MfSpace.xxl),
                      Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: MfSpace.md),
                    ],
                  ),
                ),
              ),
            ),
            expenses.when(
              data: (list) {
                final recent = list.take(6).toList();
                if (recent.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: MfSpace.xxl),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No transactions yet', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: MfSpace.sm),
                            Text(
                              'Add an expense or income to see it here.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                            ),
                            const SizedBox(height: MfSpace.lg),
                            AppButton(
                              label: 'Add expense',
                              icon: Icons.add_rounded,
                              onPressed: () {
                                Navigator.of(context).push(
                                  LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 0, MfSpace.xxl, MfSpace.sm),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final e = recent[i];
                        final cat = (e['category'] is Map) ? (e['category'] as Map)['name']?.toString() ?? '' : '';
                        final amt = e['amount']?.toString() ?? '0';
                        final id = e['id']?.toString() ?? '';
                        final letter = cat.isNotEmpty ? cat.substring(0, 1).toUpperCase() : '?';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: MfSpace.md),
                          child: TransactionTile(
                            title: cat.isEmpty ? 'Expense' : cat,
                            subtitle: e['note']?.toString().trim().isNotEmpty == true
                                ? e['note'].toString()
                                : (e['date']?.toString() ?? ''),
                            amountLabel: '-$amt',
                            leadingLabel: letter,
                            isExpense: true,
                            animationIndex: i,
                            endAction: IconButton(
                              icon: Icon(Icons.delete_outline, color: cs.onSurface.withValues(alpha: 0.4)),
                              onPressed: () async {
                                try {
                                  await ref.read(ledgerSyncServiceProvider).deleteExpenseOffline(id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Removed'), behavior: SnackBarBehavior.floating),
                                    );
                                  }
                                } catch (_) {}
                              },
                            ),
                          ),
                        );
                      },
                      childCount: recent.length,
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: MfSpace.xxl),
                  child: const TransactionListSkeleton(count: 4),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: MfSpace.xxl),
                child: Text('$e'),
              )),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(MfSpace.xxl, MfSpace.lg, MfSpace.xxl, MfSpace.sm),
                child: wa.when(
                  data: (raw) {
                    if (raw == null) return const SizedBox.shrink();
                    final connected = raw['verified'] == true || raw['connected'] == true;
                    return AppCard(
                      glass: true,
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(builder: (_) => const WhatsappConnectScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(MfSpace.md),
                            decoration: BoxDecoration(
                              color: const Color(0xFF128C7E).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(MfRadius.sm),
                            ),
                            child: const Icon(Icons.chat_rounded, color: Color(0xFF128C7E)),
                          ),
                          const SizedBox(width: MfSpace.lg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connect WhatsApp',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                                const SizedBox(height: MfSpace.xs),
                                Text(
                                  connected ? 'Connected' : 'Not connected',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: connected ? MfPalette.success : cs.onSurface.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.35)),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (Object? error, StackTrace stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _BalanceHighlight extends StatelessWidget {
  const _BalanceHighlight({required this.label, required this.balance, required this.cs});

  final String label;
  final String balance;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(MfSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: MfSpace.md),
          Text(
            balance,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: MfSpace.lg),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Add expense',
                icon: Icons.remove_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  Navigator.of(context).push(
                    LedgerPageRoutes.fadeSlide<void>(const AddExpenseScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: MfSpace.md),
            Expanded(
              child: AppButton(
                label: 'Add income',
                icon: Icons.add_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).push(
                    LedgerPageRoutes.fadeSlide<void>(const AddIncomeScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.text, required this.cs});

  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MfRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.92),
            cs.primaryContainer.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(MfSpace.xxl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(MfSpace.sm + 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(MfRadius.sm),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: MfSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI insight',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: MfSpace.sm),
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.95),
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

class _TrendBarChart extends StatelessWidget {
  const _TrendBarChart({required this.trend, required this.cs});

  final List<Map<String, dynamic>> trend;
  final ColorScheme cs;

  double _inc(Map<String, dynamic> e) =>
      double.tryParse(e['income']?.toString() ?? '0') ?? 0;

  double _exp(Map<String, dynamic> e) {
    final v = e['expenses'] ?? e['expense'];
    return double.tryParse(v?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    const incomeColor = Color(0xFF10B981);
    const expenseColor = Color(0xFFE11D48);
    var maxY = 0.0;
    for (final e in trend) {
      final a = _inc(e);
      final b = _exp(e);
      if (a > maxY) maxY = a;
      if (b > maxY) maxY = b;
    }
    final cap = maxY <= 0 ? 100.0 : maxY * 1.15;

    return BarChart(
      BarChartData(
        maxY: cap,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: cap / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: cs.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, m) => Text(
                v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                final key = trend[i]['month']?.toString() ?? '';
                final short = _monthShortLabel(key);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    short,
                    style: GoogleFonts.inter(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < trend.length; i++)
            BarChartGroupData(
              x: i,
              groupVertically: false,
              barsSpace: 6,
              barRods: [
                BarChartRodData(
                  fromY: 0,
                  toY: _inc(trend[i]),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: incomeColor,
                ),
                BarChartRodData(
                  fromY: 0,
                  toY: _exp(trend[i]),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: expenseColor,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
