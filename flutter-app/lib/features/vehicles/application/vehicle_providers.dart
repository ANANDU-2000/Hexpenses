import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/vehicles_api.dart';

final vehiclesListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(vehiclesApiProvider).list();
});
