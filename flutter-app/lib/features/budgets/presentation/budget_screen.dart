import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../expenses/application/expense_providers.dart';
import '../application/budget_providers.dart';
import '../data/budgets_api.dart';

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
    var m = int.tryParse(parts.length > 1 ? parts[1] : '${DateTime.now().month}') ?? DateTime.now().month;
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

  Future<void> _openAdd() async {
    final cats = ref.read(categoriesProvider);
    await cats.when(
      data: (list) async {
        final expenseCats = list.where((c) => c['type']?.toString() == 'expense').toList();
        if (expenseCats.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create an expense category first.')),
            );
          }
          return;
        }
        String? catId = expenseCats.first['id']?.toString();
        final limitCtrl = TextEditingController(text: '200');
        final ok = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
              child: StatefulBuilder(
                builder: (context, setSt) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('New budget', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          key: ValueKey(catId),
                          decoration: const InputDecoration(labelText: 'Category'),
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
                          decoration: const InputDecoration(labelText: 'Monthly limit'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Month: $_monthKey',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 20),
                        LedgerPrimaryGradientButton(
                          onPressed: () => Navigator.pop(context, true),
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
        if (ok != true || catId == null) return;
        final lim = double.tryParse(limitCtrl.text.trim());
        if (lim == null || lim <= 0) return;
        try {
          await ref.read(budgetsApiProvider).create(
            categoryId: catId!,
            limit: lim,
            month: _monthKey,
          );
          await ref.read(ledgerSyncServiceProvider).pullBudgetsForMonth(_monthKey);
        } on DioException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.response?.data?.toString() ?? e.message ?? 'Failed')),
            );
          }
        }
      },
      loading: () async {},
      error: (_, _) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(budgetsForMonthProvider(_monthKey));

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _shiftMonth(-1),
          ),
          Center(
            child: Text(
              _monthKey,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _shiftMonth(1),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () async {
          await ref.read(ledgerSyncServiceProvider).pullBudgetsForMonth(_monthKey);
        },
        child: async.when(
          data: (rows) {
            if (rows.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'No budgets for this month. Tap + to add a limit per category.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final name = r['categoryName']?.toString() ?? '';
                final limit = double.tryParse(r['limit']?.toString() ?? '0') ?? 0;
                final spent = double.tryParse(r['spent']?.toString() ?? '0') ?? 0;
                final exceeded = r['exceeded'] == true;
                final pctUsed = double.tryParse(r['percentUsed']?.toString() ?? '0') ?? 0;
                final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                final barColor = exceeded ? cs.error : cs.primary;
                final id = r['id']?.toString() ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LedgerActionLayer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            if (exceeded)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: cs.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Over budget',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.error,
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: cs.onSurface.withValues(alpha: 0.45)),
                              onPressed: id.isEmpty
                                  ? null
                                  : () async {
                                      try {
                                        await ref.read(budgetsApiProvider).delete(id);
                                        await ref.read(ledgerSyncServiceProvider).pullBudgetsForMonth(_monthKey);
                                      } on DioException catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${e.message}')),
                                          );
                                        }
                                      }
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress > 0 ? progress : null,
                            minHeight: 10,
                            backgroundColor: cs.surfaceContainerHighest,
                            color: barColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Spent ${spent.toStringAsFixed(2)} / ${limit.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.75),
                                  ),
                            ),
                            Text(
                              '${pctUsed.toStringAsFixed(0)}%',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: exceeded ? cs.error : cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('$e'))),
        ),
      ),
      floatingActionButton: LedgerFab(
        tooltip: 'Add budget',
        onPressed: _openAdd,
        icon: Icons.add,
      ),
    );
  }
}
