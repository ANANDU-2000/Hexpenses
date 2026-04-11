import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/ledger_ui.dart';
import '../application/insurance_providers.dart';
import '../data/insurance_api.dart';

class InsuranceScreen extends ConsumerWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(insuranceListProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Insurance')),
      body: async.when(
        data: (list) => RefreshIndicator(
          color: cs.primary,
          onRefresh: () async {
            ref.invalidate(insuranceListProvider);
            await ref.read(insuranceListProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final p = list[i];
              return LedgerStaggerItem(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name']?.toString() ?? '',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Expires ${p['expiryDate']?.toString().split('T').first ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      p['premium']?.toString() ?? '',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      floatingActionButton: LedgerFab(
        tooltip: 'Add policy',
        onPressed: () => _add(context, ref),
        icon: Icons.add,
      ),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final type = TextEditingController(text: 'health');
    final premium = TextEditingController();
    DateTime start = DateTime.now();
    DateTime end = DateTime.now().add(const Duration(days: 365));

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
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Policy name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: type,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: premium,
                decoration: const InputDecoration(labelText: 'Premium'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Start ${start.toLocal().toString().split(' ').first}',
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: start,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2040),
                  );
                  if (d != null) setSt(() => start = d);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Expiry ${end.toLocal().toString().split(' ').first}',
                ),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: end,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2040),
                  );
                  if (d != null) setSt(() => end = d);
                },
              ),
              const SizedBox(height: 12),
              LedgerPrimaryGradientButton(
                onPressed: () async {
                  final pr = double.tryParse(premium.text.trim());
                  if (pr == null || name.text.trim().isEmpty) return;
                  try {
                    await ref
                        .read(insuranceApiProvider)
                        .create(
                          name: name.text.trim(),
                          type: type.text.trim(),
                          premium: pr,
                          startDate: start.toUtc().toIso8601String(),
                          expiryDate: end.toUtc().toIso8601String(),
                        );
                    ref.invalidate(insuranceListProvider);
                    if (context.mounted) Navigator.pop(context);
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
