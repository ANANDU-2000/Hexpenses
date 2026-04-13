import 'package:flutter/material.dart';

import '../theme/money_flow_tokens.dart';

/// Full-screen premium canvas: dark vertical gradient + soft neon / violet glows.
class PremiumFintechBackdrop extends StatelessWidget {
  const PremiumFintechBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: mfPremiumCanvasGradient)),
        Positioned(
          top: -130,
          right: -50,
          child: IgnorePointer(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MfPalette.neonGreen.withValues(alpha: 0.14),
                    MfPalette.neonGreen.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: -90,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MfPalette.accentSoftPurple.withValues(alpha: 0.12),
                    MfPalette.accentSoftPurple.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
