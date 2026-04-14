import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class AiInsightsPayload {
  const AiInsightsPayload({
    required this.source,
    required this.monthlyFinancialSummary,
    required this.spendingWarnings,
    required this.savingSuggestions,
    required this.budgetRecommendations,
    required this.insights,
  });

  final String? source;
  final String monthlyFinancialSummary;
  final List<String> spendingWarnings;
  final List<String> savingSuggestions;
  final List<String> budgetRecommendations;
  final List<String> insights;
}

class InsightsApi {
  InsightsApi(this._dio);

  final Dio _dio;

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<AiInsightsPayload> fetch() async {
    final res = await _dio.get<dynamic>('/ai/insights');
    final data = unwrapApiMap(res.data) ?? <String, dynamic>{};
    return AiInsightsPayload(
      source: data['source'] as String?,
      monthlyFinancialSummary:
          data['monthlyFinancialSummary']?.toString() ?? '',
      spendingWarnings: _stringList(data['spendingWarnings']),
      savingSuggestions: _stringList(data['savingSuggestions']),
      budgetRecommendations: _stringList(data['budgetRecommendations']),
      insights: _stringList(data['insights']),
    );
  }

  Future<
      ({
        String reply,
        String? source,
        Map<String, dynamic>? actionProposal,
        bool requiresConfirmation,
      })> chat(
    String message, {
    List<Map<String, String>>? history,
    String lang = 'auto',
    Map<String, dynamic>? actionConfirmation,
  }) async {
    final res = await _dio.post<dynamic>(
      '/ai/chat',
      data: {
        'message': message,
        'lang': lang,
        if (history != null && history.isNotEmpty) 'history': history,
        if (actionConfirmation != null) 'actionConfirmation': actionConfirmation,
      },
    );
    final data = unwrapApiMap(res.data) ?? <String, dynamic>{};
    return (
      reply: data['reply']?.toString() ?? '',
      source: data['source'] as String?,
      actionProposal: (data['actionProposal'] as Map?)?.cast<String, dynamic>(),
      requiresConfirmation: data['requiresConfirmation'] == true,
    );
  }
}

final insightsApiProvider = Provider<InsightsApi>(
  (ref) => InsightsApi(ref.watch(dioProvider)),
);
