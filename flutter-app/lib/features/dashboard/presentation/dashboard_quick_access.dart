import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../accounts/presentation/accounts_screen.dart';
import '../../budgets/presentation/budget_screen.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../income/presentation/add_income_screen.dart';
import '../../income/presentation/income_history_screen.dart';
import '../../insurance/presentation/insurance_screen.dart';
import '../../investments/presentation/investments_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../vehicles/presentation/vehicles_screen.dart';

/// Premium quick links on the dashboard (same destinations as More, except log out).
class DashboardQuickAccess extends StatelessWidget {
  const DashboardQuickAccess({super.key});

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <_QuickLink>[
      _QuickLink(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Accounts',
        subtitle: 'Balances & cards',
        colors: [cs.primary.withValues(alpha: 0.92), cs.primaryContainer.withValues(alpha: 0.95)],
        onTap: () => _push(context, const AccountsScreen()),
      ),
      _QuickLink(
        icon: Icons.savings_outlined,
        title: 'Add income',
        subtitle: 'Log earnings',
        colors: [const Color(0xFF0D9F6E).withValues(alpha: 0.9), const Color(0xFF0D9F6E).withValues(alpha: 0.45)],
        onTap: () => _push(context, const AddIncomeScreen()),
      ),
      _QuickLink(
        icon: Icons.trending_up_outlined,
        title: 'Investments',
        subtitle: 'Portfolio',
        colors: [cs.tertiary.withValues(alpha: 0.88), cs.tertiaryContainer.withValues(alpha: 0.9)],
        onTap: () => _push(context, const InvestmentsScreen()),
      ),
      _QuickLink(
        icon: Icons.pie_chart_outline_outlined,
        title: 'Budgets',
        subtitle: 'Spending caps',
        colors: [const Color(0xFF6D28D9).withValues(alpha: 0.75), const Color(0xFF6D28D9).withValues(alpha: 0.35)],
        onTap: () => _push(context, const BudgetScreen()),
      ),
      _QuickLink(
        icon: Icons.notifications_outlined,
        title: 'Alerts',
        subtitle: 'Notifications',
        colors: [cs.secondary.withValues(alpha: 0.85), cs.secondaryContainer.withValues(alpha: 0.95)],
        onTap: () => _push(context, const NotificationsScreen()),
      ),
      _QuickLink(
        icon: Icons.payments_outlined,
        title: 'Income history',
        subtitle: 'Past entries',
        colors: [cs.primary.withValues(alpha: 0.55), cs.primaryContainer.withValues(alpha: 0.75)],
        onTap: () => _push(context, const IncomeHistoryScreen()),
      ),
      _QuickLink(
        icon: Icons.folder_outlined,
        title: 'Documents',
        subtitle: 'Statements',
        colors: [cs.surfaceContainerHigh, cs.surfaceContainerHighest],
        onTap: () => _push(context, const DocumentsScreen()),
      ),
      _QuickLink(
        icon: Icons.health_and_safety_outlined,
        title: 'Insurance',
        subtitle: 'Coverage',
        colors: [const Color(0xFF0369A1).withValues(alpha: 0.75), const Color(0xFF0369A1).withValues(alpha: 0.35)],
        onTap: () => _push(context, const InsuranceScreen()),
      ),
      _QuickLink(
        icon: Icons.directions_car_outlined,
        title: 'Vehicles',
        subtitle: 'Assets',
        colors: [cs.onSurface.withValues(alpha: 0.55), cs.onSurface.withValues(alpha: 0.25)],
        onTap: () => _push(context, const VehiclesScreen()),
      ),
      _QuickLink(
        icon: Icons.bar_chart_outlined,
        title: 'Reports',
        subtitle: 'Analytics',
        colors: [const Color(0xFF1E3A5F).withValues(alpha: 0.85), const Color(0xFF1E3A5F).withValues(alpha: 0.45)],
        onTap: () => _push(context, const ReportsScreen()),
      ),
      _QuickLink(
        icon: Icons.auto_awesome_outlined,
        title: 'AI insights',
        subtitle: 'Smart tips',
        colors: [const Color(0xFF000B60).withValues(alpha: 0.88), const Color(0xFF142283).withValues(alpha: 0.65)],
        onTap: () => _push(context, const InsightsScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick access',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Jump to accounts, planning, and tools',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final cross = c.maxWidth > 720 ? 4 : c.maxWidth > 420 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: cross >= 4 ? 1.05 : 1.02,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _QuickTile(link: items[i]),
            );
          },
        ),
      ],
    );
  }
}

class _QuickLink {
  const _QuickLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.link});

  final _QuickLink link;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onLight = link.colors.length >= 2 && link.colors[0].computeLuminance() > 0.55;
    final iconColor = onLight ? cs.primary : Colors.white.withValues(alpha: 0.95);
    final titleColor = onLight ? cs.onSurface : Colors.white;
    final subColor = onLight ? cs.onSurface.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: link.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: link.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: onLight ? 0.05 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: onLight ? 0.35 : 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: onLight ? 0.85 : 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(link.icon, size: 22, color: iconColor),
                ),
                const Spacer(),
                Text(
                  link.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  link.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
