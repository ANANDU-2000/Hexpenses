import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/money_flow_tokens.dart';

/// Premium card: soft shadow, rounded corners, optional glass border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MfSpace.lg),
    this.onTap,
    this.glass = false,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool glass;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final blur = glass ? ImageFilter.blur(sigmaX: 20, sigmaY: 20) : null;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MfRadius.md),
        color: cs.surfaceContainerLowest.withValues(alpha: glass ? 0.65 : 1),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: glass ? 0.25 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MfRadius.md),
        child: blur != null
            ? BackdropFilter(
                filter: blur,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MfRadius.md),
          child: card,
        ),
      );
    }

    return card;
  }
}
