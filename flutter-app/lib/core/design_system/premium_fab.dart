import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/money_flow_tokens.dart';

/// Gradient FAB with neon glow, aligned for [FloatingActionButtonLocation.endFloat].
class MoneyFlowPremiumExtendedFab extends StatefulWidget {
  const MoneyFlowPremiumExtendedFab({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.heroTag,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Object? heroTag;
  final String? tooltip;

  @override
  State<MoneyFlowPremiumExtendedFab> createState() =>
      _MoneyFlowPremiumExtendedFabState();
}

class _MoneyFlowPremiumExtendedFabState extends State<MoneyFlowPremiumExtendedFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: MfMotion.fast,
      curve: MfMotion.curve,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: MfPalette.neonGreen.withValues(alpha: 0.35),
              blurRadius: 28,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: MfPalette.accentSoftPurple.withValues(alpha: 0.22),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MfPalette.accentSoftPurple,
                    Color(0xFF6B7AE8),
                    MfPalette.neonGreenSoft,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: MfPalette.onNeonGreen, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: MfPalette.onNeonGreen,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Widget w = child;
    if (widget.heroTag != null) {
      w = Hero(tag: widget.heroTag!, child: w);
    }
    if (widget.tooltip != null) {
      w = Tooltip(message: widget.tooltip!, child: w);
    }
    return w;
  }
}

/// Circular gradient FAB (e.g. feature screens).
class MoneyFlowPremiumCircularFab extends StatefulWidget {
  const MoneyFlowPremiumCircularFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.heroTag,
    this.size = 56,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Object? heroTag;
  final double size;

  @override
  State<MoneyFlowPremiumCircularFab> createState() =>
      _MoneyFlowPremiumCircularFabState();
}

class _MoneyFlowPremiumCircularFabState extends State<MoneyFlowPremiumCircularFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final child = AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: MfMotion.fast,
      curve: MfMotion.curve,
      child: Container(
        width: s + 16,
        height: s + 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MfPalette.neonGreen.withValues(alpha: 0.32),
              blurRadius: 26,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: MfPalette.accentSoftPurple.withValues(alpha: 0.2),
              blurRadius: 18,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Ink(
              width: s,
              height: s,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MfPalette.neonGreenSoft,
                    MfPalette.neonGreen,
                    MfPalette.accentSoftPurple,
                  ],
                ),
              ),
              child: Icon(widget.icon, color: MfPalette.onNeonGreen, size: 26),
            ),
          ),
        ),
      ),
    );

    Widget w = child;
    if (widget.tooltip != null) {
      w = Tooltip(message: widget.tooltip!, child: w);
    }
    if (widget.heroTag != null) {
      w = Hero(tag: widget.heroTag!, child: w);
    }
    return w;
  }
}
