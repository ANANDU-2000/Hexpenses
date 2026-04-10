import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/application/theme_mode_provider.dart';
import '../../../core/design_system/app_card.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../auth/application/session_notifier.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../insurance/presentation/insurance_screen.dart';
import '../../investments/presentation/investments_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../recurring/presentation/recurring_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../vehicles/presentation/vehicles_screen.dart';
import '../../whatsapp/presentation/whatsapp_connect_screen.dart';
import '../../insights/presentation/insights_screen.dart';

/// Profile & settings hub (formerly "More").
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(MfSpace.xxl, MfSpace.md, MfSpace.xxl, 100),
        children: [
          AppCard(
            padding: const EdgeInsets.all(MfSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: MfSpace.md),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto, size: 18)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined, size: 18)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined, size: 18)),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) {
                    ref.read(themeModeProvider.notifier).setMode(s.first);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          _section(context, 'AI', [
            _tile(
              context,
              Icons.chat_bubble_outline_rounded,
              'Ask AI',
              null,
              cs.primary,
              () => _push(context, const InsightsScreen(initialTab: InsightsEntryTab.chat)),
            ),
          ]),
          _section(context, 'Messaging', [
            _tile(context, Icons.chat_rounded, 'WhatsApp', 'Optional alerts & digests', const Color(0xFF128C7E), () {
              _push(context, const WhatsappConnectScreen());
            }),
          ]),
          _section(context, 'Money', [
            _tile(context, Icons.account_balance_wallet_outlined, 'Accounts', null, cs.primary, () {
              _push(context, const AccountsScreen());
            }),
            _tile(context, Icons.repeat_rounded, 'Recurring', null, cs.secondary, () {
              _push(context, const RecurringScreen());
            }),
            _tile(context, Icons.pie_chart_outline_rounded, 'Budgets', null, const Color(0xFF6D28D9), () {
              _push(context, const BudgetScreen());
            }),
            _tile(context, Icons.bar_chart_rounded, 'Full reports', null, cs.primary, () {
              _push(context, const ReportsScreen());
            }),
          ]),
          _section(context, 'Library', [
            _tile(context, Icons.folder_outlined, 'Documents', null, cs.onSurface, () {
              _push(context, const DocumentsScreen());
            }),
            _tile(context, Icons.notifications_outlined, 'Notifications', null, cs.onSurface, () {
              _push(context, const NotificationsScreen());
            }),
          ]),
          _section(context, 'Wealth', [
            _tile(context, Icons.trending_up_outlined, 'Investments', null, cs.onSurface, () {
              _push(context, const InvestmentsScreen());
            }),
            _tile(context, Icons.health_and_safety_outlined, 'Insurance', null, const Color(0xFF0369A1), () {
              _push(context, const InsuranceScreen());
            }),
            _tile(context, Icons.directions_car_outlined, 'Vehicles', null, cs.onSurface, () {
              _push(context, const VehiclesScreen());
            }),
          ]),
          const SizedBox(height: MfSpace.lg),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: cs.onSurface.withValues(alpha: 0.5)),
            title: Text('About MoneyFlow AI', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.35)),
            onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'MoneyFlow AI',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'Premium personal finance',
                ),
          ),
          const SizedBox(height: MfSpace.xl),
          FilledButton.icon(
            onPressed: () async {
              await ref.read(sessionProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(
              backgroundColor: cs.error.withValues(alpha: 0.12),
              foregroundColor: cs.error,
            ),
            icon: Icon(Icons.logout_rounded, color: cs.error),
            label: Text('Log out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> tiles) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: MfSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: MfSpace.xs, bottom: MfSpace.sm),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: tiles),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String? subtitle,
    Color tint,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MfSpace.lg, vertical: MfSpace.md + 2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(MfRadius.sm),
                ),
                child: Icon(icon, color: tint.withValues(alpha: 0.9), size: 22),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
