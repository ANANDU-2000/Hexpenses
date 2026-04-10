import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/ledger_ui.dart';
import '../application/document_providers.dart';
import '../data/documents_api.dart';
import 'document_preview_screen.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  final _searchCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final t = ref.read(documentsQueryProvider).tag;
      if (t != null) _tagCtrl.text = t;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  /// Web must not read [PlatformFile.path] (throws); prefer bytes from [pickFiles].
  bool _pickedFileReady(PlatformFile f) {
    if (f.bytes != null && f.bytes!.isNotEmpty) return true;
    if (kIsWeb) return false;
    return f.path != null && f.path!.isNotEmpty;
  }

  Future<void> _openUploadSheet() async {
    final rootContext = context;
    String type = 'bill';
    final tagsCtrl = TextEditingController();
    PlatformFile? picked;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Upload document', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Category'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: type,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'bill', child: Text('Bill')),
                          DropdownMenuItem(value: 'insurance', child: Text('Insurance')),
                        ],
                        onChanged: (v) => setModal(() => type = v ?? 'bill'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tags',
                      hintText: 'comma-separated, e.g. home, 2025',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final r = await FilePicker.platform.pickFiles(withData: kIsWeb);
                      if (r != null && r.files.isNotEmpty) {
                        setModal(() => picked = r.files.single);
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(picked?.name ?? 'Choose file'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: picked == null || !_pickedFileReady(picked!)
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            try {
                              final api = ref.read(documentsApiProvider);
                              final f = picked!;
                              if (f.bytes != null && f.bytes!.isNotEmpty) {
                                await api.uploadBytes(
                                  bytes: f.bytes!,
                                  fileName: f.name,
                                  type: type,
                                  tagsCommaSeparated: tagsCtrl.text,
                                );
                              } else if (!kIsWeb && f.path != null && f.path!.isNotEmpty) {
                                await api.upload(
                                  filePath: f.path!,
                                  fileName: f.name,
                                  type: type,
                                  tagsCommaSeparated: tagsCtrl.text,
                                );
                              } else {
                                throw StateError('No file data');
                              }
                              ref.invalidate(documentsListProvider);
                              if (rootContext.mounted) {
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  const SnackBar(content: Text('Upload complete')),
                                );
                              }
                            } catch (e) {
                              if (rootContext.mounted) {
                                ScaffoldMessenger.of(rootContext).showSnackBar(
                                  SnackBar(content: Text('Upload failed: $e')),
                                );
                              }
                            }
                          },
                    child: const Text('Upload'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    tagsCtrl.dispose();
  }

  Future<void> _editTags(Map<String, dynamic> row) async {
    final id = row['id'] as String? ?? '';
    if (id.isEmpty) return;
    final tags = (row['tags'] as List<dynamic>?)?.map((e) => '$e').toList() ?? <String>[];
    final ctrl = TextEditingController(text: tags.join(', '));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit tags'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'comma-separated'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && mounted) {
      final next = ctrl.text
          .split(RegExp(r'[,;]+'))
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();
      try {
        await ref.read(documentsApiProvider).updateTags(id, next);
        ref.invalidate(documentsListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tags updated')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final asyncDocs = ref.watch(documentsListProvider);
    final query = ref.watch(documentsQueryProvider);

    ref.listen<DocumentsQuery>(documentsQueryProvider, (_, next) {
      final t = next.tag ?? '';
      if (_tagCtrl.text != t) {
        _tagCtrl.value = TextEditingValue(
          text: t,
          selection: TextSelection.collapsed(offset: t.length),
        );
      }
    });

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUploadSheet,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: LedgerSectionLayer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search name, type, tags…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(documentsQueryProvider.notifier).setQ('');
                            ref.invalidate(documentsListProvider);
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) {
                        ref.read(documentsQueryProvider.notifier).setQ(v);
                        ref.invalidate(documentsListProvider);
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All types'),
                          selected: query.type == null,
                          onSelected: (_) {
                            ref.read(documentsQueryProvider.notifier).setType(null);
                            ref.invalidate(documentsListProvider);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Bills'),
                          selected: query.type == 'bill',
                          onSelected: (_) {
                            ref.read(documentsQueryProvider.notifier).setType('bill');
                            ref.invalidate(documentsListProvider);
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Insurance'),
                          selected: query.type == 'insurance',
                          onSelected: (_) {
                            ref.read(documentsQueryProvider.notifier).setType('insurance');
                            ref.invalidate(documentsListProvider);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tagCtrl,
                      decoration: InputDecoration(
                        labelText: 'Filter by tag',
                        hintText: 'exact tag, e.g. medical',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        suffixIcon: query.tag != null && query.tag!.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _tagCtrl.clear();
                                  ref.read(documentsQueryProvider.notifier).setTag(null);
                                  ref.invalidate(documentsListProvider);
                                },
                              )
                            : null,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) {
                        ref.read(documentsQueryProvider.notifier).setTag(v.trim());
                        ref.invalidate(documentsListProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: asyncDocs.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return Center(
                    child: Text(
                      'No documents match your filters.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(documentsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final row = rows[i];
                      final id = row['id'] as String? ?? '';
                      final name = row['originalName'] as String? ?? row['fileUrl'] as String? ?? 'Document';
                      final type = row['type'] as String? ?? '';
                      final tags = (row['tags'] as List<dynamic>?)?.map((e) => '$e').toList() ?? [];
                      final uploaded = row['uploadedAt'] as String?;
                      DateTime? dt;
                      if (uploaded != null) dt = DateTime.tryParse(uploaded);
                      final subtitle = dt != null ? DateFormat.yMMMd().add_jm().format(dt.toLocal()) : '';
                      final mime = row['mimeType'] as String?;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LedgerStaggerItem(
                          marginBottom: 0,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subtitle.isNotEmpty)
                                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Chip(
                                      label: Text(type, style: const TextStyle(fontSize: 12)),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                    ...tags.map(
                                      (t) => Chip(
                                        label: Text(t, style: const TextStyle(fontSize: 12)),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.label_outline),
                              onPressed: () => _editTags(row),
                              tooltip: 'Edit tags',
                            ),
                            onTap: id.isEmpty
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => DocumentPreviewScreen(
                                          documentId: id,
                                          title: name,
                                          mimeType: mime,
                                        ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
            ),
          ),
        ],
      ),
    );
  }
}
