import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/dio_errors.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../accounts/application/account_providers.dart';
import '../application/expense_providers.dart';
import '../data/categories_api.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.initialAccountId});

  final String? initialAccountId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _taxAmount = TextEditingController();

  DateTime _date = DateTime.now();
  String? _categoryId;
  String? _subId;
  String? _accountId;
  bool _saving = false;
  bool _taxable = false;
  String _taxScheme = 'gst_in';

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

  void _showSnack(
    String message, {
    IconData icon = Icons.info_outline_rounded,
  }) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(icon, size: 18, color: cs.onInverseSurface),
            const SizedBox(width: MfSpace.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _createCategory(
    String name, {
    bool announce = true,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _showSnack(
        'Enter a category name first.',
        icon: Icons.label_outline_rounded,
      );
      return <String, dynamic>{};
    }

    try {
      final created = await ref
          .read(categoriesApiProvider)
          .createCategory(trimmed);
      ref.invalidate(categoriesProvider);
      if (announce) {
        _showSnack(
          'Category added successfully.',
          icon: Icons.check_circle_outline_rounded,
        );
      }
      return created;
    } on DioException catch (e) {
      _showSnack(dioErrorMessage(e), icon: Icons.error_outline_rounded);
      rethrow;
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    var creating = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add category'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  hintText: 'e.g. Groceries',
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  if (creating) return;
                  final created = await _createCategory(
                    controller.text,
                    announce: false,
                  );
                  if (!mounted || created.isEmpty) return;
                  setState(() {
                    _categoryId = created['id']?.toString() ?? _categoryId;
                    _subId = null;
                  });
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  _showSnack(
                    'Category added successfully.',
                    icon: Icons.check_circle_outline_rounded,
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: creating
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: creating
                      ? null
                      : () async {
                          setDialogState(() => creating = true);
                          try {
                            final created = await _createCategory(
                              controller.text,
                              announce: false,
                            );
                            if (!mounted || created.isEmpty) return;
                            setState(() {
                              _categoryId =
                                  created['id']?.toString() ?? _categoryId;
                              _subId = null;
                            });
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            _showSnack(
                              'Category added successfully.',
                              icon: Icons.check_circle_outline_rounded,
                            );
                          } catch (_) {
                            if (dialogContext.mounted) {
                              setDialogState(() => creating = false);
                            }
                          }
                        },
                  child: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add category'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (_categoryId == null) {
      _showSnack(
        'Pick a category before saving.',
        icon: Icons.category_outlined,
      );
      return;
    }
    if (_accountId == null || _accountId!.isEmpty) {
      _showSnack(
        'Pick an account before saving.',
        icon: Icons.account_balance_wallet_outlined,
      );
      return;
    }

    final amt = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amt == null || amt <= 0) {
      _showSnack(
        'Enter a valid expense amount.',
        icon: Icons.currency_rupee_rounded,
      );
      return;
    }

    double? taxAmt;
    if (_taxable) {
      taxAmt = double.tryParse(_taxAmount.text.trim().replaceAll(',', ''));
      if (taxAmt == null || taxAmt < 0 || taxAmt > amt) {
        _showSnack(
          'Enter a valid tax amount between 0 and the expense amount.',
          icon: Icons.receipt_long_outlined,
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final iso = _date.toUtc().toIso8601String();
      final cats =
          ref.read(categoriesProvider).value ?? const <Map<String, dynamic>>[];
      String? catName;
      for (final c in cats) {
        if (c['id']?.toString() == _categoryId) {
          catName = c['name']?.toString();
          break;
        }
      }
      await ref
          .read(ledgerSyncServiceProvider)
          .createExpenseOffline(
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
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      _showSnack(dioErrorMessage(e), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cats = ref.watch(categoriesProvider);
    final accs = ref.watch(accountsProvider);
    final today = DateTime.now();
    final isToday =
        _date.year == today.year &&
        _date.month == today.month &&
        _date.day == today.day;

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      backgroundColor: cs.surface,
      body: SafeArea(
        top: false,
        child: cats.when(
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(MfSpace.lg),
                children: [
                  LedgerActionLayer(
                    padding: const EdgeInsets.all(MfSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'No categories yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: MfSpace.sm),
                        Text(
                          'Create your first expense category to continue.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: MfSpace.md),
                        _InlineCategoryCreator(
                          onCreated: (name) async {
                            final created = await _createCategory(name);
                            if (!mounted || created.isEmpty) return;
                            setState(() {
                              _categoryId =
                                  created['id']?.toString() ?? _categoryId;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            Map<String, dynamic>? selected;
            for (final c in list) {
              if (c['id']?.toString() == _categoryId) {
                selected = c;
              }
            }

            final subs =
                (selected?['subCategoryRows'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];

            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(MfSpace.lg),
              children: [
                LedgerActionLayer(
                  padding: const EdgeInsets.all(MfSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      accs.when(
                        data: (ledger) {
                          final accounts = ledger.accounts;
                          if (accounts.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: MfSpace.md,
                              ),
                              child: Text(
                                'Add an account under Profile -> Accounts first.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: cs.error),
                              ),
                            );
                          }

                          final accVal =
                              _accountId != null &&
                                  accounts.any(
                                    (a) => a['id']?.toString() == _accountId,
                                  )
                              ? _accountId
                              : null;

                          return DropdownButtonFormField<String>(
                            key: ValueKey('acc-$accVal'),
                            initialValue: accVal,
                            borderRadius: BorderRadius.circular(12),
                            decoration: const InputDecoration(
                              labelText: 'Account',
                            ),
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
                        error: (e, _) => Text(
                          'Something went wrong. Please try refreshing.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: cs.error),
                        ),
                      ),
                      const SizedBox(height: MfSpace.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Category',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Add category',
                            onPressed: _showAddCategoryDialog,
                            icon: Icon(
                              Icons.add_circle_outline_rounded,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: MfSpace.xs),
                      DropdownButtonFormField<String>(
                        key: ValueKey('cat-$_categoryId'),
                        initialValue: _categoryId,
                        borderRadius: BorderRadius.circular(12),
                        decoration: const InputDecoration(
                          hintText: 'Choose a category',
                        ),
                        items: list
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c['id']?.toString(),
                                child: Text(c['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _categoryId = v;
                          _subId = null;
                        }),
                      ),
                      if (subs.isNotEmpty) ...[
                        const SizedBox(height: MfSpace.md),
                        DropdownButtonFormField<String?>(
                          key: ValueKey('sub-$_subId'),
                          initialValue: _subId,
                          borderRadius: BorderRadius.circular(12),
                          decoration: const InputDecoration(
                            labelText: 'Subcategory (optional)',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('None'),
                            ),
                            ...subs.map(
                              (s) => DropdownMenuItem<String?>(
                                value: s['id']?.toString(),
                                child: Text(s['name']?.toString() ?? ''),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() => _subId = v),
                        ),
                      ],
                      const SizedBox(height: MfSpace.md),
                      TextField(
                        controller: _amount,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '${MfCurrency.symbol} ',
                          prefixStyle: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: MfSpace.md),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                size: 18,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  DateFormat('EEEE, d MMM yyyy').format(_date),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              if (isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: MfSpace.md),
                      TextField(
                        controller: _note,
                        decoration: const InputDecoration(labelText: 'Note'),
                      ),
                      const SizedBox(height: MfSpace.lg),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _taxable,
                        onChanged: (v) => setState(() => _taxable = v),
                        title: Row(
                          children: [
                            const Flexible(child: Text('Mark as taxable')),
                            const SizedBox(width: 6),
                            Tooltip(
                              message:
                                  'Use this when GST or VAT should be tracked on the expense.',
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: cs.onSurface.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text(
                          'Enables GST/VAT tracking for this expense',
                        ),
                      ),
                      if (_taxable) ...[
                        const SizedBox(height: MfSpace.sm),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_taxScheme),
                          initialValue: _taxScheme,
                          borderRadius: BorderRadius.circular(12),
                          decoration: const InputDecoration(
                            labelText: 'Tax type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'gst_in',
                              child: Text('India GST'),
                            ),
                            DropdownMenuItem(
                              value: 'vat_ae',
                              child: Text('UAE VAT'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _taxScheme = v ?? 'gst_in'),
                        ),
                        const SizedBox(height: MfSpace.md),
                        TextField(
                          controller: _taxAmount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Tax amount',
                            prefixText: '${MfCurrency.symbol} ',
                            helperText:
                                'GST or VAT portion included in the amount above',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: MfSpace.xxl),
                LedgerPrimaryGradientButton(
                  onPressed: _save,
                  loading: _saving,
                  child: const Text('Save'),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(MfSpace.xl),
              child: Text(
                'Something went wrong. Please try refreshing.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineCategoryCreator extends StatefulWidget {
  const _InlineCategoryCreator({required this.onCreated});

  final Future<void> Function(String name) onCreated;

  @override
  State<_InlineCategoryCreator> createState() => _InlineCategoryCreatorState();
}

class _InlineCategoryCreatorState extends State<_InlineCategoryCreator> {
  final _controller = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      await widget.onCreated(name);
      if (!mounted) return;
      _controller.clear();
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Category name',
            hintText: 'e.g. Groceries',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: MfSpace.md),
        FilledButton(
          onPressed: _creating ? null : _submit,
          child: _creating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create & continue'),
        ),
      ],
    );
  }
}
