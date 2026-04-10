import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dio_errors.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../accounts/application/account_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/income_providers.dart';
import '../data/incomes_api.dart';

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key, this.initialAccountId});

  final String? initialAccountId;

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  static const _sources = ['salary', 'business', 'other'];

  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  String _source = 'salary';
  String? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (_accountId == null || _accountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick an account')));
      return;
    }
    final amt = double.tryParse(_amount.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid amount required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final iso = _date.toUtc().toIso8601String();
      await ref.read(incomesApiProvider).create(
            amount: amt,
            source: _source,
            dateIso: iso,
            accountId: _accountId!,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      ref.invalidate(incomesProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(monthlySummaryProvider);
      if (mounted) Navigator.of(context).pop();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dioErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accs = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add income')),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LedgerActionLayer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                accs.when(
                  data: (ledger) {
                    final accounts = ledger.accounts;
                    if (accounts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Add an account under Profile → Accounts first.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      );
                    }
                    final accVal = _accountId != null &&
                            accounts.any((a) => a['id']?.toString() == _accountId)
                        ? _accountId
                        : null;
                    return DropdownButtonFormField<String>(
                      key: ValueKey('acc-$accVal'),
                      decoration: const InputDecoration(labelText: 'Account'),
                      initialValue: accVal,
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem<String>(
                              value: a['id']?.toString(),
                              child: Text(
                                '${a['name']?.toString() ?? ''} (${a['balance']?.toString() ?? '0'})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _accountId = v),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_source),
                  decoration: const InputDecoration(labelText: 'Source'),
                  initialValue: _source,
                  items: _sources
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s,
                          child: Text(s[0].toUpperCase() + s.substring(1)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _source = v ?? 'salary'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Date: ${_date.toLocal().toString().split(' ').first}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          Icon(Icons.calendar_today_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note (optional)')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LedgerPrimaryGradientButton(
            onPressed: _save,
            loading: _saving,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
