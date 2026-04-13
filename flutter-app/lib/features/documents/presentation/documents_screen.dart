import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/app_card.dart';
import '../../../core/design_system/premium_fab.dart';
import '../../../core/dio_errors.dart';
import '../../../core/theme/money_flow_tokens.dart';
import '../../../core/widgets/ledger_async_states.dart';
import '../../../core/widgets/premium_fintech_app_bar.dart';
import '../../../core/widgets/premium_fintech_backdrop.dart';
import '../application/document_providers.dart';
import '../data/documents_api.dart';
import 'document_preview_screen.dart';

IconData _mimeIcon(String? mime, String name) {
  final m = mime?.toLowerCase() ?? '';
  final n = name.toLowerCase();
  if (m.contains('pdf') || n.endsWith('.pdf')) {
    return Icons.picture_as_pdf_rounded;
  }
  if (m.contains('image') ||
      m.contains('jpeg') ||
      m.contains('png') ||
      m.contains('gif') ||
      m.contains('webp') ||
      n.endsWith('.jpg') ||
      n.endsWith('.jpeg') ||
      n.endsWith('.png') ||
      n.endsWith('.gif') ||
      n.endsWith('.webp')) {
    return Icons.image_rounded;
  }
  if (m.contains('word') ||
      m.contains('document') ||
      m.contains('msword') ||
      n.endsWith('.doc') ||
      n.endsWith('.docx')) {
    return Icons.description_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

List<Color> _mimeIconColors(String? mime, String name) {
  final m = mime?.toLowerCase() ?? '';
  final n = name.toLowerCase();
  if (m.contains('pdf') || n.endsWith('.pdf')) {
    return [const Color(0xFFEF4444), const Color(0xFFB91C1C)];
  }
  if (m.contains('image') ||
      m.contains('jpeg') ||
      m.contains('png') ||
      n.endsWith('.jpg') ||
      n.endsWith('.png')) {
    return [const Color(0xFF8B5CF6), MfPalette.accentSoftPurple];
  }
  if (m.contains('word') || n.endsWith('.doc') || n.endsWith('.docx')) {
    return [const Color(0xFF2563EB), const Color(0xFF1D4ED8)];
  }
  return [MfPalette.accentSoftPurple, const Color(0xFF6366F1)];
}

String _typeDisplayLabel(String type) {
  switch (type.toLowerCase()) {
    case 'bill':
      return 'Bill';
    case 'insurance':
      return 'Insurance';
    default:
      if (type.isEmpty) return 'Document';
      return type[0].toUpperCase() + type.substring(1);
  }
}

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
      final q = ref.read(documentsQueryProvider).q;
      if (q.isNotEmpty) _searchCtrl.text = q;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

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
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Upload document',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Category'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: type,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'bill', child: Text('Bill')),
                          DropdownMenuItem(
                            value: 'insurance',
                            child: Text('Insurance'),
                          ),
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
                      final r = await FilePicker.platform.pickFiles(
                        withData: kIsWeb,
                      );
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
                              } else if (!kIsWeb &&
                                  f.path != null &&
                                  f.path!.isNotEmpty) {
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
                                  const SnackBar(
                                    content: Text('Upload complete'),
                                  ),
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
    final tags =
        (row['tags'] as List<dynamic>?)?.map((e) => '$e').toList() ??
        <String>[];
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Tags updated')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
    ctrl.dispose();
  }

  void _applySearch() {
    ref.read(documentsQueryProvider.notifier).setQ(_searchCtrl.text.trim());
    ref.invalidate(documentsListProvider);
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
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: PremiumFintechAppBar.bar(
        context: context,
        title: 'Documents',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: MoneyFlowPremiumExtendedFab(
        heroTag: 'documents_upload_fab',
        tooltip: 'Upload document',
        onPressed: _openUploadSheet,
        icon: Icons.upload_file_rounded,
        label: 'Upload',
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PremiumFintechBackdrop(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 8, MfSpace.xxl, MfSpace.sm),
                child: _GlassSearchBarWrapper(
                  controller: _searchCtrl,
                  onClear: () {
                    _searchCtrl.clear();
                    ref.read(documentsQueryProvider.notifier).setQ('');
                    ref.invalidate(documentsListProvider);
                  },
                  onSearch: _applySearch,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 0, MfSpace.xxl, MfSpace.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DocFilterChip(
                        label: 'All',
                        selected: query.type == null,
                        onSelected: (_) {
                          ref.read(documentsQueryProvider.notifier).setType(null);
                          ref.invalidate(documentsListProvider);
                        },
                      ),
                      const SizedBox(width: MfSpace.sm),
                      _DocFilterChip(
                        label: 'Bills',
                        selected: query.type == 'bill',
                        onSelected: (_) {
                          ref.read(documentsQueryProvider.notifier).setType('bill');
                          ref.invalidate(documentsListProvider);
                        },
                      ),
                      const SizedBox(width: MfSpace.sm),
                      _DocFilterChip(
                        label: 'Insurance',
                        selected: query.type == 'insurance',
                        onSelected: (_) {
                          ref
                              .read(documentsQueryProvider.notifier)
                              .setType('insurance');
                          ref.invalidate(documentsListProvider);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(MfSpace.xxl, 0, MfSpace.xxl, MfSpace.md),
                child: _GlassTagField(
                  controller: _tagCtrl,
                  hasTag: query.tag != null && query.tag!.isNotEmpty,
                  onClear: () {
                    _tagCtrl.clear();
                    ref.read(documentsQueryProvider.notifier).setTag(null);
                    ref.invalidate(documentsListProvider);
                  },
                  onSubmit: (v) {
                    ref.read(documentsQueryProvider.notifier).setTag(v.trim());
                    ref.invalidate(documentsListProvider);
                  },
                ),
              ),
              Expanded(
                child: asyncDocs.when(
                  data: (rows) {
                    if (rows.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          MfSpace.xxl,
                          8,
                          MfSpace.xxl,
                          120,
                        ),
                        children: [
                          _DocumentsEmptyState(onUpload: _openUploadSheet),
                        ],
                      );
                    }
                    return RefreshIndicator(
                      color: MfPalette.neonGreen,
                      backgroundColor: cs.surfaceContainerLow,
                      onRefresh: () async {
                        ref.invalidate(documentsListProvider);
                        await ref.read(documentsListProvider.future);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          MfSpace.xxl,
                          0,
                          MfSpace.xxl,
                          120,
                        ),
                        itemCount: rows.length,
                        itemBuilder: (context, i) {
                          final row = rows[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: MfSpace.md),
                            child: _DocumentFileCard(
                              row: row,
                              onEditTags: () => _editTags(row),
                              onOpen: () {
                                final id = row['id'] as String? ?? '';
                                if (id.isEmpty) return;
                                final name =
                                    row['originalName'] as String? ??
                                    row['fileUrl'] as String? ??
                                    'Document';
                                final mime = row['mimeType'] as String?;
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
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(MfSpace.xxl),
                    child: LedgerErrorState(
                      title: 'Could not load documents',
                      message: e is DioException ? dioErrorMessage(e) : e.toString(),
                      onRetry: () => ref.invalidate(documentsListProvider),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassSearchBarWrapper extends StatefulWidget {
  const _GlassSearchBarWrapper({
    required this.controller,
    required this.onClear,
    required this.onSearch,
  });

  final TextEditingController controller;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  @override
  State<_GlassSearchBarWrapper> createState() => _GlassSearchBarWrapperState();
}

class _GlassSearchBarWrapperState extends State<_GlassSearchBarWrapper> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MfRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(MfRadius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: MfPalette.accentSoftPurple.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: widget.controller,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Search files, tags…',
              hintStyle: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.45),
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: MfPalette.accentSoftPurple.withValues(alpha: 0.9),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                      onPressed: widget.onClear,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      color: MfPalette.neonGreen,
                    ),
                    onPressed: widget.onSearch,
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: MfSpace.sm,
                vertical: MfSpace.md,
              ),
              isDense: true,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => widget.onSearch(),
          ),
        ),
      ),
    );
  }
}

class _DocFilterChip extends StatelessWidget {
  const _DocFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      selected: selected,
      showCheckmark: false,
      selectedColor: MfPalette.accentSoftPurple.withValues(alpha: 0.28),
      backgroundColor: cs.surfaceContainerHigh.withValues(alpha: 0.55),
      side: BorderSide(
        color: selected
            ? MfPalette.neonGreen.withValues(alpha: 0.55)
            : cs.outlineVariant.withValues(alpha: 0.35),
        width: selected ? 1.5 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MfRadius.lg)),
      onSelected: onSelected,
    );
  }
}

