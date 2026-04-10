import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../expenses/presentation/expense_list_screen.dart';
import '../application/account_providers.dart';
import '../data/accounts_api.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  static const _types = ['bank', 'cash', 'credit'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_outlined),
            tooltip: 'Transfer',
            onPressed: () => _openTransfer(context, ref),
          ),
        ],
      ),
      body: async.when(
        data: (ledger) {
          final list = ledger.accounts;
          final sum = ledger.summary;
          final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 2);
          if (list.isEmpty) {            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No accounts yet', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    LedgerPrimaryGradientButton(
                      onPressed: () => _openAddAccount(context, ref),
                      child: const Text('Add account'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: cs.primary,
            onRefresh: () async {
              await ref.read(ledgerSyncServiceProvider).pullAndFlush();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              children: [
                if (sum.isNotEmpty) ...[
                  LedgerSectionLayer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Workspace balances',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _BalanceMini(
                                label: 'Bank & cash',
                                value: fmt.format(double.tryParse(sum['totalBankAndCash']?.toString() ?? '0') ?? 0),
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _BalanceMini(
                                label: 'Credit cards',
                                value: fmt.format(double.tryParse(sum['totalCreditCardDebt']?.toString() ?? '0') ?? 0),
                                color: cs.error.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net liquid',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              Text(
                                fmt.format(double.tryParse(sum['netLiquid']?.toString() ?? '0') ?? 0),
                                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 16, color: cs.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...list.map((a) {                  final id = a['id']?.toString() ?? '';
                  final name = a['name']?.toString() ?? '';
                  final type = a['type']?.toString() ?? '';
                  final bal = a['balance']?.toString() ?? '0';
                  return LedgerStaggerItem(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: Theme.of(context).textTheme.titleSmall),
                                  const SizedBox(height: 4),
                                  Text(
                                    type.toUpperCase(),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: cs.onSurface.withValues(alpha: 0.5),
                                          letterSpacing: 0.8,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              bal,
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ExpenseListScreen(accountId: id, accountName: name),
                                  ),
                                );
                              },
                              child: const Text('Expenses'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('$e'))),
      ),
      floatingActionButton: LedgerFab(
        tooltip: 'Add account',
        onPressed: () => _openAddAccount(context, ref),
        icon: Icons.add,
      ),
    );
  }

  void _openAddAccount(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    var type = 'bank';
    final initial = TextEditingController(text: '0');
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New account', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(type),
                decoration: const InputDecoration(labelText: 'Type'),
                initialValue: type,
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setSt(() => type = v ?? 'bank'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: initial,
                decoration: const InputDecoration(labelText: 'Starting balance'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 20),
              LedgerPrimaryGradientButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  final ib = double.tryParse(initial.text.trim());
                  try {
                    await ref.read(accountsApiProvider).create(
                      name: name.text.trim(),
                      type: type,
                      initialBalance: ib,
                    );
                    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
                    if (context.mounted) Navigator.pop(context);
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTransfer(BuildContext context, WidgetRef ref) {
    final accounts = ref.read(accountsProvider).valueOrNull?.accounts ?? [];
    if (accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create at least two accounts to transfer')),
      );
      return;
    }
    String? fromId = accounts.first['id']?.toString();
    String? toId = accounts[1]['id']?.toString();
    final amount = TextEditingController();
    final note = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Transfer', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('from-$fromId'),
                decoration: const InputDecoration(labelText: 'From'),
                initialValue: fromId,
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a['id']?.toString(),
                          child: Text(a['name']?.toString() ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setSt(() => fromId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('to-$toId'),
                decoration: const InputDecoration(labelText: 'To'),
                initialValue: toId,
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a['id']?.toString(),
                          child: Text(a['name']?.toString() ?? ''),
                        ))
                    .toList(),
                onChanged: (v) => setSt(() => toId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)')),
              const SizedBox(height: 20),
              LedgerPrimaryGradientButton(
                onPressed: () async {
                  final a = double.tryParse(amount.text.trim());
                  if (fromId == null || toId == null || a == null || a <= 0) return;
                  if (fromId == toId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Choose different accounts')),
                    );
                    return;
                  }
                  try {
                    await ref.read(accountsApiProvider).transfer(
                          fromAccountId: fromId!,
                          toAccountId: toId!,
                          amount: a,
                          note: note.text.trim().isEmpty ? null : note.text.trim(),
                        );
                    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
                    if (context.mounted) Navigator.pop(context);
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
                    }
                  }
                },
                child: const Text('Transfer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceMini extends StatelessWidget {
  const _BalanceMini({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 13, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
