import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'money_flow_tokens.dart';

ColorScheme _lightScheme() {
  const p = MfPalette.primaryDark;
  return const ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF059669),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD1FAE5),
    onPrimaryContainer: Color(0xFF064E3B),
    secondary: Color(0xFF34D399),
    onSecondary: Color(0xFF022C1A),
    secondaryContainer: Color(0xFFCCFBEF),
    onSecondaryContainer: Color(0xFF065F46),
    tertiary: MfPalette.warningAmber,
    onTertiary: Color(0xFF422006),
    tertiaryContainer: Color(0xFFFFE7C2),
    onTertiaryContainer: Color(0xFF713F12),
    error: MfPalette.expenseRed,
    onError: Colors.white,
    surface: Color(0xFFF0FDF4),
    onSurface: Color(0xFF0A0F0D),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFE7F8EE),
    surfaceContainer: Color(0xFFD7F2E1),
    surfaceContainerHigh: Color(0xFFC5E8D3),
    surfaceContainerHighest: Color(0xFFACD7BF),
    outline: Color(0xFFB8D7C3),
    outlineVariant: Color(0xFFD6E9DC),
    shadow: Color(0xFF0A0F0D),
    scrim: Colors.black54,
    inverseSurface: Color(0xFF111A14),
    onInverseSurface: Color(0xFFF0FDF4),
    inversePrimary: Color(0xFF34D399),
    surfaceTint: p,
    surfaceDim: Color(0xFFDCEFE4),
    surfaceBright: Colors.white,
  );
}

ColorScheme _darkScheme() {
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF10B981),
    onPrimary: Color(0xFF022C1A),
    primaryContainer: Color(0xFF065F46),
    onPrimaryContainer: Color(0xFFD1FAE5),
    secondary: Color(0xFF34D399),
    onSecondary: Color(0xFF022C1A),
    secondaryContainer: Color(0xFF1A2B1E),
    onSecondaryContainer: Color(0xFFD1FAE5),
    tertiary: Color(0xFFFBBF24),
    onTertiary: Color(0xFF431407),
    tertiaryContainer: Color(0xFF6B2D0B),
    onTertiaryContainer: Color(0xFFFFDBCC),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    surface: Color(0xFF0A0F0D),
    onSurface: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFF060D08),
    surfaceContainerLow: Color(0xFF111A14),
    surfaceContainer: Color(0x1A34D399),
    surfaceContainerHigh: Color(0xFF1A2B1E),
    surfaceContainerHighest: Color(0xFF25402F),
    outline: Color(0x2634D399),
    outlineVariant: Color(0x1434D399),
    shadow: Colors.black,
    scrim: Color(0xCC000000),
    inverseSurface: Color(0xFFF0FDF4),
    onInverseSurface: Color(0xFF0A0F0D),
    inversePrimary: Color(0xFF059669),
    surfaceTint: Color(0xFF10B981),
    surfaceDim: Color(0xFF060D08),
    surfaceBright: Color(0xFF1A2B1E),
  );
}

TextTheme _textTheme(ColorScheme cs, Brightness b) {
  final base = ThemeData(brightness: b, colorScheme: cs).textTheme;
  final dmSans = GoogleFonts.dmSansTextTheme(base);

  return dmSans.copyWith(
    displayLarge: GoogleFonts.dmSans(
      textStyle: dmSans.displayLarge,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
    displayMedium: GoogleFonts.dmSans(
      textStyle: dmSans.displayMedium,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
    displaySmall: GoogleFonts.dmSans(
      textStyle: dmSans.displaySmall,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
    headlineLarge: GoogleFonts.dmSans(
      textStyle: dmSans.headlineLarge,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
    headlineMedium: GoogleFonts.dmSans(
      textStyle: dmSans.headlineMedium,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
    headlineSmall: GoogleFonts.dmSans(
      textStyle: dmSans.headlineSmall,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    ),
    titleLarge: GoogleFonts.dmSans(
      textStyle: dmSans.titleLarge,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    ),
    titleMedium: GoogleFonts.dmSans(
      textStyle: dmSans.titleMedium,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    ),
    titleSmall: GoogleFonts.dmSans(
      textStyle: dmSans.titleSmall,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    ),
    bodyLarge: GoogleFonts.dmSans(
      textStyle: dmSans.bodyLarge,
      color: cs.onSurface,
    ),
    bodyMedium: GoogleFonts.dmSans(
      textStyle: dmSans.bodyMedium,
      color: cs.onSurface,
    ),
    bodySmall: GoogleFonts.dmSans(
      textStyle: dmSans.bodySmall,
      fontSize: 12,
      color: cs.onSurface.withValues(alpha: 0.65),
    ),
    labelLarge: GoogleFonts.dmSans(
      textStyle: dmSans.labelLarge,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: GoogleFonts.dmMono(
      textStyle: dmSans.labelMedium,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.dmMono(
      textStyle: dmSans.labelSmall,
      fontSize: 11,
      fontWeight: FontWeight.w400,
    ),
  );
}

InputDecorationTheme _inputTheme(ColorScheme cs) {
  return InputDecorationTheme(
    filled: true,
    fillColor: cs.surfaceContainerLowest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(
        color: cs.primary.withValues(alpha: 0.85),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.error.withValues(alpha: 0.6)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: MfSpace.lg,
      vertical: MfSpace.md + 2,
    ),
    labelStyle: GoogleFonts.dmSans(color: cs.onSurface.withValues(alpha: 0.65)),
    floatingLabelStyle: GoogleFonts.dmSans(
      color: cs.primary,
      fontWeight: FontWeight.w600,
    ),
  );
}

ThemeData _buildTheme(ColorScheme colorScheme, MoneyFlowThemeExtension mf) {
  final textTheme = _textTheme(colorScheme, colorScheme.brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    extensions: [mf],
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MfRadius.md),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: _inputTheme(colorScheme),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      disabledColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.35,
      ),
      labelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      secondaryLabelStyle: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: MfSpace.md,
        vertical: MfSpace.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MfRadius.sm + 4),
      ),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
      brightness: colorScheme.brightness,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          vertical: MfSpace.md + 2,
          horizontal: MfSpace.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MfRadius.md),
        ),
        textStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          vertical: MfSpace.md + 2,
          horizontal: MfSpace.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MfRadius.md),
        ),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MfRadius.sm),
        ),
        textStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 2,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MfRadius.lg),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 72,
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.55),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.2,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.45),
          size: 24,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: GoogleFonts.dmSans(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
      thickness: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
    ),
  );
}

ThemeData buildAppTheme() =>
    _buildTheme(_lightScheme(), MoneyFlowThemeExtension.light);

ThemeData buildAppDarkTheme() {
  final cs = _darkScheme();
  final base = _buildTheme(cs, MoneyFlowThemeExtension.dark);
  return base.copyWith(
    scaffoldBackgroundColor: MfPalette.phoneBg,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: MfPalette.phoneBg,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: MfPalette.cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MfRadius.lg),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 60,
      backgroundColor: const Color(0xF0111A14),
      indicatorColor: cs.primaryContainer.withValues(alpha: 0.24),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.2,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
          size: 24,
        );
      }),
    ),
  );
}

List<BoxShadow> ledgerAmbientFabShadows(ColorScheme cs) => [
  BoxShadow(
    offset: const Offset(0, 10),
    blurRadius: 28,
    color: cs.shadow.withValues(alpha: 0.08),
  ),
];
