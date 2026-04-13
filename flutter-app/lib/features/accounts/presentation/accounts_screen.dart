import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/app_button.dart';
import '../../../core/design_system/premium_fab.dart';
import '../../../core/dio_errors.dart';
import '../../../core/navigation/ledger_page_routes.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../expenses/presentation/expense_list_screen.dart';
import '../application/account_providers.dart';
import '../data/accounts_api.dart';

class _AccountKind {
  const _AccountKind({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

_AccountKind _kindForAccount(Map<String, dynamic> a) {
  final name = (a['name']?.toString() ?? '').toLowerCase();
  final type = (a['type']?.toString() ?? 'bank').toLowerCase();
  if (name.contains('upi')) {
    return const _AccountKind(
      label: 'UPI',
      icon: Icons.smartphone_rounded,
    );
  }
  switch (type) {
    case 'cash':
      return const _AccountKind(
        label: 'Wallet',
        icon: Icons.account_balance_wallet_rounded,
      );
    case 'credit':
      return const _AccountKind(
        label: 'Credit card',
        icon: Icons.credit_card_rounded,
      );
    case 'bank':
    default:
      return const _AccountKind(
        label: 'Savings',
        icon: Icons.account_balance_rounded,
      );
  }
}

double _totalBalance(List<Map<String, dynamic>> accounts) {
  var sum = 0.0;
  for (final a in accounts) {
    sum += double.tryParse(a['balance']?.toString() ?? '0') ?? 0;
  }
  return sum;
}

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  static const _types = ['bank', 'cash', 'credit'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(accountsProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Accounts',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transfer',
            onPressed: () => _openTransfer(context, ref),
          ),
        ],
      ),
      body: async.when(
        data: (ledger) {
          final list = ledger.accounts;
          if (list.isEmpty) {
            return RefreshIndicator(
              color: MfPalette.neonGreen,
              backgroundColor: cs.surfaceContainerHigh,
              onRefresh: () async {
                await ref.read(ledgerSyncServiceProvider).pullAndFlush();
              },
              child: _AccountsEmptyBody(
                onAddAccount: () => _openAddAccount(context, ref),
              ),
            );
          }
          final total = _totalBalance(list);
          return RefreshIndicator(
            color: MfPalette.neonGreen,
            backgroundColor: const Color(0xFF121A2B),
            onRefresh: () async {
              await ref.read(ledgerSyncServiceProvider).pullAndFlush();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    MfSpace.lg,
                    MfSpace.sm,
                    MfSpace.lg,
                    MediaQuery.paddingOf(context).bottom + 100,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TotalBalanceHero(totalFormatted: MfCurrency.formatInr(total)),
                      const SizedBox(height: MfSpace.lg),
                      Text(
                        'Your accounts',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: cs.onSurface.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: MfSpace.md),
                      ...list.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: MfSpace.sm),
                          child: _AccountTile(
                            account: a,
                            onOpenTransactions: () {
                              final id = a['id']?.toString() ?? '';
                              final name = a['name']?.toString() ?? 'Account';
                              Navigator.of(context).push(
                                LedgerPageRoutes.fadeSlide<void>(
                                  ExpenseListScreen(
                                    accountId: id,
                                    accountName: name,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const _AccountsLoadingBody(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(MfSpace.xxl),
          child: LedgerErrorState(
            title: 'Could not load accounts',
            message: e is DioException ? dioErrorMessage(e) : e.toString(),
            onRetry: () {
              ref.invalidate(accountsProvider);
              ref.read(ledgerSyncServiceProvider).pullAndFlush();
            },
          ),
        ),
      ),
      floatingActionButton: MoneyFlowPremiumExtendedFab(
        heroTag: 'accounts_add_fab',
        tooltip: 'Add account',
        icon: Icons.add_rounded,
        label: 'Add account',
        onPressed: () => _openAddAccount(context, ref),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
              Text(
                'New account',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(type),
                decoration: const InputDecoration(labelText: 'Type'),
                initialValue: type,
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setSt(() => type = v ?? 'bank'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: initial,
                decoration: const InputDecoration(
                  labelText: 'Starting balance',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 20),
              LedgerPrimaryGradientButton(
                onPressed: () async {
                  if (name.text.trim().isEmpty) return;
                  final initialText = initial.text.trim().replaceAll(',', '');
                  final ib = initialText.isEmpty
                      ? 0.0
                      : double.tryParse(initialText);
                  if (ib == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter a valid starting balance'),
                      ),
                    );
                    return;
                  }
                  if (ib.abs() > 9999999999.99) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Starting balance must be below 10,000,000,000',
                        ),
                      ),
                    );
                    return;
                  }
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(dioErrorMessage(e))),
                      );
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
        const SnackBar(
          content: Text('Create at least two accounts to transfer'),
        ),
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
                    .map(
                      (a) => DropdownMenuItem(
                        value: a['id']?.toString(),
                        child: Text(a['name']?.toString() ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSt(() => fromId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('to-$toId'),
                decoration: const InputDecoration(labelText: 'To'),
                initialValue: toId,
                items: accounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a['id']?.toString(),
                        child: Text(a['name']?.toString() ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSt(() => toId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 20),
              LedgerPrimaryGradientButton(
                onPressed: () async {
                  final a = double.tryParse(
                    amount.text.trim().replaceAll(',', ''),
                  );
                  if (fromId == null || toId == null || a == null || a <= 0) {
                    return;
                  }
                  if (fromId == toId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Choose different accounts'),
                      ),
                    );
                    return;
                  }
                  try {
                    await ref.read(accountsApiProvider).transfer(
                          fromAccountId: fromId!,
                          toAccountId: toId!,
                          amount: a,
                          note: note.text.trim().isEmpty
                              ? null
                              : note.text.trim(),
                        );
                    await ref.read(ledgerSyncServiceProvider).pullAndFlush();
                    if (context.mounted) Navigator.pop(context);
                  } on DioException catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(dioErrorMessage(e))),
                      );
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

class _TotalBalanceHero extends StatelessWidget {
  const _TotalBalanceHero({required this.totalFormatted});

  final String totalFormatted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: MfSpace.xl,
        vertical: MfSpace.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MfRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A2556),
            const Color(0xFF233C9C),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL BALANCE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            totalFormatted,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MfSpace.xs),
          Text(
            'Across all linked accounts',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.onOpenTransactions,
  });

  final Map<String, dynamic> account;
  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context) {
    final kind = _kindForAccount(account);
    final bankName = account['name']?.toString() ?? 'Account';
    final bal = account['balance'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenTransactions,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(MfSpace.md),
          decoration: BoxDecoration(
            color: const Color(0xFF121A2B),
            borderRadius: BorderRadius.circular(MfRadius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MfRadius.md),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: Icon(
              kind.icon,
              color: Colors.white.withValues(alpha: 0.92),
              size: 22,
            ),
          ),
          const SizedBox(width: MfSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bankName,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.94),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  kind.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MfSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MfCurrency.formatInr(bal),
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.98),
                ),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountsEmptyBody extends StatelessWidget {
  const _AccountsEmptyBody({required this.onAddAccount});

  final VoidCallback onAddAccount;

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
              MfSpace.xxl,
              MfSpace.xxl,
              MediaQuery.paddingOf(context).bottom + 100,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const LedgerAccountsEmptyIllustration(width: 192),
                const SizedBox(height: MfSpace.xl),
                Text(
                  'No accounts added',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: MfSpace.md),
                Text(
                  'Link bank, UPI, or wallet accounts to track balances and spending in one place.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: MfSpace.xl),
                Center(
                  child: AppButton(
                    label: 'Add account',
                    icon: Icons.add_rounded,
                    onPressed: onAddAccount,
                    expand: false,
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

class _AccountsLoadingBody extends StatelessWidget {
  const _AccountsLoadingBody();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        MfSpace.lg,
        MfSpace.md,
        MfSpace.lg,
        MediaQuery.paddingOf(context).bottom + 88,
      ),
      children: [
        Container(
          height: 132,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(MfRadius.xl),
          ),
        ),
        const SizedBox(height: MfSpace.xl),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: MfSpace.md),
            child: Container(
              height: 88,
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

/// Bank / card stack illustration for empty accounts.
class LedgerAccountsEmptyIllustration extends StatelessWidget {
  const LedgerAccountsEmptyIllustration({super.key, this.width = 168});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.58;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(painter: _AccountsEmptyPainter()),
    );
  }
}

class _AccountsEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final back = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.18, w * 0.76, h * 0.52),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      back,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MfPalette.accentSoftPurple.withValues(alpha: 0.28),
            MfPalette.heroMid.withValues(alpha: 0.45),
          ],
        ).createShader(back.outerRect),
    );
    canvas.drawRRect(
      back,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.2),
    );

    final front = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.06, w * 0.88, h * 0.48),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MfPalette.heroEnd.withValues(alpha: 0.75),
            MfPalette.accentSoftPurple.withValues(alpha: 0.5),
          ],
        ).createShader(front.outerRect),
    );
    canvas.drawRRect(
      front,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.28),
    );

    final chip = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.22, w * 0.18, h * 0.12),
      const Radius.circular(4),
    );
    canvas.drawRRect(chip, Paint()..color = MfPalette.neonGreen.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
