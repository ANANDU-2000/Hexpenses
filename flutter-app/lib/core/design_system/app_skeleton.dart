import 'package:flutter/material.dart';

import '../theme/money_flow_tokens.dart';

/// Shimmer-style loading placeholder.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, required this.child, this.borderRadius});

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 + t * 2, 0),
              colors: [
                cs.surfaceContainerHighest.withValues(alpha: 0.35),
                cs.surfaceContainerHigh.withValues(alpha: 0.85),
                cs.surfaceContainerHighest.withValues(alpha: 0.35),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class DashboardHeaderSkeleton extends StatelessWidget {
  const DashboardHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget bar(double h, {double w = double.infinity}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(MfRadius.sm),
      ),
    );

    return AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(14, w: 160),
          const SizedBox(height: MfSpace.lg),
          bar(40, w: 220),
          const SizedBox(height: MfSpace.sm),
          bar(18, w: 140),
        ],
      ),
    );
  }
}

class TransactionListSkeleton extends StatelessWidget {
  const TransactionListSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: MfSpace.md),
          child: AppSkeleton(
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(MfRadius.md),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
