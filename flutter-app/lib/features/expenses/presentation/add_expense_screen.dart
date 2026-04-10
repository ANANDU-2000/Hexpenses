import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../accounts/application/account_providers.dart';
import '../application/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.initialAccountId});

  final String? initialAccountId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _subId;
  String? _accountId;
  bool _saving = false;
  bool _taxable = false;
  String _taxScheme = 'gst_in';
  final _taxAmount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
  }

  @override
  void dispose() {
       _amount.dispose();
    _note.dispose();
    _taxAmount.dispose();
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
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick a category')));
      return;
    }
    if (_accountId == null || _accountId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pick an account')));
      return;
    }
    final amt = double.tryParse(_amount.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid amount required')));
      return;
    }
    double? taxAmt;
    if (_taxable) {
      taxAmt = double.tryParse(_taxAmount.text.trim().replaceAll(',', ''));
      if (taxAmt == null || taxAmt < 0 || taxAmt > amt) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid tax amount (0 … expense amount)')),
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final iso = _date.toUtc().toIso8601String();
      final cats = ref.read(categoriesProvider).value ?? const <Map<String, dynamic>>[];
      String? catName;
      for (final c in cats) {
        if (c['id']?.toString() == _categoryId) {
          catName = c['name']?.toString();
          break;
        }
      }
      await ref.read(ledgerSyncServiceProvider).createExpenseOffline(
            amount: amt,
            categoryId: _categoryId!,
            categoryName: catName,
            subCategoryId: _subId,
            dateIso: iso,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            accountId: _accountId,
            taxable: _taxable,
            taxScheme: _taxable ? _taxScheme : null,
            taxAmount: _taxable ? taxAmt : null,
          );
      await ref.read(ledgerSyncServiceProvider).pullAndFlush();
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
    final cats = ref.watch(categoriesProvider);
    final accs = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: cats.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Create a category in the API or app first.'));
          }
          Map<String, dynamic>? selected;
          for (final c in list) {
            if (c['id'] == _categoryId) selected = c;
          }
          final subs = (selected?['subCategoryRows'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

          return ListView(
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
                              .map((a) => DropdownMenuItem<String>(
                                    value: a['id']?.toString(),
                                    child: Text(
                                      '${a['name']?.toString() ?? ''} (${a['balance']?.toString() ?? '0'})',
                                    ),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _accountId = v),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('$e'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('cat-$_categoryId'),
                      decoration: const InputDecoration(labelText: 'Category'),
                      initialValue: _categoryId,
                      items: list
                          .map((c) => DropdownMenuItem<String>(
                                value: c['id']?.toString(),
                                child: Text(c['name']?.toString() ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() {
                        _categoryId = v;
                        _subId = null;
                      }),
                    ),
                    if (subs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        key: ValueKey('sub-$_subId'),
                        decoration: const InputDecoration(labelText: 'Subcategory (optional)'),
                        initialValue: _subId,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('None')),
                          ...subs.map((s) => DropdownMenuItem<String?>(
                                value: s['id']?.toString(),
                                child: Text(s['name']?.toString() ?? ''),
                              )),
                        ],
                        onChanged: (v) => setState(() => _subId = v),
                      ),
                    ],
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
                    TextField(controller: _note, decoration: const InputDecoration(labelText: 'Note')),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Taxable (GST / VAT)'),
                      subtitle: const Text('Track tax included in this expense'),
                      value: _taxable,
                      onChanged: (v) => setState(() => _taxable = v),
                    ),
                    if (_taxable) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_taxScheme),
                        initialValue: _taxScheme,
                        decoration: const InputDecoration(labelText: 'Tax type'),
                        items: const [
                          DropdownMenuItem(value: 'gst_in', child: Text('India GST')),
                          DropdownMenuItem(value: 'vat_ae', child: Text('UAE VAT')),
                        ],
                        onChanged: (v) => setState(() => _taxScheme = v ?? 'gst_in'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _taxAmount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Tax amount',
                          helperText: 'GST or VAT portion included in the amount above',
                        ),
                      ),
                    ],
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
