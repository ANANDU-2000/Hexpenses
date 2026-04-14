import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../../../core/offline/no_api_dashboard.dart';
import '../../../core/offline/sync/ledger_sync_service.dart';
import '../data/reports_api.dart';
import '../../analytics/domain/analytics_filter.dart';

/// Calendar month and/or inclusive YYYY-MM-DD range for expense analytics API.
typedef ExpenseMvpQuery = ({
  int year,
  int month,
  String? fromYmd,
  String? toYmd,
});

final monthlySummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    if (kNoApiMode) {
      return buildOfflineMonthlySummary(ref.watch(ledgerDatabaseProvider));
    }
    return ref.watch(reportsApiProvider).monthlySummary();
  },
);

final dashboardOverviewProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      if (kNoApiMode) {
        return buildOfflineDashboardOverview(ref.watch(ledgerDatabaseProvider));
      }
      return ref.watch(reportsApiProvider).dashboard();
    });

final categoryBreakdownProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      if (kNoApiMode) {
        return buildOfflineCategoryBreakdown(ref.watch(ledgerDatabaseProvider));
      }
      return ref.watch(reportsApiProvider).categoryBreakdown();
    });

final taxSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  if (kNoApiMode) {
    return offlineTaxSummaryPlaceholder();
  }
  return ref.watch(reportsApiProvider).taxSummary(details: true);
});

final expenseMvpProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ExpenseMvpQuery>((ref, m) async {
      if (kNoApiMode) {
        return buildOfflineExpenseMvp(
          ref.watch(ledgerDatabaseProvider),
          m.year,
          m.month,
          fromYmd: m.fromYmd,
          toYmd: m.toYmd,
        );
      }
      return ref.watch(reportsApiProvider).expenseMvp(
            year: m.year,
            month: m.month,
            fromYmd: m.fromYmd,
            toYmd: m.toYmd,
            trendMonths: 12,
          );
    });

final analyticsDrilldownProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, AnalyticsFilter>((ref, f) async {
      if (kNoApiMode) {
        return buildOfflineAnalytics(
          ref.watch(ledgerDatabaseProvider),
          f,
        );
      }
      return ref.watch(reportsApiProvider).analytics(f);
    });

final insightsSnapshotProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      if (kNoApiMode) {
        return buildOfflineInsights();
      }
      return ref.watch(reportsApiProvider).insightsSnapshot();
    });
