import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/money_flow_tokens.dart';

/// App bar for screens that sit on [PremiumFintechBackdrop].
///
/// On Flutter **web**, a fully transparent [AppBar] often composites over a
/// light material gap while still using **dark** [ColorScheme.onSurface] for
/// icons/title — yielding invisible chrome. This bar uses an explicit dark
/// fill, light foreground, and a visible back affordance when the route can pop.
class PremiumFintechAppBar {
  PremiumFintechAppBar._();

  static TextStyle titleTextStyle() => GoogleFonts.manrope(
        fontWeight: FontWeight.w800,
        fontSize: 22,
        color: MfPalette.textPrimary,
      );

  /// Prefer this over a raw [AppBar] on premium canvas screens.
  static PreferredSizeWidget bar({
    required BuildContext context,
    String? title,
    Widget? titleWidget,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Widget? leading,
    bool showBackWhenCanPop = true,
  }) {
    assert(
      title != null || titleWidget != null,
      'Provide title or titleWidget',
    );

    final canPop = Navigator.of(context).canPop();
    final Widget? effectiveLeading = leading ??
        (showBackWhenCanPop && canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null);

    return AppBar(
      leading: effectiveLeading,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: titleWidget ??
          Text(
            title!,
            style: titleTextStyle(),
          ),
      actions: actions,
      bottom: bottom,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MfPalette.canvasGradientTop.withValues(alpha: 0.96),
              MfPalette.canvasGradientBottom.withValues(alpha: 0.88),
            ],
          ),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      forceMaterialTransparency: true,
      foregroundColor: MfPalette.textPrimary,
      iconTheme: const IconThemeData(color: MfPalette.textPrimary),
      actionsIconTheme: const IconThemeData(color: MfPalette.textPrimary),
      titleTextStyle: titleTextStyle(),
    );
  }
}
