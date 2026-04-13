import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/premium_fab.dart';
import '../../../core/dio_errors.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../../core/widgets/premium_fintech_app_bar.dart';
import '../../../core/widgets/premium_fintech_backdrop.dart';
import '../../expenses/application/expense_providers.dart';
import '../application/recurring_providers.dart';
import '../data/recurring_api.dart';

bool _isActiveRow(Map<String, dynamic> r) {
  final v = r['active'];
  if (v == false) return false;
  return true;
}

double _monthlyEquivalent(Map<String, dynamic> r) {
  final amt = double.tryParse(r['amount']?.toString() ?? '0') ?? 0;
  final freq = r['frequency']?.toString() ?? 'monthly';
  switch (freq) {
    case 'daily':
      return amt * 30;
    case 'weekly':
      return amt * 52 / 12;
    case 'monthly':
      return amt;
    case 'quarterly':
      return amt / 3;
    case 'yearly':
      return amt / 12;
    default:
      return amt;
  }
}

double _monthlyTotalActive(List<Map<String, dynamic>> rows) {
  var t = 0.0;
  for (final r in rows) {
    if (_isActiveRow(r)) t += _monthlyEquivalent(r);
  }
  return t;
}

String _nextBillingLabel(Map<String, dynamic> r) {
  final raw = r['nextDate'];
  if (raw == null) return '—';
  final dt = DateTime.tryParse(raw.toString());
  if (dt == null) return raw.toString();
  final local = dt.toLocal();
  return DateFormat('d MMM yyyy').format(local);
}

