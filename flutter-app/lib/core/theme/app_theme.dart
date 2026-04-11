import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'money_flow_tokens.dart';

ColorScheme _lightScheme() {
  const p = MfPalette.primary;
  return ColorScheme(
    brightness: Brightness.light,
    primary: p,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE0E7FF),
    onPrimaryContainer: const Color(0xFF312E81),
    secondary: const Color(0xFF6366F1),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFEEF2FF),
    onSecondaryContainer: const Color(0xFF3730A3),
    tertiary: MfPalette.warning,
    onTertiary: const Color(0xFF422006),
    tertiaryContainer: const Color(0xFFFFE7C2),
    onTertiaryContainer: const Color(0xFF713F12),
    error: MfPalette.error,
    onError: Colors.white,
    surface: MfPalette.lightBg,
    onSurface: const Color(0xFF0F172A),
    surfaceContainerLowest: MfPalette.lightBgElevated,
    surfaceContainerLow: const Color(0xFFF1F5F9),
    surfaceContainer: const Color(0xFFE2E8F0),
    surfaceContainerHigh: const Color(0xFFCBD5E1),
    surfaceContainerHighest: const Color(0xFF94A3B8),
    outline: const Color(0xFFCBD5E1),
    outlineVariant: const Color(0xFFE2E8F0),
    shadow: const Color(0xFF0F172A),
    scrim: Colors.black54,
    inverseSurface: MfPalette.darkBg,
    onInverseSurface: const Color(0xFFF8FAFC),
    inversePrimary: const Color(0xFFC7D2FE),
    surfaceTint: p,
    surfaceDim: const Color(0xFFCBD5E1),
    surfaceBright: Colors.white,
  );
}

ColorScheme _darkScheme() {
  const p = Color(0xFF818CF8);
  return ColorScheme(
    brightness: Brightness.dark,
    primary: p,
    onPrimary: const Color(0xFF1E1B4B),
    primaryContainer: const Color(0xFF3730A3),
    onPrimaryContainer: const Color(0xFFE0E7FF),
    secondary: const Color(0xFFA5B4FC),
    onSecondary: const Color(0xFF1E1B4B),
    secondaryContainer: const Color(0xFF312E81),
    onSecondaryContainer: const Color(0xFFE0E7FF),
    tertiary: const Color(0xFFFBBF24),
    onTertiary: const Color(0xFF422006),
    tertiaryContainer: const Color(0xFF713F12),
    onTertiaryContainer: const Color(0xFFFFE7C2),
    error: const Color(0xFFF87171),
    onError: const Color(0xFF450A0A),
    surface: MfPalette.darkBg,
    onSurface: const Color(0xFFF1F5F9),
    surfaceContainerLowest: const Color(0xFF020617),
    surfaceContainerLow: const Color(0xFF1E293B),
    surfaceContainer: const Color(0xFF334155),
    surfaceContainerHigh: const Color(0xFF475569),
    surfaceContainerHighest: const Color(0xFF64748B),
    outline: const Color(0xFF475569),
    outlineVariant: const Color(0xFF334155),
    shadow: Colors.black,
    scrim: Colors.black87,
    inverseSurface: MfPalette.lightBg,
    onInverseSurface: const Color(0xFF0F172A),
    inversePrimary: MfPalette.primary,
    surfaceTint: p,
    surfaceDim: const Color(0xFF0F172A),
    surfaceBright: const Color(0xFF334155),
  );
}

TextTheme _textTheme(ColorScheme cs, Brightness b) {
  final base = ThemeData(brightness: b, colorScheme: cs).textTheme;
  final jakarta = GoogleFonts.plusJakartaSansTextTheme(base);
  final inter = GoogleFonts.interTextTheme(jakarta);

  return inter.copyWith(
    displayLarge: GoogleFonts.plusJakartaSans(textStyle: jakarta.displayLarge, fontWeight: FontWeight.w700, color: cs.onSurface),
    displayMedium: GoogleFonts.plusJakartaSans(textStyle: jakarta.displayMedium, fontWeight: FontWeight.w700, color: cs.onSurface),
    displaySmall: GoogleFonts.plusJakartaSans(textStyle: jakarta.displaySmall, fontWeight: FontWeight.w700, color: cs.onSurface),
    headlineLarge: GoogleFonts.plusJakartaSans(textStyle: jakarta.headlineLarge, fontWeight: FontWeight.w700, color: cs.onSurface),
    headlineMedium: GoogleFonts.plusJakartaSans(textStyle: jakarta.headlineMedium, fontWeight: FontWeight.w700, color: cs.onSurface),
    headlineSmall: GoogleFonts.plusJakartaSans(textStyle: jakarta.headlineSmall, fontWeight: FontWeight.w700, color: cs.onSurface),
    titleLarge: GoogleFonts.plusJakartaSans(textStyle: jakarta.titleLarge, fontWeight: FontWeight.w600, color: cs.onSurface),
    titleMedium: GoogleFonts.plusJakartaSans(textStyle: jakarta.titleMedium, fontWeight: FontWeight.w600, color: cs.onSurface),
    titleSmall: GoogleFonts.plusJakartaSans(textStyle: jakarta.titleSmall, fontWeight: FontWeight.w600, color: cs.onSurface),
    bodyLarge: GoogleFonts.inter(textStyle: inter.bodyLarge, color: cs.onSurface),
    bodyMedium: GoogleFonts.inter(textStyle: inter.bodyMedium, color: cs.onSurface),
    bodySmall: GoogleFonts.inter(textStyle: inter.bodySmall?.copyWith(fontSize: 12), color: cs.onSurface.withValues(alpha: 0.75)),
    labelLarge: GoogleFonts.inter(textStyle: inter.labelLarge, fontWeight: FontWeight.w600),
    labelMedium: GoogleFonts.inter(textStyle: inter.labelMedium, fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: GoogleFonts.inter(textStyle: inter.labelSmall, fontSize: 11, fontWeight: FontWeight.w500),
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
      borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.85), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.error.withValues(alpha: 0.6)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(MfRadius.md),
      borderSide: BorderSide(color: cs.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: MfSpace.lg, vertical: MfSpace.md + 2),
    labelStyle: GoogleFonts.inter(color: cs.onSurface.withValues(alpha: 0.65)),
    floatingLabelStyle: GoogleFonts.inter(color: cs.primary, fontWeight: FontWeight.w600),
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
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: _inputTheme(colorScheme),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      disabledColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: MfSpace.md, vertical: MfSpace.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm + 4)),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      brightness: colorScheme.brightness,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: MfSpace.md + 2, horizontal: MfSpace.xl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: MfSpace.md + 2, horizontal: MfSpace.xl),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.55)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.sm)),
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 2,
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 72,
      backgroundColor: Colors.transparent,
      indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.55),
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.2,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        final selected = s.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.45),
          size: 24,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      // Fixed avoids "floating SnackBar off screen" when a child route has a FAB and the shell has a bottom bar.
      behavior: SnackBarBehavior.fixed,
      elevation: 0,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: GoogleFonts.inter(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.md)),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
      thickness: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),
  );
}

ThemeData buildAppTheme() => _buildTheme(_lightScheme(), MoneyFlowThemeExtension.light);

ThemeData buildAppDarkTheme() => _buildTheme(_darkScheme(), MoneyFlowThemeExtension.dark);

List<BoxShadow> ledgerAmbientFabShadows(ColorScheme cs) => [
      BoxShadow(
        offset: const Offset(0, 10),
        blurRadius: 28,
        color: cs.shadow.withValues(alpha: 0.08),
      ),
    ];
