import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/insurance_api.dart';

final insuranceListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(insuranceApiProvider).list();
});
