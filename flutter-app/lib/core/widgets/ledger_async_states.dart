import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ledger_tokens.dart';

class LedgerDashboardSkeleton extends StatelessWidget {
  const LedgerDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: LedgerGap.lg),
        LinearProgressIndicator(color: cs.primary, minHeight: 3),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: LedgerGap.sm),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.65)),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: LedgerGap.md),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ],
      ),
    );
  }
}

/// Placeholder block for bar / pie chart areas while loading.
class LedgerChartSkeleton extends StatelessWidget {
  const LedgerChartSkeleton({super.key, this.height = 200});

  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
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
            height: 56,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LedgerGap.xxl, horizontal: LedgerGap.lg),
      child: Column(
        children: [
          Icon(icon, size: 48, color: cs.outline.withValues(alpha: 0.6)),
          const SizedBox(height: LedgerGap.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: LedgerGap.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.55),
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: LedgerGap.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
