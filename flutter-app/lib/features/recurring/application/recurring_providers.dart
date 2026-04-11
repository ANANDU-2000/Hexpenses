import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../data/recurring_api.dart';

final recurringListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      if (kNoApiMode) {
        return const <Map<String, dynamic>>[];
      }
      return ref.watch(recurringApiProvider).list();
    });
