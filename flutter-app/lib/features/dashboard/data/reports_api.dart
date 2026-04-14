import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';
import '../../analytics/domain/analytics_filter.dart';

class ReportsApi {
  ReportsApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> monthlySummary() async {
    final res = await _dio.get<dynamic>('/reports/monthly-summary');
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> categoryBreakdown() async {
    final res = await _dio.get<dynamic>('/reports/category-breakdown');
    return unwrapApiList(res.data);
  }

  Future<Map<String, dynamic>> monthlyIncome({int? year, int? month}) async {
    final res = await _dio.get<dynamic>(
      '/reports/monthly-income',
      queryParameters: {
        if (year != null) 'year': year.toString(),
        if (month != null) 'month': month.toString(),
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> dashboard({int trendMonths = 6}) async {
    final res = await _dio.get<dynamic>(
      '/reports/dashboard',
      queryParameters: {'trendMonths': trendMonths},
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  /// MVP: chart-ready category breakdown + monthly expense trend + vehicle placeholder.
  /// Optional [fromYmd]/[toYmd] (`YYYY-MM-DD`, inclusive) override calendar month.
  Future<Map<String, dynamic>> expenseMvp({
    int? year,
    int? month,
    int trendMonths = 12,
    String? fromYmd,
    String? toYmd,
  }) async {
    final res = await _dio.get<dynamic>(
      '/reports/expense-mvp',
      queryParameters: {
        if (year != null) 'year': year.toString(),
        if (month != null) 'month': month.toString(),
        'trendMonths': trendMonths.toString(),
        if (fromYmd != null && fromYmd.isNotEmpty) 'from': fromYmd,
        if (toYmd != null && toYmd.isNotEmpty) 'to': toYmd,
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  /// Drill-down analytics: pie + monthly + stacked + line trend.
  Future<Map<String, dynamic>> analytics(AnalyticsFilter filter) async {
    final res = await _dio.get<dynamic>(
      '/reports/analytics',
      queryParameters: filter.toQuery(),
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  /// Rule-based MoM / alerts for dashboard cards.
  Future<Map<String, dynamic>> insightsSnapshot() async {
    final res = await _dio.get<dynamic>('/reports/insights');
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> taxSummary({
    int? year,
    int? month,
    bool details = false,
  }) async {
    final res = await _dio.get<dynamic>(
      '/reports/tax-summary',
      queryParameters: {
        if (year != null) 'year': year.toString(),
        if (month != null) 'month': month.toString(),
        if (details) 'details': '1',
      },
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }
}

final reportsApiProvider = Provider<ReportsApi>(
  (ref) => ReportsApi(ref.watch(dioProvider)),
);
