import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/documents_api.dart';

class DocumentsQuery {
  const DocumentsQuery({this.q = '', this.type, this.tag});

  final String q;
  final String? type;
  final String? tag;
}

class DocumentsQueryNotifier extends Notifier<DocumentsQuery> {
  @override
  DocumentsQuery build() => const DocumentsQuery();

  void setQ(String v) =>
      state = DocumentsQuery(q: v, type: state.type, tag: state.tag);

  void setType(String? v) => state = DocumentsQuery(
    q: state.q,
    type: (v == null || v.isEmpty) ? null : v,
    tag: state.tag,
  );

  void setTag(String? v) => state = DocumentsQuery(
    q: state.q,
    type: state.type,
    tag: (v == null || v.isEmpty) ? null : v,
  );
}

final documentsQueryProvider =
    NotifierProvider<DocumentsQueryNotifier, DocumentsQuery>(
      DocumentsQueryNotifier.new,
    );

final documentsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final api = ref.watch(documentsApiProvider);
      final query = ref.watch(documentsQueryProvider);
      return api.list(
        q: query.q.trim().isEmpty ? null : query.q.trim(),
        type: query.type,
        tag: query.tag,
      );
    });