class _GlassTagField extends StatelessWidget {
  const _GlassTagField({
    required this.controller,
    required this.hasTag,
    required this.onClear,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool hasTag;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(MfRadius.md),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(MfRadius.md),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Filter by tag',
              hintText: 'e.g. medical',
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: MfSpace.lg,
                vertical: MfSpace.sm,
              ),
              isDense: true,
              suffixIcon: hasTag
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: onClear,
                    )
                  : null,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmit,
          ),
        ),
      ),
    );
  }
}

class _DocumentFileCard extends StatelessWidget {
  const _DocumentFileCard({
    required this.row,
    required this.onEditTags,
    required this.onOpen,
  });

  final Map<String, dynamic> row;
  final VoidCallback onEditTags;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = row['id'] as String? ?? '';
    final name =
        row['originalName'] as String? ??
        row['fileUrl'] as String? ??
        'Document';
    final type = row['type'] as String? ?? '';
    final mime = row['mimeType'] as String?;
    final uploaded = row['uploadedAt'] as String?;
    DateTime? dt;
    if (uploaded != null) dt = DateTime.tryParse(uploaded);
    final dateStr = dt != null
        ? DateFormat.yMMMd().add_jm().format(dt.toLocal())
        : '';
    final icon = _mimeIcon(mime, name);
    final grads = _mimeIconColors(mime, name);
    final typeLabel = _typeDisplayLabel(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: id.isEmpty ? null : onOpen,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        splashColor: MfPalette.accentSoftPurple.withValues(alpha: 0.08),
        child: AppCard(
          glass: true,
          padding: const EdgeInsets.all(MfSpace.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MfRadius.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: grads,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: grads.last.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: MfSpace.sm),
                    Wrap(
                      spacing: MfSpace.sm,
                      runSpacing: MfSpace.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: MfSpace.md,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: type.toLowerCase() == 'insurance'
                                ? MfPalette.accentSoftPurple.withValues(alpha: 0.18)
                                : MfPalette.neonGreen.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type.toLowerCase() == 'insurance'
                                    ? Icons.shield_rounded
                                    : Icons.receipt_long_rounded,
                                size: 14,
                                color: type.toLowerCase() == 'insurance'
                                    ? MfPalette.accentSoftPurple
                                    : MfPalette.incomeGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                typeLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (dateStr.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.upload_rounded,
                                size: 14,
                                color: cs.onSurface.withValues(alpha: 0.45),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dateStr,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.label_outline_rounded,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
                tooltip: 'Edit tags',
                onPressed: onEditTags,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentsEmptyState extends StatelessWidget {
  const _DocumentsEmptyState({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(MfSpace.xxl),
      child: Column(
        children: [
          const _DocumentsEmptyIllustration(width: 200),
          const SizedBox(height: MfSpace.xl),
          Icon(
            Icons.folder_open_rounded,
            size: 32,
            color: MfPalette.accentSoftPurple,
          ),
          const SizedBox(height: MfSpace.md),
          Text(
            'No documents found',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Text(
            'Upload bills and insurance PDFs to keep them organised and searchable.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: MfSpace.xl),
          FilledButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload'),
          ),
        ],
      ),
    );
  }
}

class _DocumentsEmptyIllustration extends StatelessWidget {
  const _DocumentsEmptyIllustration({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 0.5;
    return SizedBox(
      width: width,
      height: h,
      child: CustomPaint(painter: _DocumentsEmptyPainter()),
    );
  }
}

class _DocumentsEmptyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final doc = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.56, h * 0.72),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      doc,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MfPalette.accentSoftPurple.withValues(alpha: 0.45),
            MfPalette.neonGreen.withValues(alpha: 0.15),
          ],
        ).createShader(doc.outerRect),
    );
    canvas.drawRRect(
      doc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    final fold = Path()
      ..moveTo(w * 0.62, h * 0.12)
      ..lineTo(w * 0.78, h * 0.28)
      ..lineTo(w * 0.62, h * 0.28)
      ..close();
    canvas.drawPath(
      fold,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawLine(
      Offset(w * 0.32, h * 0.42),
      Offset(w * 0.68, h * 0.42),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(w * 0.32, h * 0.52),
      Offset(w * 0.58, h * 0.52),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
