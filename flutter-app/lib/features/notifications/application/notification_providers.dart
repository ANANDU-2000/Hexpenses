import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_api.dart';

/// In-memory filters for the notifications list screen.
class NotificationListFilters {
  const NotificationListFilters({
    this.category,
    this.unreadOnly = false,
  });

  final String? category;
  final bool unreadOnly;

  NotificationListFilters copyWith({
    String? category,
    bool? unreadOnly,
    bool clearCategory = false,
  }) {
    return NotificationListFilters(
      category: clearCategory ? null : (category ?? this.category),
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

class NotificationFiltersNotifier extends Notifier<NotificationListFilters> {
  @override
  NotificationListFilters build() => const NotificationListFilters();

  void setCategory(String? v) {
    if (v == null || v.isEmpty) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(category: v);
    }
  }

  void setUnreadOnly(bool v) {
    state = state.copyWith(unreadOnly: v);
  }
}

final notificationFiltersProvider =
    NotifierProvider<NotificationFiltersNotifier, NotificationListFilters>(
  NotificationFiltersNotifier.new,
);

final notificationsListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(notificationsApiProvider);
  final f = ref.watch(notificationFiltersProvider);
  return api.list(
    category: f.category,
    unreadOnly: f.unreadOnly ? true : null,
    limit: 100,
  );
});
