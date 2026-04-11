import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/money_flow_tokens.dart';

Color _categoryColor(String? name) {
  final colors = [
    Color(0xFF10B981),
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];
  final idx = (name?.codeUnits.fold(0, (a, b) => a + b) ?? 0) % colors.length;
  return colors[idx];
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.avatarColor,
    required this.avatarLabel,
    this.endAction,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;
  final Color avatarColor;
  final String avatarLabel;
  final Widget? endAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        child: Container(
          decoration: glassCard(borderRadius: MfRadius.lg),
          padding: const EdgeInsets.symmetric(
            horizontal: MfSpace.lg,
            vertical: MfSpace.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isExpense
                      ? expenseGradient(avatarColor)
                      : incomeGradient(),
                  borderRadius: BorderRadius.circular(MfRadius.sm),
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarLabel.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _categoryColor(title),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MfSpace.xs - 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                isExpense ? '−$amount' : '+$amount',
                style: GoogleFonts.dmMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isExpense
                      ? MfPalette.expenseRed
                      : MfPalette.incomeGreen,
                ),
              ),
              if (endAction != null) ...[
                const SizedBox(width: MfSpace.sm),
                endAction!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
