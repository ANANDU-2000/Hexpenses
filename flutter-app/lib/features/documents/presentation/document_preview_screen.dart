import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../data/documents_api.dart';

class DocumentPreviewScreen extends ConsumerStatefulWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.documentId,
    required this.title,
    this.mimeType,
  });

  final String documentId;
  final String title;
  final String? mimeType;

  @override
  ConsumerState<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends ConsumerState<DocumentPreviewScreen> {
  bool _loading = true;
  String? _error;
  Uint8List? _bytes;
  PdfControllerPinch? _pdf;

  bool get _isImage {
    final m = widget.mimeType?.toLowerCase() ?? '';
    return m.startsWith('image/');
  }

  bool get _isPdf {
    final m = widget.mimeType?.toLowerCase() ?? '';
    return m == 'application/pdf' || m.endsWith('/pdf');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await ref.read(documentsApiProvider).fetchFileBytes(widget.documentId);
      if (!mounted) return;
      final u8 = Uint8List.fromList(bytes);
      _pdf?.dispose();
      _pdf = null;
      if (_isPdf) {
        _pdf = PdfControllerPinch(document: PdfDocument.openData(u8));
      }
      setState(() {
        _bytes = u8;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pdf?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : _bytes == null
                  ? const SizedBox.shrink()
                  : _isImage
                      ? InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4,
                          child: Center(child: Image.memory(_bytes!, fit: BoxFit.contain)),
                        )
                      : _isPdf && _pdf != null
                          ? PdfViewPinch(controller: _pdf!)
                          : _fallback(cs),
    );
  }

  Widget _fallback(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, size: 56, color: cs.onSurface.withValues(alpha: 0.45)),
            const SizedBox(height: 16),
            Text(
              'Preview is only available for images and PDFs.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
