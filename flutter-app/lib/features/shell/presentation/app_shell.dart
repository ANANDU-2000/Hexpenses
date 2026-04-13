import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
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
      'Activity',
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      backgroundColor: const Color(0xFF0B1220),
      body: IndexedStack(
        index: _index,
        children: const [
          MoneyFlowHomeScreen(),
          ExpenseListScreen(),
          AnalyticsDashboardScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showMoneyFlowQuickCreateSheet(context),
        backgroundColor: const Color(0xFFE6FF4D),
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.black, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF121A2B),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItemButton(
                destination: _destinations[0],
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItemButton(
                destination: _destinations[1],
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              const SizedBox(width: 48), // Spacer for FAB
              _NavItemButton(
                destination: _destinations[2],
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItemButton(
                destination: _destinations[3],
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected
                    ? destination.selectedIcon
                    : destination.icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                style: GoogleFonts.inter(
                  fontSize: 10,
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
