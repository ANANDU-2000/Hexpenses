import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/money_flow_tokens.dart';

/// Single transaction row: icon, title, subtitle, amount (expense = rose, income = green).
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.leadingLabel,
    this.isExpense = true,
    this.onTap,
    this.endAction,
    this.animationIndex = 0,
  });

  final String title;
  final String subtitle;
  final String amountLabel;
  final String leadingLabel;
  final bool isExpense;
  final VoidCallback? onTap;
  final Widget? endAction;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final success = context.mf.success;
    final amountColor = isExpense ? const Color(0xFFE11D48) : success;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (animationIndex.clamp(0, 8) * 40)),
      curve: MfMotion.curve,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Material(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(MfRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MfSpace.lg, vertical: MfSpace.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.primary.withValues(alpha: 0.9),
                        cs.primary.withValues(alpha: 0.65),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(MfRadius.sm),
                  ),
                  child: Text(
                    leadingLabel.isNotEmpty ? leadingLabel.substring(0, 1).toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: MfSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: MfSpace.xs),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: amountColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                ?endAction,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
