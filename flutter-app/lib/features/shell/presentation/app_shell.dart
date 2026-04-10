import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_ui.dart';
import '../../dashboard/presentation/money_flow_home_screen.dart';
import '../../expenses/presentation/expense_list_screen.dart';
import '../../insights/presentation/insights_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../reports/presentation/reports_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: IndexedStack(
        index: _index,
        children: const [
          MoneyFlowHomeScreen(),
          ExpenseListScreen(),
          ReportsScreen(),
          InsightsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: LedgerGlassBar(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(MfSpace.md, MfSpace.sm, MfSpace.md, MfSpace.sm),
            child: NavigationBar(
              height: 64,
              backgroundColor: Colors.transparent,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Expenses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Reports',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
