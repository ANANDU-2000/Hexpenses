import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/ledger_ui.dart';
import '../application/vehicle_providers.dart';
import '../data/vehicles_api.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(vehiclesListProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Vehicles')),
      body: async.when(
        data: (list) => RefreshIndicator(
          color: cs.primary,
          onRefresh: () async {
            ref.invalidate(vehiclesListProvider);
            await ref.read(vehiclesListProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final v = list[i];
              final id = v['id']?.toString() ?? '';
              final name = v['name']?.toString() ?? '';
              final number = v['number']?.toString() ?? '';
              return LedgerStaggerItem(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            number,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.55),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: cs.primary.withValues(alpha: 0.85)),
                      onPressed: () => _addCost(context, ref, id),
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
        tooltip: 'Add vehicle',
        onPressed: () => _addVehicle(context, ref),
        icon: Icons.add,
      ),
    );
  }

  void _addVehicle(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final number = TextEditingController();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: number, decoration: const InputDecoration(labelText: 'Plate / number')),
            const SizedBox(height: 20),
            LedgerPrimaryGradientButton(
              onPressed: () async {
                if (name.text.trim().isEmpty || number.text.trim().isEmpty) return;
                try {
                  await ref.read(vehiclesApiProvider).create(name: name.text.trim(), number: number.text.trim());
                  ref.invalidate(vehiclesListProvider);
                  if (context.mounted) Navigator.pop(context);
                } on DioException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              child: const Text('Add vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  void _addCost(BuildContext context, WidgetRef ref, String vehicleId) {
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
              TextField(controller: type, decoration: const InputDecoration(labelText: 'Type (fuel, service…)')),
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
                    if (context.mounted) Navigator.pop(context);
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
