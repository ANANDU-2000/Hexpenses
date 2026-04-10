import 'dart:js_interop';

import 'api_config.dart';

@JS('MONEYFLOW_API_BASE')
external JSString? get _moneyflowApiBase;

String resolveApiBase() {
  try {
    final v = _moneyflowApiBase;
    if (v != null) {
      final s = v.toDart.trim();
      if (s.isNotEmpty) return s;
    }
  } catch (_) {}
  return kApiBase;
}
