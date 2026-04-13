import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/dio_errors.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../../core/widgets/premium_fintech_app_bar.dart';
import '../../../core/widgets/premium_fintech_backdrop.dart';
import '../application/notification_providers.dart';
import '../data/notifications_api.dart';
import '../notification_categories.dart';

IconData _notificationCategoryIcon(String? category) {
  switch (category?.toLowerCase()) {
    case 'insurance':
      return Icons.receipt_long_rounded;
    case 'emi':
      return Icons.account_balance_wallet_rounded;
    case 'recurring':
      return Icons.event_repeat_rounded;
    case 'ai':
      return Icons.auto_awesome_rounded;
    case 'system':
      return Icons.notifications_active_rounded;
    default:
      return Icons.notifications_none_rounded;
  }
}

List<Color> _notificationIconGradient(String? category) {
  switch (category?.toLowerCase()) {
    case 'insurance':
      return [const Color(0xFF6366F1), MfPalette.accentSoftPurple];
    case 'emi':
      return [const Color(0xFF0D9488), MfPalette.incomeGreen];
    case 'recurring':
      return [const Color(0xFFF59E0B), const Color(0xFFEA580C)];
    case 'ai':
      return [const Color(0xFF7C3AED), const Color(0xFFEC4899)];
    case 'system':
      return [const Color(0xFF64748B), const Color(0xFF334155)];
    default:
      return [MfPalette.accentSoftPurple, const Color(0xFF4F46E5)];
  }
}

String _categoryChipLabel(String raw) {
  if (raw.isEmpty) return raw;
  return raw[0].toUpperCase() + raw.substring(1);
}

