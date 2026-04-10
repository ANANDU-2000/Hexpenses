import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/insights_api.dart';

final aiInsightsProvider = FutureProvider.autoDispose<AiInsightsPayload>((ref) {
  return ref.watch(insightsApiProvider).fetch();
});
