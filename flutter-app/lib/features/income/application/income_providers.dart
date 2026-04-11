import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../data/incomes_api.dart';

final incomesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  if (kNoApiMode) {
    return const <Map<String, dynamic>>[];
  }
  return ref.watch(incomesApiProvider).list();
});
