import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/investments_api.dart';

final investmentPortfolioProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  return ref.watch(investmentsApiProvider).fetchPortfolio();
});
