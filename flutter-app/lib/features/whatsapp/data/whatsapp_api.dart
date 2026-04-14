import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class WhatsappApi {
  WhatsappApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getStatus() async {
    final res = await _dio.get<dynamic>('/whatsapp/status');
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> requestLink(String phoneE164) async {
    final res = await _dio.post<dynamic>(
      '/whatsapp/link',
      data: {'phoneE164': phoneE164},
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> verify(String phoneE164, String code) async {
    final res = await _dio.post<dynamic>(
      '/whatsapp/verify',
      data: {'phoneE164': phoneE164, 'code': code.trim()},
    );
    return unwrapApiMap(res.data) ?? <String, dynamic>{};
  }

  Future<void> updatePreferences({
    bool? dailySummary,
    bool? monthlyReport,
    bool? alerts,
    String? phoneE164,
  }) async {
    final data = <String, dynamic>{
      if (dailySummary != null) 'dailySummary': dailySummary,
      if (monthlyReport != null) 'monthlyReport': monthlyReport,
      if (alerts != null) 'alerts': alerts,
      if (phoneE164 != null && phoneE164.isNotEmpty) 'phoneE164': phoneE164,
    };
    await _dio.patch<dynamic>('/whatsapp/preferences', data: data);
  }
}

final whatsappApiProvider = Provider<WhatsappApi>(
  (ref) => WhatsappApi(ref.watch(dioProvider)),
);
