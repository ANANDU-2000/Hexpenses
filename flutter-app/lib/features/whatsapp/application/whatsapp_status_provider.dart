import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_config.dart';
import '../data/whatsapp_api.dart';

/// Optional feature: `null` when offline mode or request failed (no UI errors).
final whatsappLinkStatusProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  if (kNoApiMode) return null;
  try {
    return await ref.read(whatsappApiProvider).getStatus();
  } catch (_) {
    return null;
  }
});
