import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/money_flow_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: MfMotion.fast);
    _scale = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = widget.onPressed == null || widget.loading;

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedOpacity(
          duration: MfMotion.fast,
          opacity: disabled ? 0.55 : 1,
          child: switch (widget.variant) {
            AppButtonVariant.primary => _Primary(
              label: widget.label,
              icon: widget.icon,
              loading: widget.loading,
              expand: widget.expand,
              onPressed: disabled ? null : widget.onPressed,
            ),
            AppButtonVariant.secondary => _Secondary(
              label: widget.label,
              icon: widget.icon,
              loading: widget.loading,
              expand: widget.expand,
              onPressed: disabled ? null : widget.onPressed,
              cs: cs,
            ),
            AppButtonVariant.ghost => _Ghost(
              label: widget.label,
              icon: widget.icon,
              loading: widget.loading,
              expand: widget.expand,
              onPressed: disabled ? null : widget.onPressed,
              cs: cs,
            ),
          },
        ),
      ),
    );
  }
}

class _Primary extends StatelessWidget {
  const _Primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: cs.onPrimary),
                const SizedBox(width: MfSpace.sm),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: cs.onPrimary,
                ),
              ),
            ],
          );

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: expand
            ? const Size(double.infinity, 52)
            : const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: MfSpace.xl,
          vertical: MfSpace.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MfRadius.md),
        ),
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      child: child,
    );
  }
}

class _Secondary extends StatelessWidget {
  const _Secondary({
    required this.label,
    required this.onPressed,
    required this.cs,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final ColorScheme cs;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: MfSpace.sm),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: cs.primary,
                ),
              ),
            ],
          );

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: expand
            ? const Size(double.infinity, 52)
            : const Size(0, 52),
        padding: const EdgeInsets.symmetric(
          horizontal: MfSpace.xl,
          vertical: MfSpace.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MfRadius.md),
        ),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        foregroundColor: cs.primary,
      ),
      child: child,
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost({
    required this.label,
    required this.onPressed,
    required this.cs,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final ColorScheme cs;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.75),
                ),
                const SizedBox(width: MfSpace.sm),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          );

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: expand
            ? const Size(double.infinity, 48)
            : const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MfRadius.sm),
        ),
      ),
      child: child,
    );
  }
}
