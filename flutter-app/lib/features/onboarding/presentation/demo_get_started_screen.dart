import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/storage/demo_get_started_storage.dart';
import '../../../core/theme/money_flow_tokens.dart';

/// Shows the demo onboarding once (unless skipped earlier). No-op when not in demo mode.
Future<void> showDemoGetStartedIfNeeded(BuildContext context) async {
  if (!kNoApiMode) return;
  final done = await DemoGetStartedStorage.hasCompleted();
  if (!context.mounted || done) return;
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (ctx, _, __) => const DemoGetStartedScreen(markCompleteOnExit: true),
      transitionsBuilder: (ctx, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    ),
  );
}

/// Re-open tips from Profile (demo mode only). Does not change completion flag.
Future<void> openDemoGetStartedFromProfile(BuildContext context) async {
  if (!kNoApiMode) return;
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const DemoGetStartedScreen(markCompleteOnExit: false),
    ),
  );
}

class DemoGetStartedScreen extends StatefulWidget {
  const DemoGetStartedScreen({super.key, required this.markCompleteOnExit});

  final bool markCompleteOnExit;

  @override
  State<DemoGetStartedScreen> createState() => _DemoGetStartedScreenState();
}

class _DemoGetStartedScreenState extends State<DemoGetStartedScreen> {
  final _pageController = PageController();
  int _page = 0;
  static const _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _exit() async {
    if (widget.markCompleteOnExit) {
      await DemoGetStartedStorage.setCompleted();
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pageController.nextPage(
        duration: MfMotion.medium,
        curve: MfMotion.curve,
      );
    } else {
      _exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MfPalette.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MfSpace.sm,
                MfSpace.sm,
                MfSpace.sm,
                MfSpace.xs,
              ),
              child: Row(
                children: [
                  Text(
                    'MoneyFlow AI',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: MfPalette.neonGreen,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _exit,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: MfPalette.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OnboardPage(
                    icon: Icons.rocket_launch_rounded,
                    title: 'Welcome to the demo',
                    body:
                        'You\'re in offline demo mode with sample income, expenses, '
                        'and balances. No sign-in or server is required—explore freely.',
                  ),
                  _OnboardPage(
                    icon: Icons.explore_rounded,
                    title: 'Find your way around',
                    body:
                        'Use the bottom bar: Home for your overview, Transactions for '
                        'spending history, Analytics for charts, and Profile for settings '
                        'and more tools. Tap the yellow + button to add an expense quickly.',
                  ),
                  _OnboardPage(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Tips',
                    body:
                        'Pull down on lists to refresh when a live API is connected. '
                        'In this demo, adding income from some flows may be limited—'
                        'expenses and browsing work with local sample data.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MfSpace.xxl,
                MfSpace.md,
                MfSpace.xxl,
                MfSpace.lg,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: MfMotion.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? MfPalette.neonGreen
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: MfSpace.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: MfPalette.neonGreen,
                        foregroundColor: MfPalette.onNeonGreen,
                        padding: const EdgeInsets.symmetric(vertical: MfSpace.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(MfRadius.md),
                        ),
                      ),
                      child: Text(
                        _page < _totalPages - 1 ? 'Next' : 'Get started',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MfSpace.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(MfSpace.xl),
            decoration: BoxDecoration(
              color: MfPalette.neonGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: MfPalette.neonGreen),
          ),
          const SizedBox(height: MfSpace.xxxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              height: 1.45,
              color: MfPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
