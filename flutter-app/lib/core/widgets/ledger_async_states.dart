import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../design_system/app_card.dart';
import '../theme/ledger_tokens.dart';
import '../theme/money_flow_tokens.dart';

/// Minimal vector-style illustration for empty states (card + coins + glow).
class LedgerFintechEmptyIllustration extends StatelessWidget {
  const LedgerFintechEmptyIllustration({super.key, this.width = 168});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.62;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(painter: _LedgerEmptyIllustrationPainter()),
    );
  }
}

class _LedgerEmptyIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.14, w * 0.8, h * 0.48),
      const Radius.circular(14),
    );
    final cardFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          MfPalette.accentSoftPurple.withValues(alpha: 0.42),
          MfPalette.neonGreen.withValues(alpha: 0.12),
        ],
      ).createShader(cardRect.outerRect);
    canvas.drawRRect(cardRect, cardFill);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.22),
    );

    final coinPaint = Paint();
    for (var i = 0; i < 3; i++) {
      coinPaint.color = MfPalette.neonGreen.withValues(alpha: 0.55 - i * 0.12);
      canvas.drawCircle(Offset(w * (0.26 + i * 0.2), h * 0.78), w * 0.065, coinPaint);
    }
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.32),
      w * 0.05,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LedgerDashboardSkeleton extends StatelessWidget {
  const LedgerDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 164,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(MfRadius.xl),
          ),
        ),
        const SizedBox(height: LedgerGap.lg),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(color: cs.primary, minHeight: 4),
        ),
      ],
    );
  }
}

class LedgerErrorState extends StatelessWidget {
  const LedgerErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LedgerGap.lg),
      child: AppCard(
        glass: true,
        padding: const EdgeInsets.all(MfSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(MfRadius.md),
                  ),
                  child: Icon(Icons.error_outline_rounded, color: cs.error),
                ),
                const SizedBox(width: MfSpace.md),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MfSpace.md),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.45,
                color: cs.onSurface.withValues(alpha: 0.68),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: MfSpace.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder block for chart areas while loading.
class LedgerChartSkeleton extends StatelessWidget {
  const LedgerChartSkeleton({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(MfRadius.lg),
      ),
    );
  }
}

/// Shimmer-free list placeholders for expense-style rows.
class LedgerExpenseListSkeleton extends StatelessWidget {
  const LedgerExpenseListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : LedgerGap.md),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(MfRadius.lg),
            ),
          ),
        ),
      ),
    );
  }
}

class LedgerEmptyState extends StatelessWidget {
  const LedgerEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 540),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: Transform.scale(
              scale: 0.97 + 0.03 * t,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: LedgerGap.xxl,
                  horizontal: LedgerGap.lg,
                ),
                child: AppCard(
                  glass: true,
                  padding: const EdgeInsets.all(MfSpace.xxl),
                  child: Column(
                    children: [
                      const LedgerFintechEmptyIllustration(width: 176),
                      const SizedBox(height: MfSpace.lg),
                      Container(
                        padding: const EdgeInsets.all(MfSpace.md),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(MfRadius.md),
                        ),
                        child: Icon(icon, size: 26, color: cs.primary),
                      ),
                      const SizedBox(height: MfSpace.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: MfSpace.sm),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.55),
                          height: 1.45,
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: MfSpace.xl),
                        FilledButton.icon(
                          onPressed: onAction,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(actionLabel!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
