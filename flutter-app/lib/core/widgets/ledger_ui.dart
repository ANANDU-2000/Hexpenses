import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Primary CTA: gradient primary → primary_container, 12px radius (DESIGN.md §2, §5).
class LedgerPrimaryGradientButton extends StatelessWidget {
  const LedgerPrimaryGradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              alignment: Alignment.center,
              child: loading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : DefaultTextStyle(
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Action layer: white / surfaceContainerLowest on canvas (DESIGN.md §2).
class LedgerActionLayer extends StatelessWidget {
  const LedgerActionLayer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.shadow = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: shadow ? ledgerAmbientFabShadows(cs) : null,
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Section layer: surfaceContainerLow grouping (DESIGN.md §2).
class LedgerSectionLayer extends StatelessWidget {
  const LedgerSectionLayer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Staggered list row: 12px rhythm, no dividers (DESIGN.md §5).
class LedgerStaggerItem extends StatelessWidget {
  const LedgerStaggerItem({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.marginBottom = 12,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double marginBottom;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Glass-style bar: surface @ ~80% + blur (DESIGN.md §2).
class LedgerGlassBar extends StatelessWidget {
  const LedgerGlassBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.82)),
          child: child,
        ),
      ),
    );
  }
}

/// FAB with ambient shadow recipe (DESIGN.md §4).
class LedgerFab extends StatelessWidget {
  const LedgerFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: ledgerAmbientFabShadows(cs),
      ),
      child: FloatingActionButton(
        tooltip: tooltip,
        elevation: 0,
        highlightElevation: 0,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
