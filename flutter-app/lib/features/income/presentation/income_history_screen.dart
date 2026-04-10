import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/dio_errors.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../accounts/application/account_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/income_providers.dart';
import '../data/incomes_api.dart';

class IncomeHistoryScreen extends ConsumerWidget {
  const IncomeHistoryScreen({super.key});

  static String _sourceLabel(String s) {
    if (s.isEmpty) return s;
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
    final async = ref.watch(incomesProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Income history')),
      body: async.when(
        data: (list) => RefreshIndicator(
          color: cs.primary,
          onRefresh: () async {
            ref.invalidate(incomesProvider);
            await ref.read(incomesProvider.future);
          },
          child: list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      'No income entries yet.\nUse Add income to record salary or other inflows.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final row = list[i];
                    final amt = double.tryParse(row['amount']?.toString() ?? '') ?? 0;
                    final src = row['source']?.toString() ?? '';
                    final date = row['date']?.toString().split('T').first ?? '';
                    final note = row['note']?.toString();
                    final acc = row['account'] is Map ? Map<String, dynamic>.from(row['account'] as Map) : null;
                    final accName = acc?['name']?.toString() ?? '';
                    final id = row['id']?.toString() ?? '';
                    return LedgerStaggerItem(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_sourceLabel(src), style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(
                                  '$date · $accName',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                ),
                                if (note != null && note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      note,
                                      style: Theme.of(context).textTheme.bodySmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                fmt.format(amt),
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: const Color(0xFF0D9F6E),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete income?'),
                                      content: const Text('This reverses the credit on the linked account.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok != true || !context.mounted) return;
                                  try {
                                    await ref.read(incomesApiProvider).delete(id);
                                    ref.invalidate(incomesProvider);
                                    ref.invalidate(accountsProvider);
                                    ref.invalidate(monthlySummaryProvider);
                                  } on DioException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(dioErrorMessage(e))),
                                      );
                                    }
                                  }
                                },
                                child: Text('Delete', style: TextStyle(color: cs.error, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('$e'))),
      ),
    );
  }
}
