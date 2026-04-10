import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/ledger_ui.dart';
import '../application/notification_providers.dart';
import '../data/notifications_api.dart';
import '../notification_categories.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final asyncList = ref.watch(notificationsListProvider);
    final filters = ref.watch(notificationFiltersProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ref.read(notificationsApiProvider).markAllRead();
                ref.invalidate(notificationsListProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All marked as read')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not update: $e')),
                  );
                }
              }
            },
            child: Text('Mark all read', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: LedgerSectionLayer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filters', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Unread only'),
                          selected: filters.unreadOnly,
                          onSelected: (v) {
                            ref.read(notificationFiltersProvider.notifier).setUnreadOnly(v);
                            ref.invalidate(notificationsListProvider);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('All types'),
                          selected: filters.category == null,
                          onSelected: (_) {
                            ref.read(notificationFiltersProvider.notifier).setCategory(null);
                            ref.invalidate(notificationsListProvider);
                          },
                        ),
                        ...kNotificationCategoryValues.map(
                          (c) => ChoiceChip(
                            label: Text(c),
                            selected: filters.category == c,
                            onSelected: (_) {
                              ref.read(notificationFiltersProvider.notifier).setCategory(c);
                              ref.invalidate(notificationsListProvider);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: asyncList.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(notificationsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      final id = row['id'] as String? ?? '';
                      final title = row['title'] as String? ?? '';
                      final body = row['body'] as String? ?? '';
                      final category = row['category'] as String? ?? '';
                      final readAt = row['readAt'];
                      final unread = readAt == null;
                      final created = row['createdAt'] as String?;
                      DateTime? dt;
                      if (created != null) {
                        dt = DateTime.tryParse(created);
                      }
                      final subtitle = dt != null
                          ? DateFormat.yMMMd().add_jm().format(dt.toLocal())
                          : '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LedgerStaggerItem(
                          marginBottom: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: unread && id.isNotEmpty
                                  ? () async {
                                      try {
                                        await ref.read(notificationsApiProvider).markRead(id);
                                        ref.invalidate(notificationsListProvider);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Could not mark read: $e')),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6, right: 12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: unread ? cs.primary : cs.outline.withValues(alpha: 0.35),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                                      ),
                                                ),
                                              ),
                                              if (category.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: cs.primaryContainer.withValues(alpha: 0.55),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    category,
                                                    style: Theme.of(context).textTheme.labelSmall,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (body.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              body,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: cs.onSurface.withValues(alpha: 0.85),
                                                  ),
                                            ),
                                          ],
                                          if (subtitle.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              subtitle,
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: cs.onSurface.withValues(alpha: 0.45),
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
            ),
          ),
        ],
      ),
    );
  }
}
