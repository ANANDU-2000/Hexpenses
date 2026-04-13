import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// MoneyFlow AI - spacing, radii, motion.
abstract final class MfRadius {
  static const double sm = 12;
  static const double md = 16;
  /// Primary cards, tiles (premium fintech spec: 20px).
  static const double lg = 20;
  static const double xl = 28;
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
  static const Duration slow = Duration(milliseconds: 460);
  static const Curve curve = Curves.easeOutCubic;
}

/// Brand + semantic colors (use with [ColorScheme] in theme).
abstract final class MfPalette {
  // Canvas — premium dark gradient endpoints
  static const Color canvasGradientTop = Color(0xFF0B1220);
  static const Color canvasGradientBottom = Color(0xFF0E1A2B);
  static const Color canvas = canvasGradientTop;
  static const Color phoneBg = canvasGradientBottom;
  static const Color cardBg = Color(0x1AFFFFFF);
  static const Color cardBorder = Color(0x24FFFFFF);

  /// Secondary accent (CTAs, glows, selected chrome).
  static const Color accentSoftPurple = Color(0xFF8B9CFF);

  // Brand
  static const Color primary = Color(0xFF000B60);
  static const Color primaryDark = Color(0xFF000844);
  static const Color primaryLight = Color(0xFF2236A8);
  static const Color primaryGlow = accentSoftPurple;

  /// Premium fintech neon accent (shell, CTAs, highlights).
  static const Color neonGreen = Color(0xFFE6FF4D);
  static const Color neonGreenSoft = Color(0xFFF3FD6F);
  static const Color onNeonGreen = Color(0xFF0D0D0D);

  // Semantic (master design spec)
  static const Color incomeGreen = Color(0xFF22C697);
  static const Color expenseRed = Color(0xFFF07070);
  static const Color warningAmber = Color(0xFFF4A83A);
  static const Color insightBlue = Color(0xFF4B79F8);

  // Hero card gradient stops
  static const Color heroStart = Color(0xFF000B60);
  static const Color heroMid = Color(0xFF142283);
  static const Color heroEnd = Color(0xFF3F68FF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xB3EDF1FF);
  static const Color textHint = Color(0x66EDF1FF);

  // Legacy aliases (keep for non-redesigned screens)
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightBgElevated = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFF5D6471);
  static const Color darkBg = canvasGradientTop;
  static const Color darkBgElevated = Color(0xFF131D32);
  static const Color darkMuted = Color(0xFF98A3C5);

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

  /// Indian grouping + ₹ (en_IN). Use for API/map numeric strings shown in UI.
  static String formatInr(dynamic raw) {
    final n = double.tryParse(raw?.toString() ?? '0') ?? 0;
    final digits = n == n.roundToDouble() ? 0 : 2;
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: digits,
    ).format(n);
  }
}

const String kCurrencySymbol = MfCurrency.symbol;

/// Global vertical canvas gradient (dark shell / home / lists).
const LinearGradient mfPremiumCanvasGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    MfPalette.canvasGradientTop,
    MfPalette.canvasGradientBottom,
  ],
);

/// Glass card decoration - use for premium list and summary cards.
BoxDecoration glassCard({
  Color? color,
  double borderRadius = MfRadius.lg,
  Color? borderColor,
}) => BoxDecoration(
  color: color ?? MfPalette.cardBg,
  borderRadius: BorderRadius.circular(borderRadius),
  border: Border.all(color: borderColor ?? const Color(0x26FFFFFF), width: 1),
  boxShadow: [
    BoxShadow(
      color: MfPalette.accentSoftPurple.withValues(alpha: 0.07),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    const BoxShadow(
      offset: Offset(0, 18),
      blurRadius: 48,
      color: Color(0x12000B60),
    ),
    const BoxShadow(
      offset: Offset(0, 6),
      blurRadius: 18,
      color: Color(0x100C152F),
    ),
  ],
);

/// Hero gradient - for balance/summary cards.
BoxDecoration heroCardDecoration() => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MfPalette.heroStart, MfPalette.heroMid, MfPalette.heroEnd],
    stops: [0.0, 0.58, 1.0],
  ),
  borderRadius: BorderRadius.circular(MfRadius.xl),
  border: Border.all(color: const Color(0x24FFFFFF), width: 1),
  boxShadow: const [
    BoxShadow(offset: Offset(0, 28), blurRadius: 52, color: Color(0x33000B60)),
  ],
);

LinearGradient incomeGradient() => LinearGradient(
  colors: [
    MfPalette.incomeGreen.withValues(alpha: 0.96),
    MfPalette.incomeGreen.withValues(alpha: 0.62),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

LinearGradient expenseGradient(Color categoryColor) => LinearGradient(
  colors: [
    categoryColor.withValues(alpha: 0.94),
    categoryColor.withValues(alpha: 0.58),
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
    glassOpacity: 0.78,
  );

  static const dark = MoneyFlowThemeExtension(
    success: MfPalette.incomeGreen,
    onSuccess: Color(0xFF06120E),
    warning: MfPalette.warningAmber,
    glassOpacity: 0.52,
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
