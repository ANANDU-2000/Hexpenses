import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/ledger_ui.dart';
import '../../expenses/application/expense_providers.dart';
import '../application/recurring_providers.dart';
import '../data/recurring_api.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  static const _freqs = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(recurringListProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: list.when(
        data: (rows) {
          if (rows.isEmpty) {
            return Center(child: Text('No recurring expenses', style: Theme.of(context).textTheme.titleMedium));
          }
          return RefreshIndicator(
            color: cs.primary,
            onRefresh: () async {
              ref.invalidate(recurringListProvider);
              await ref.read(recurringListProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final title = r['title']?.toString() ?? '';
                final amt = r['amount']?.toString() ?? '';
                final freq = r['frequency']?.toString() ?? '';
                final next = r['nextDate']?.toString() ?? '';
                return LedgerStaggerItem(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              '$freq · next $next',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        amt,
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 16, color: cs.onSurface),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: LedgerFab(
        tooltip: 'Add recurring',
        onPressed: () => _openForm(context, ref),
        icon: Icons.add,
      ),
    );
  }

  void _openForm(BuildContext context, WidgetRef ref) {
    final amount = TextEditingController();
    final title = TextEditingController();
    final note = TextEditingController();
    var freq = 'monthly';
    DateTime next = DateTime.now();
    String? categoryId;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Consumer(
            builder: (context, ref, _) {
              final cats = ref.watch(categoriesProvider);
              return StatefulBuilder(
                builder: (context, setSt) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('New recurring', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          cats.when(
                            data: (list) => DropdownButtonFormField<String>(
                              key: ValueKey('rcat-$categoryId'),
                              decoration: const InputDecoration(labelText: 'Category'),
                              initialValue: categoryId,
                              items: list
                                  .map((c) => DropdownMenuItem(
                                        value: c['id']?.toString(),
                                        child: Text(c['name']?.toString() ?? ''),
                                      ))
                                  .toList(),
                              onChanged: (v) => setSt(() => categoryId = v),
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('$e'),
                          ),
                          const SizedBox(height: 12),
                          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                          const SizedBox(height: 12),
                          TextField(
                            controller: amount,
                            decoration: const InputDecoration(labelText: 'Amount'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(freq),
                            decoration: const InputDecoration(labelText: 'Frequency'),
                            initialValue: freq,
                            items: _freqs.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                            onChanged: (v) => setSt(() => freq = v ?? 'monthly'),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Next: ${next.toLocal().toString().split(' ').first}'),
                            trailing: const Icon(Icons.calendar_today_outlined),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: next,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                              );
                              if (d != null) setSt(() => next = d);
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
                          const SizedBox(height: 20),
                          LedgerPrimaryGradientButton(
                            onPressed: () async {
                              if (categoryId == null) return;
                              final a = double.tryParse(amount.text.trim());
                              if (a == null || a <= 0) return;
                              try {
                                await ref.read(recurringApiProvider).create(
                                      amount: a,
                                      frequency: freq,
                                      nextDateIso: next.toUtc().toIso8601String(),
                                      categoryId: categoryId!,
                                      title: title.text.trim().isEmpty ? 'Recurring' : title.text.trim(),
                                      note: note.text.trim().isEmpty ? null : note.text.trim(),
                                    );
                                ref.invalidate(recurringListProvider);
                                if (context.mounted) Navigator.pop(context);
                              } on DioException catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              }
                            },
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
