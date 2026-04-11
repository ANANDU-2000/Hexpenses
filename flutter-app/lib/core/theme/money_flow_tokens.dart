import 'package:flutter/material.dart';

/// MoneyFlow AI - spacing, radii, motion.
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
  // Canvas
  static const Color canvas = Color(0xFF0A0F0D);
  static const Color phoneBg = Color(0xFF0A0F0D);
  static const Color cardBg = Color(0xCC111A14);
  static const Color cardBorder = Color(0x2634D399);

  // Brand
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryGlow = Color(0xFF6EE7B7);

  // Semantic
  static const Color incomeGreen = Color(0xFF34D399);
  static const Color expenseRed = Color(0xFFF87171);
  static const Color warningAmber = Color(0xFFFBBF24);

  // Hero card gradient stops
  static const Color heroStart = Color(0xFF10B981);
  static const Color heroMid = Color(0xFF0B8A65);
  static const Color heroEnd = Color(0xFF059669);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xB3E5F7EF);
  static const Color textHint = Color(0x66D1FAE5);

  // Legacy aliases (keep for non-redesigned screens)
  static const Color lightBg = Color(0xFFF0FDF4);
  static const Color lightBgElevated = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFF4B6355);
  static const Color darkBg = Color(0xFF0A0F0D);
  static const Color darkBgElevated = Color(0xFF111A14);
  static const Color darkMuted = Color(0xFF8DA89A);

  /// Backwards-compatible names used by older widgets / light theme.
  static const Color success = incomeGreen;
  static const Color error = expenseRed;
  static const Color warning = warningAmber;
}

/// Indian Rupee symbol - use everywhere instead of hardcoded literals.
abstract final class MfCurrency {
  static const String symbol = '\u20B9';

  static String format(num value) =>
      '$symbol${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';

  static String formatCompact(num value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    if (abs >= 10000000) {
      final crore = abs / 10000000;
      final digits = crore == crore.truncateToDouble() ? 0 : 1;
      return '$sign$symbol${crore.toStringAsFixed(digits)}Cr';
    }
    if (abs >= 100000) {
      final lakh = abs / 100000;
      final digits = lakh == lakh.truncateToDouble() ? 0 : 1;
      return '$sign$symbol${lakh.toStringAsFixed(digits)}L';
    }
    return format(value);
  }
}

const String kCurrencySymbol = MfCurrency.symbol;

/// Glass card decoration - use for ALL card widgets.
BoxDecoration glassCard({
  Color? color,
  double borderRadius = MfRadius.lg,
  Color? borderColor,
}) => BoxDecoration(
  color: color ?? MfPalette.cardBg,
  borderRadius: BorderRadius.circular(borderRadius),
  border: Border.all(color: borderColor ?? MfPalette.cardBorder, width: 1),
);

/// Hero gradient - for balance/summary cards.
BoxDecoration heroCardDecoration() => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MfPalette.heroStart, MfPalette.heroMid, MfPalette.heroEnd],
    stops: [0.0, 0.6, 1.0],
  ),
  borderRadius: BorderRadius.circular(MfRadius.xl),
  border: Border.all(color: const Color(0x2634D399), width: 1),
);

LinearGradient incomeGradient() => LinearGradient(
  colors: [
    MfPalette.incomeGreen.withValues(alpha: 0.85),
    MfPalette.incomeGreen.withValues(alpha: 0.50),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

LinearGradient expenseGradient(Color categoryColor) => LinearGradient(
  colors: [
    categoryColor.withValues(alpha: 0.85),
    categoryColor.withValues(alpha: 0.50),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

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
    success: MfPalette.incomeGreen,
    onSuccess: Colors.white,
    warning: MfPalette.warningAmber,
    glassOpacity: 0.72,
  );

  static const dark = MoneyFlowThemeExtension(
    success: MfPalette.incomeGreen,
    onSuccess: Color(0xFF022C1A),
    warning: MfPalette.warningAmber,
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
  MoneyFlowThemeExtension lerp(
    ThemeExtension<MoneyFlowThemeExtension>? other,
    double t,
  ) {
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
  MoneyFlowThemeExtension get mf =>
      Theme.of(this).extension<MoneyFlowThemeExtension>() ??
      MoneyFlowThemeExtension.light;
}
