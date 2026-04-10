import 'package:flutter/material.dart';

/// MoneyFlow AI — spacing, radii, motion (Stripe / Linear–inspired rhythm).
abstract final class MfRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
}

abstract final class MfSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

abstract final class MfMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeOutCubic;
}

/// Brand + semantic colors (use with [ColorScheme] in theme).
abstract final class MfPalette {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightBgElevated = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFF64748B);

  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkBgElevated = Color(0xFF1E293B);
  static const Color darkMuted = Color(0xFF94A3B8);
}

/// Optional theme extension for widgets that need explicit semantic colors.
@immutable
class MoneyFlowThemeExtension extends ThemeExtension<MoneyFlowThemeExtension> {
  const MoneyFlowThemeExtension({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.glassOpacity,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final double glassOpacity;

  static const light = MoneyFlowThemeExtension(
    success: MfPalette.success,
    onSuccess: Colors.white,
    warning: MfPalette.warning,
    glassOpacity: 0.72,
  );

  static const dark = MoneyFlowThemeExtension(
    success: Color(0xFF34D399),
    onSuccess: Color(0xFF064E3B),
    warning: Color(0xFFFBBF24),
    glassOpacity: 0.55,
  );

  @override
  MoneyFlowThemeExtension copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    double? glassOpacity,
  }) {
    return MoneyFlowThemeExtension(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      glassOpacity: glassOpacity ?? this.glassOpacity,
    );
  }

  @override
  MoneyFlowThemeExtension lerp(ThemeExtension<MoneyFlowThemeExtension>? other, double t) {
    if (other is! MoneyFlowThemeExtension) return this;
    return MoneyFlowThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      glassOpacity: glassOpacity + (other.glassOpacity - glassOpacity) * t,
    );
  }
}

extension MoneyFlowThemeX on BuildContext {
  MoneyFlowThemeExtension get mf => Theme.of(this).extension<MoneyFlowThemeExtension>() ?? MoneyFlowThemeExtension.light;
}
