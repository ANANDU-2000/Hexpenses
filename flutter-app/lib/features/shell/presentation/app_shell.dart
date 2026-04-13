import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../onboarding/presentation/demo_get_started_screen.dart';
import '../../analytics/presentation/analytics_dashboard_screen.dart';
import '../../dashboard/presentation/money_flow_home_screen.dart';
import '../../expenses/presentation/expense_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'quick_create_sheet.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _destinations = [
    _ShellDestination('Home', Icons.home_outlined, Icons.home_rounded),
    _ShellDestination(
      'Transactions',
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
    ),
    _ShellDestination(
      'Analytics',
      Icons.insights_outlined,
      Icons.insights_rounded,
    ),
    _ShellDestination(
      'Profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sync = ref.read(ledgerSyncServiceProvider);
      await sync.ensureNoApiSeed();
      if (!kNoApiMode) {
        await sync.pullAndFlush();
      } else if (mounted) {
        await showDemoGetStartedIfNeeded(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    // Docked FAB + bar + home indicator; keep list content above the bar.
    final bodyBottomInset = bottomSafe + 88.0;
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFF0B1220),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: EdgeInsets.only(bottom: bodyBottomInset),
        ),
        child: IndexedStack(
          index: _index,
          children: const [
            MoneyFlowHomeScreen(),
            ExpenseListScreen(),
            AnalyticsDashboardScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showMoneyFlowQuickCreateSheet(context),
        backgroundColor: const Color(0xFFE6FF4D),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF121A2B),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black54,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 12,
        height: 64 + bottomSafe,
        padding: EdgeInsets.only(
          left: 4,
          right: 4,
          top: 6,
          bottom: bottomSafe > 0 ? bottomSafe : 8,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _NavItemButton(
                destination: _destinations[0],
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
            ),
            Expanded(
              child: _NavItemButton(
                destination: _destinations[1],
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
            ),
            const SizedBox(width: 56),
            Expanded(
              child: _NavItemButton(
                destination: _destinations[2],
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ),
            Expanded(
              child: _NavItemButton(
                destination: _destinations[3],
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ShellDestination {
  const _ShellDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavItemButton extends StatelessWidget {
  const _NavItemButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFFE6FF4D)
        : const Color(0xFF8D93A1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? destination.selectedIcon
                    : destination.icon,
                color: color,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
