import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/dio_errors.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../application/investment_providers.dart';
import '../data/investments_api.dart';

const _profitGreen = Color(0xFF0D9F6E);
const _lossRose = Color(0xFFE11D48);

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
    final async = ref.watch(investmentPortfolioProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Investments')),
      body: async.when(
        data: (data) {
          final summaryRaw = data['summary'];
          final summary = summaryRaw is Map ? Map<String, dynamic>.from(summaryRaw) : <String, dynamic>{};
          final holdingsRaw = data['holdings'];
          final holdings = holdingsRaw is List
              ? holdingsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : <Map<String, dynamic>>[];

          final totalInv = _toDouble(summary['totalInvested']);
          final totalCur = _toDouble(summary['totalCurrentValue']);
          final pnl = _toDouble(summary['profitLoss']);
          final pnlPct = _toDouble(summary['profitLossPercent']);

          return RefreshIndicator(
            color: cs.primary,
            onRefresh: () async {
              ref.invalidate(investmentPortfolioProvider);
              await ref.read(investmentPortfolioProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                LedgerSectionLayer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Portfolio',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              label: 'Invested',
                              value: fmt.format(totalInv),
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SummaryTile(
                              label: 'Current value',
                              value: fmt.format(totalCur),
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profit / loss',
                                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                          color: cs.onSurface.withValues(alpha: 0.55),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fmt.format(pnl),
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: pnl >= 0 ? _profitGreen : _lossRose,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${pnl >= 0 ? '+' : ''}${pnlPct.toStringAsFixed(1)}%',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: pnl >= 0 ? _profitGreen : _lossRose,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (holdings.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      'No holdings yet. Add stocks, SIPs, or crypto manually.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                  )
                else
                  ...holdings.map((h) {
                    final name = h['name']?.toString() ?? '';
                    final kind = h['kind']?.toString() ?? 'other';
                    final cur = _toDouble(h['currentValue']);
                    final rowPnl = _toDouble(h['profitLoss']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LedgerStaggerItem(
                        child: InkWell(
                          onTap: () => _editHolding(context, ref, h),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: Theme.of(context).textTheme.titleSmall),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Chip(
                                            label: Text(_kindLabel(kind)),
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            labelStyle: Theme.of(context).textTheme.labelSmall,
                                          ),
                                          Text(
                                            fmt.format(cur),
                                            style: GoogleFonts.manrope(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  rowPnl >= 0 ? '+${fmt.format(rowPnl)}' : fmt.format(rowPnl),
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: rowPnl >= 0 ? _profitGreen : _lossRose,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: LedgerFab(
        tooltip: 'Add holding',
        onPressed: () => _addHolding(context, ref),
        icon: Icons.add,
      ),
    );
  }

  void _addHolding(BuildContext context, WidgetRef ref) {
    _showHoldingSheet(context, ref, null);
  }

  void _editHolding(BuildContext context, WidgetRef ref, Map<String, dynamic> h) {
    _showHoldingSheet(context, ref, h);
  }

  void _showHoldingSheet(BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final invested = TextEditingController(
      text: existing != null ? _toDouble(existing['investedAmount']).toString() : '',
    );
    final current = TextEditingController(
      text: existing != null ? _toDouble(existing['currentValue']).toString() : '',
    );
    final note = TextEditingController(text: existing?['note']?.toString() ?? '');
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
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(kind),
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'stock', child: Text('Stock')),
                  DropdownMenuItem(value: 'sip', child: Text('SIP / mutual fund')),
                  DropdownMenuItem(value: 'crypto', child: Text('Crypto')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setSt(() => kind = v ?? 'stock'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: invested,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount invested (cost basis)',
                  helperText: 'Total you put in',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: current,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  final inv = double.tryParse(invested.text.replaceAll(',', ''));
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
                        note: note.text.trim().isEmpty ? null : note.text.trim(),
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
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
                      await ref.read(investmentsApiProvider).delete(existing['id']!.toString());
                      ref.invalidate(investmentPortfolioProvider);
                    } on DioException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
                      }
                    }
                  },
                  child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