String _frequencyShort(String? freq) {
  switch (freq) {
    case 'daily':
      return 'Daily';
    case 'weekly':
      return 'Weekly';
    case 'monthly':
      return 'Monthly';
    case 'quarterly':
      return 'Quarterly';
    case 'yearly':
      return 'Yearly';
    default:
      return freq ?? '';
  }
}

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  static const _freqs = ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final list = ref.watch(recurringListProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: PremiumFintechAppBar.bar(
        context: context,
        title: 'Recurring',
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumFintechBackdrop(),
          list.when(
            data: (rows) {
              if (rows.isEmpty) {
                return RefreshIndicator(
                  color: MfPalette.neonGreen,
                  backgroundColor: cs.surfaceContainerHigh,
                  onRefresh: () async {
                    ref.invalidate(recurringListProvider);
                    await ref.read(recurringListProvider.future);
                  },
                  child: _RecurringEmptyBody(),
                );
              }
              final monthly = _monthlyTotalActive(rows);
              return RefreshIndicator(
                color: MfPalette.neonGreen,
                backgroundColor: cs.surfaceContainerHigh,
                onRefresh: () async {
                  ref.invalidate(recurringListProvider);
                  await ref.read(recurringListProvider.future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        MfSpace.xxl,
                        MfSpace.sm,
                        MfSpace.xxl,
                        MediaQuery.paddingOf(context).bottom + 100,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _MonthlyRecurringHero(
                            totalFormatted: MfCurrency.formatInr(monthly),
                          ),
                          const SizedBox(height: MfSpace.xl),
                          Text(
                            'Subscriptions',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: cs.onSurface.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: MfSpace.md),
                          ...rows.map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: MfSpace.md),
                              child: _SubscriptionCard(row: r),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const _RecurringLoadingBody(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(MfSpace.xxl),
              child: LedgerErrorState(
                title: 'Could not load recurring expenses',
                message: e is DioException ? dioErrorMessage(e) : e.toString(),
                onRetry: () {
                  ref.invalidate(recurringListProvider);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: MoneyFlowPremiumExtendedFab(
        heroTag: 'recurring_add_fab',
        tooltip: 'Add recurring',
        icon: Icons.add_rounded,
        label: 'Add recurring',
        onPressed: () => _openForm(context, ref),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                          Text(
                            'New recurring',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          cats.when(
                            data: (list) => DropdownButtonFormField<String>(
                              key: ValueKey('rcat-$categoryId'),
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              initialValue: categoryId,
                              items: list
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c['id']?.toString(),
                                      child: Text(c['name']?.toString() ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setSt(() => categoryId = v),
                            ),
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('$e'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: title,
                            decoration: const InputDecoration(
                              labelText: 'Title',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: amount,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(freq),
                            decoration: const InputDecoration(
                              labelText: 'Frequency',
                            ),
                            initialValue: freq,
                            items: _freqs
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setSt(() => freq = v ?? 'monthly'),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Next: ${next.toLocal().toString().split(' ').first}',
                            ),
                            trailing: const Icon(Icons.calendar_today_outlined),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: next,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 3),
                                ),
                              );
                              if (d != null) setSt(() => next = d);
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: note,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                            ),
                          ),
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
                                      title: title.text.trim().isEmpty
                                          ? 'Recurring'
                                          : title.text.trim(),
                                      note: note.text.trim().isEmpty
                                          ? null
                                          : note.text.trim(),
                                    );
                                ref.invalidate(recurringListProvider);
                                if (context.mounted) Navigator.pop(context);
                              } on DioException catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(dioErrorMessage(e)),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
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

class _MonthlyRecurringHero extends StatelessWidget {
  const _MonthlyRecurringHero({required this.totalFormatted});

  final String totalFormatted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: MfSpace.xl,
        vertical: MfSpace.xl,
      ),
      decoration: heroCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY RECURRING (EST.)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            totalFormatted,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 30,
              height: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MfSpace.xs),
          Text(
            'Active subscriptions, normalized to a monthly run rate',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.52),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends ConsumerStatefulWidget {
  const _SubscriptionCard({required this.row});

  final Map<String, dynamic> row;

  @override
  ConsumerState<_SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends ConsumerState<_SubscriptionCard> {
  bool _patching = false;

  Future<void> _setActive(bool value) async {
    final id = widget.row['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _patching = true);
    try {
      await ref.read(recurringApiProvider).setActive(id: id, active: value);
      ref.invalidate(recurringListProvider);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dioErrorMessage(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _patching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = widget.row;
    final title = r['title']?.toString() ?? 'Subscription';
    final amount = r['amount'];
    final freq = r['frequency']?.toString();
    final active = _isActiveRow(r);
    final muted = !active;

    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(MfSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MfRadius.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MfPalette.accentSoftPurple.withValues(alpha: muted ? 0.25 : 0.55),
                      MfPalette.neonGreen.withValues(alpha: muted ? 0.1 : 0.22),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.subscriptions_rounded,
                  color: Colors.white.withValues(alpha: muted ? 0.5 : 0.95),
                  size: 24,
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: cs.onSurface.withValues(alpha: muted ? 0.45 : 1),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: MfSpace.xs),
                    Text(
                      _frequencyShort(freq),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
              AbsorbPointer(
                absorbing: _patching,
                child: Opacity(
                  opacity: _patching ? 0.55 : 1,
                  child: Switch(
                    value: active,
                    onChanged: _patching ? null : _setActive,
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return MfPalette.neonGreenSoft;
                      }
                      return cs.outline;
                    }),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return MfPalette.neonGreen.withValues(alpha: 0.42);
                      }
                      return cs.surfaceContainerHighest.withValues(alpha: 0.85);
                    }),
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MfSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next billing',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _nextBillingLabel(r),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: cs.onSurface.withValues(alpha: muted ? 0.4 : 0.92),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                MfCurrency.formatInr(amount),
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: cs.onSurface.withValues(alpha: muted ? 0.4 : 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecurringEmptyBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              MfSpace.xxl,
              MfSpace.xxxl,
              MfSpace.xxl,
              MediaQuery.paddingOf(context).bottom + 100,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LedgerRecurringEmptyIllustration(width: 200),
                const SizedBox(height: MfSpace.xl),
                Text(
                  'No recurring expenses',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: MfSpace.md),
                Text(
                  'Track Netflix, rent, SIPs, and other subscriptions. We will remind you before each billing cycle.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecurringLoadingBody extends StatelessWidget {
  const _RecurringLoadingBody();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        MfSpace.xxl,
        MfSpace.md,
        MfSpace.xxl,
        MediaQuery.paddingOf(context).bottom + 88,
      ),
      children: [
        Container(
          height: 128,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(MfRadius.xl),
          ),
        ),
        const SizedBox(height: MfSpace.xl),
        ...List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: MfSpace.md),
            child: Container(
              height: 108,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(MfRadius.lg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty state: calendar + repeat motif for recurring bills.
class LedgerRecurringEmptyIllustration extends StatelessWidget {
  const LedgerRecurringEmptyIllustration({super.key, this.width = 168});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.62;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(painter: _RecurringEmptyPainter()),
    );
  }
}

class _RecurringEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cal = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.12, w * 0.72, h * 0.52),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      cal,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MfPalette.heroMid.withValues(alpha: 0.55),
            MfPalette.accentSoftPurple.withValues(alpha: 0.35),
          ],
        ).createShader(cal.outerRect),
    );
    canvas.drawRRect(
      cal,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.22),
    );

    final bar = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.14, h * 0.12, w * 0.72, h * 0.14),
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
    );
    canvas.drawRRect(bar, Paint()..color = Colors.black.withValues(alpha: 0.2));

    final loopCenter = Offset(w * 0.5, h * 0.72);
    final loopPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..color = MfPalette.neonGreen.withValues(alpha: 0.65);
    canvas.drawArc(
      Rect.fromCircle(center: loopCenter.translate(-w * 0.1, 0), radius: w * 0.12),
      3.3,
      2.2,
      false,
      loopPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: loopCenter.translate(w * 0.1, 0), radius: w * 0.12),
      0.2,
      2.2,
      false,
      loopPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
