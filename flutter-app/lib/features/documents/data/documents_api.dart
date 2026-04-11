import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_envelope.dart';
import '../../../core/providers.dart';

class DocumentsApi {
  DocumentsApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> list({
    String? q,
    String? type,
    String? tag,
    int limit = 200,
  }) async {
    final res = await _dio.get<dynamic>(
      '/documents',
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (type != null && type.isNotEmpty) 'type': type,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
        'limit': limit,
      },
    );
    final body = unwrapApiMap(res.data) ?? <String, dynamic>{};
    final raw = body['documents'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> upload({
    required String filePath,
    required String fileName,
    required String type,
    String? tagsCommaSeparated,
  }) async {
    final form = FormData.fromMap({
      'type': type,
      if (tagsCommaSeparated != null && tagsCommaSeparated.trim().isNotEmpty)
        'tags': tagsCommaSeparated.trim(),
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await _dio.post<dynamic>('/documents/upload', data: form);
    final body = unwrapApiMap(res.data) ?? <String, dynamic>{};
    final doc = body['document'];
    if (doc is Map<String, dynamic>) return doc;
    if (doc is Map) return Map<String, dynamic>.from(doc);
    throw StateError('Invalid upload response');
  }

  Future<Map<String, dynamic>> uploadBytes({
    required List<int> bytes,
    required String fileName,
    required String type,
    String? tagsCommaSeparated,
  }) async {
    final form = FormData.fromMap({
      'type': type,
      if (tagsCommaSeparated != null && tagsCommaSeparated.trim().isNotEmpty)
        'tags': tagsCommaSeparated.trim(),
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final res = await _dio.post<dynamic>('/documents/upload', data: form);
    final body = unwrapApiMap(res.data) ?? <String, dynamic>{};
    final doc = body['document'];
    if (doc is Map<String, dynamic>) return doc;
    if (doc is Map) return Map<String, dynamic>.from(doc);
    throw StateError('Invalid upload response');
  }

  Future<Map<String, dynamic>> updateTags(String id, List<String> tags) async {
    final res = await _dio.patch<dynamic>(
      '/documents/$id',
      data: {'tags': tags},
    );
    final body = unwrapApiMap(res.data) ?? <String, dynamic>{};
    final doc = body['document'];
    if (doc is Map<String, dynamic>) return doc;
    if (doc is Map) return Map<String, dynamic>.from(doc);
    throw StateError('Invalid update response');
  }

  /// Authorized file bytes (for PDF preview).
  Future<List<int>> fetchFileBytes(String documentId) async {
    final res = await _dio.get<List<int>>(
      '/documents/$documentId/file',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }
}

final documentsApiProvider = Provider<DocumentsApi>(
  (ref) => DocumentsApi(ref.watch(dioProvider)),
);