String _formatNotificationTime(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.isNegative) return DateFormat.yMMMd().add_jm().format(local);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat.yMMMd().add_jm().format(local);
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final asyncList = ref.watch(notificationsListProvider);
    final filters = ref.watch(notificationFiltersProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: PremiumFintechAppBar.bar(
        context: context,
        title: 'Notifications',
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumFintechBackdrop(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 4, MfSpace.xxl, MfSpace.md),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await ref.read(notificationsApiProvider).markAllRead();
                      ref.invalidate(notificationsListProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: const Text('All notifications marked as read'),
                          ),
                        );
                      }
                    } on DioException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(dioErrorMessage(e)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Could not update: $e'),
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.done_all_rounded, color: cs.primary, size: 20),
                  label: Text(
                    'Mark all as read',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: MfSpace.md,
                      horizontal: MfSpace.lg,
                    ),
                    side: BorderSide(
                      color: MfPalette.accentSoftPurple.withValues(alpha: 0.45),
                    ),
                    foregroundColor: cs.onSurface,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 0, MfSpace.xxl, MfSpace.sm),
                child: Text(
                  'Filters',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: cs.onSurface.withValues(alpha: 0.48),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 0, MfSpace.xxl, MfSpace.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChipStyled(
                        label: 'Unread',
                        selected: filters.unreadOnly,
                        onSelected: (v) {
                          ref.read(notificationFiltersProvider.notifier).setUnreadOnly(v);
                          ref.invalidate(notificationsListProvider);
                        },
                        useCheckmark: true,
                      ),
                      const SizedBox(width: MfSpace.sm),
                      _FilterChipStyled(
                        label: 'All',
                        selected: filters.category == null,
                        onSelected: (_) {
                          ref.read(notificationFiltersProvider.notifier).setCategory(null);
                          ref.invalidate(notificationsListProvider);
                        },
                        useCheckmark: false,
                      ),
                      ...kNotificationCategoryValues.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: MfSpace.sm),
                          child: _FilterChipStyled(
                            label: _categoryChipLabel(c),
                            selected: filters.category == c,
                            onSelected: (_) {
                              ref.read(notificationFiltersProvider.notifier).setCategory(c);
                              ref.invalidate(notificationsListProvider);
                            },
                            useCheckmark: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: asyncList.when(
                  data: (rows) {
                    if (rows.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          MfSpace.xxl,
                          24,
                          MfSpace.xxl,
                          120,
                        ),
                        children: const [
                          _NotificationsEmptyState(),
                        ],
                      );
                    }
                    return RefreshIndicator(
                      color: MfPalette.neonGreen,
                      backgroundColor: cs.surfaceContainerLow,
                      onRefresh: () async {
                        ref.invalidate(notificationsListProvider);
                        await ref.read(notificationsListProvider.future);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          MfSpace.xxl,
                          0,
                          MfSpace.xxl,
                          120,
                        ),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final row = rows[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: MfSpace.md),
                            child: _NotificationCard(
                              row: row,
                              onTapMarkRead: () async {
                                final id = row['id']?.toString() ?? '';
                                if (id.isEmpty) return;
                                try {
                                  await ref.read(notificationsApiProvider).markRead(id);
                                  ref.invalidate(notificationsListProvider);
                                } on DioException catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(dioErrorMessage(e)),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(MfSpace.xxl),
                    child: LedgerErrorState(
                      title: 'Could not load notifications',
                      message: e is DioException ? dioErrorMessage(e) : e.toString(),
                      onRetry: () => ref.invalidate(notificationsListProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChipStyled extends StatelessWidget {
  const _FilterChipStyled({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.useCheckmark,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final bool useCheckmark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      selected: selected,
      showCheckmark: useCheckmark,
      checkmarkColor: MfPalette.neonGreen,
      selectedColor: MfPalette.accentSoftPurple.withValues(alpha: 0.28),
      backgroundColor: cs.surfaceContainerHigh.withValues(alpha: 0.55),
      disabledColor: cs.surfaceContainerHigh.withValues(alpha: 0.35),
      side: BorderSide(
        color: selected
            ? MfPalette.neonGreen.withValues(alpha: 0.55)
            : cs.outlineVariant.withValues(alpha: 0.35),
        width: selected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
      onSelected: onSelected,
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.row,
    required this.onTapMarkRead,
  });

  final Map<String, dynamic> row;
  final Future<void> Function() onTapMarkRead;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = row['id']?.toString() ?? '';
    final title = row['title']?.toString() ?? '';
    final body = row['body']?.toString() ?? '';
    final category = row['category']?.toString() ?? '';
    final readAt = row['readAt'];
    final unread = readAt == null;
    final created = row['createdAt']?.toString();
    final dt = created != null ? DateTime.tryParse(created) : null;
    final timeStr = _formatNotificationTime(dt);
    final grads = _notificationIconGradient(category);
    final icon = _notificationCategoryIcon(category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unread && id.isNotEmpty ? () => onTapMarkRead() : null,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        splashColor: MfPalette.accentSoftPurple.withValues(alpha: 0.08),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppCard(
              glass: true,
              padding: const EdgeInsets.all(MfSpace.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(MfRadius.md),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: grads,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: grads.last.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: MfSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                                  height: 1.25,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            if (category.isNotEmpty) ...[
                              const SizedBox(width: MfSpace.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: MfSpace.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _categoryChipLabel(category),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: MfSpace.sm),
                          Text(
                            body,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withValues(alpha: unread ? 0.78 : 0.62),
                            ),
                          ),
                        ],
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(height: MfSpace.md),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 15,
                                color: cs.onSurface.withValues(alpha: 0.42),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.48),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Positioned(
                top: 12,
                right: 14,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MfPalette.accentSoftPurple,
                    boxShadow: [
                      BoxShadow(
                        color: MfPalette.accentSoftPurple.withValues(alpha: 0.65),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(MfSpace.xxl),
      child: Column(
        children: [
          const _NotificationsEmptyIllustration(width: 200),
          const SizedBox(height: MfSpace.xl),
          Icon(
            Icons.celebration_rounded,
            size: 36,
            color: MfPalette.neonGreen,
          ),
          const SizedBox(height: MfSpace.md),
          Text(
            "You're all caught up 🎉",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'No alerts right now. Bills, renewals, and AI tips will show up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsEmptyIllustration extends StatelessWidget {
  const _NotificationsEmptyIllustration({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.52;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(painter: _NotificationsEmptyPainter()),
    );
  }
}

class _NotificationsEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bell = Path()
      ..moveTo(w * 0.42, h * 0.18)
      ..quadraticBezierTo(w * 0.5, h * 0.08, w * 0.58, h * 0.18)
      ..lineTo(w * 0.62, h * 0.52)
      ..quadraticBezierTo(w * 0.65, h * 0.62, w * 0.55, h * 0.68)
      ..lineTo(w * 0.45, h * 0.68)
      ..quadraticBezierTo(w * 0.35, h * 0.62, w * 0.38, h * 0.52)
      ..close();
    canvas.drawPath(
      bell,
      Paint()
        ..shader = LinearGradient(
          colors: [
            MfPalette.accentSoftPurple.withValues(alpha: 0.85),
            MfPalette.neonGreen.withValues(alpha: 0.45),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      bell,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.25),
    );
    // Check badge
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.28),
      w * 0.1,
      Paint()..color = MfPalette.incomeGreen.withValues(alpha: 0.95),
    );
    final check = Path()
      ..moveTo(w * 0.66, h * 0.28)
      ..lineTo(w * 0.71, h * 0.34)
      ..lineTo(w * 0.79, h * 0.22);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Confetti dots
    final dots = [
      Offset(w * 0.18, h * 0.35),
      Offset(w * 0.85, h * 0.55),
      Offset(w * 0.22, h * 0.72),
    ];
    final dotColors = [
      MfPalette.neonGreen,
      MfPalette.accentSoftPurple,
      MfPalette.warningAmber,
    ];
    for (var i = 0; i < dots.length; i++) {
      canvas.drawCircle(dots[i], 4, Paint()..color = dotColors[i].withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
