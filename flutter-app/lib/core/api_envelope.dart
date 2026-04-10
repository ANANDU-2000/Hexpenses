/// Unwraps Nest `{ success, data }` or returns the map as-is.
Map<String, dynamic>? unwrapApiMap(dynamic raw) {
  if (raw is! Map) return null;
  final m = Map<String, dynamic>.from(raw);
  if (m['success'] == true && m['data'] is Map) {
    return Map<String, dynamic>.from(m['data'] as Map);
  }
  return m;
}

/// Lists from envelope, bare list, or common keys.
List<Map<String, dynamic>> unwrapApiList(dynamic raw) {
  if (raw is List) {
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  if (raw is Map) {
    final m = Map<String, dynamic>.from(raw);
    if (m['success'] == true && m['data'] is List) {
      return (m['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final d = m['data'];
    if (d is List) {
      return d.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final ex = m['expenses'];
    if (ex is List) {
      return ex.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  }
  return [];
}
