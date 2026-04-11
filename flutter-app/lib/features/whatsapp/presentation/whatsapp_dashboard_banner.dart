import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/whatsapp_status_provider.dart';
import 'whatsapp_connect_screen.dart';

/// Soft, optional CTA — hidden when linked, offline, or status unknown (no warnings).
class WhatsappDashboardBanner extends ConsumerWidget {
  const WhatsappDashboardBanner({super.key});

  bool _connected(Map<String, dynamic> s) =>
      s['verified'] == true || s['connected'] == true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(whatsappLinkStatusProvider);

    return async.when(
      data: (raw) {
        if (raw == null || _connected(raw)) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const WhatsappConnectScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_rounded,
                      color: cs.primary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connect WhatsApp',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Optional — daily summaries & budget alerts on your phone',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object? error, StackTrace stackTrace) => const SizedBox.shrink(),
    );
  }
}
