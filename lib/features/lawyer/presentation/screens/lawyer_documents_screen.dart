import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/snaplaw_widgets.dart';
import '../../../../theme/snaplaw_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/lawyer_document_model.dart';

// ─── Provider ───────────────────────────────────────────────────────────────

final lawyerDocumentsProvider =
    StateNotifierProvider<LawyerDocumentsNotifier, AsyncValue<List<LawyerDocumentModel>>>(
  (ref) => LawyerDocumentsNotifier(ref),
);

class LawyerDocumentsNotifier
    extends StateNotifier<AsyncValue<List<LawyerDocumentModel>>> {
  final Ref _ref;
  LawyerDocumentsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      state = const AsyncValue.loading();
      final user = _ref.read(authProvider).user;
      if (user == null) { state = const AsyncValue.data([]); return; }
      final db = Supabase.instance.client;
      final rows = await db
          .from('lawyer_documents')
          .select()
          .eq('lawyer_id', user.id)
          .order('created_at', ascending: false);
      state = AsyncValue.data(
          (rows as List).map((r) => LawyerDocumentModel.fromJson(r as Map<String, dynamic>)).toList());
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<String?> upload({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? description,
    String? caseTitle,
  }) async {
    try {
      final user = _ref.read(authProvider).user;
      if (user == null) return 'Not authenticated';
      final db = Supabase.instance.client;
      final storage = db.storage;

      // Upload to Supabase Storage bucket "documents"
      final storagePath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$filename';
      await storage.from('documents').uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: false),
      );
      final fileUrl = storage.from('documents').getPublicUrl(storagePath);

      // Insert metadata row
      final row = {
        'lawyer_id': user.id,
        'filename': filename,
        'file_url': fileUrl,
        'file_size': bytes.length,
        'file_type': mimeType,
        'description': description,
        'case_title': caseTitle,
      };
      await db.from('lawyer_documents').insert(row);
      await load();
      return null; // success
    } catch (e) {
      final msg = e.toString();
      if (msg.toLowerCase().contains('bucket') || msg.toLowerCase().contains('not found')) {
        return 'Storage bucket not set up. Please run the Supabase SQL setup (complete_supabase_setup.sql) in your Supabase dashboard.';
      }
      if (msg.toLowerCase().contains('row-level security') || msg.toLowerCase().contains('rls') || msg.toLowerCase().contains('policy')) {
        return 'Permission denied. Make sure you are logged in and the storage policies are configured.';
      }
      return msg;
    }
  }

  Future<String?> delete(LawyerDocumentModel doc) async {
    try {
      final db = Supabase.instance.client;
      await db.from('lawyer_documents').delete().eq('id', doc.id);
      // Try to remove from storage (best effort)
      try {
        final uri = Uri.parse(doc.fileUrl);
        final segments = uri.pathSegments;
        // path after "documents/"
        final idx = segments.indexOf('documents');
        if (idx != -1 && idx + 1 < segments.length) {
          final storagePath = segments.sublist(idx + 1).join('/');
          await db.storage.from('documents').remove([storagePath]);
        }
      } catch (_) {}
      await load();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class LawyerDocumentsScreen extends ConsumerStatefulWidget {
  const LawyerDocumentsScreen({super.key});

  @override
  ConsumerState<LawyerDocumentsScreen> createState() => _LawyerDocumentsScreenState();
}

class _LawyerDocumentsScreenState extends ConsumerState<LawyerDocumentsScreen> {
  String _filter = 'All'; // All | PDF | Image | Other
  bool _uploading = false;

  static const _accent = SnapLawColors.lawyerPurple;

  List<LawyerDocumentModel> _applyFilter(List<LawyerDocumentModel> docs) {
    if (_filter == 'All') return docs;
    return docs.where((d) {
      final t = (d.fileType ?? '').toLowerCase();
      if (_filter == 'PDF') return t.contains('pdf');
      if (_filter == 'Image') return t.startsWith('image');
      return !t.contains('pdf') && !t.startsWith('image');
    }).toList();
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not read file. Please try selecting it again.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Ask for optional metadata
    String? description;
    String? caseTitle;
    final confirmed = await _showUploadDialog(file.name, (d, c) {
      description = d;
      caseTitle = c;
    });
    if (!confirmed) return;

    setState(() => _uploading = true);
    final mime = _mimeFromName(file.name);
    final error = await ref.read(lawyerDocumentsProvider.notifier).upload(
      bytes: file.bytes!,
      filename: file.name,
      mimeType: mime,
      description: description,
      caseTitle: caseTitle,
    );
    setState(() => _uploading = false);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $error'), backgroundColor: Colors.red.shade700));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded successfully'),
            backgroundColor: Color(0xFF00C896)));
    }
  }

  String _mimeFromName(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default: return 'text/plain';
    }
  }

  Future<bool> _showUploadDialog(String filename, Function(String?, String?) onSave) async {
    final descCtrl = TextEditingController();
    final caseCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.upload_file, color: _accent, size: 22),
          const SizedBox(width: 10),
          const Expanded(child: Text('Upload Document', style: TextStyle(color: Colors.white, fontSize: 16))),
        ]),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _accent.withOpacity(0.30)),
              ),
              child: Row(children: [
                Icon(_fileIcon(filename), color: _accent, size: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(filename,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis)),
              ]),
            ),
            const SizedBox(height: 16),
            _DialogField(controller: caseCtrl, label: 'Case Title (optional)', icon: Icons.folder_outlined),
            const SizedBox(height: 12),
            _DialogField(controller: descCtrl, label: 'Description (optional)', icon: Icons.notes, maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.55)))),
          ElevatedButton.icon(
            onPressed: () {
              onSave(
                descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                caseCtrl.text.trim().isEmpty ? null : caseCtrl.text.trim(),
              );
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.upload, size: 16),
            label: const Text('Upload'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmDelete(LawyerDocumentModel doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete Document', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${doc.filename}"? This cannot be undone.',
            style: TextStyle(color: Colors.white.withOpacity(0.75))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.55)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await ref.read(lawyerDocumentsProvider.notifier).delete(doc);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $error'), backgroundColor: Colors.red.shade700));
    }
  }

  IconData _fileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['png', 'jpg', 'jpeg'].contains(ext)) return Icons.image_outlined;
    if (['doc', 'docx'].contains(ext)) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _fileColor(String? mimeType) {
    final t = (mimeType ?? '').toLowerCase();
    if (t.contains('pdf')) return const Color(0xFFFF4757);
    if (t.startsWith('image')) return const Color(0xFF3B82F6);
    if (t.contains('word')) return const Color(0xFF3B82F6);
    return const Color(0xFF7B61FF);
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(lawyerDocumentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020818),
      body: AppBackground(
        overlayOpacity: 0.55,
        child: Column(
          children: [
            GlassTopBar(
              title: 'My Documents',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (_uploading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ElevatedButton.icon(
                      onPressed: _pickAndUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Upload', style: TextStyle(fontSize: 13)),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: docsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: SnapLawColors.lawyerPurple)),
                error: (e, _) => _buildError(e.toString()),
                data: (docs) => _buildBody(docs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<LawyerDocumentModel> allDocs) {
    final docs = _applyFilter(allDocs);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Document Library',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${allDocs.length} document${allDocs.length != 1 ? 's' : ''} stored',
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
              ])),
              // Summary chips
              _SummaryChip(label: 'Total', value: '${allDocs.length}', color: _accent),
              const SizedBox(width: 8),
              _SummaryChip(label: 'PDFs',
                  value: '${allDocs.where((d) => (d.fileType ?? '').contains('pdf')).length}',
                  color: const Color(0xFFFF4757)),
              const SizedBox(width: 8),
              _SummaryChip(label: 'Images',
                  value: '${allDocs.where((d) => (d.fileType ?? '').startsWith('image')).length}',
                  color: const Color(0xFF3B82F6)),
            ]),
          ),
          const SizedBox(height: 20),

          // Filter chips
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: ['All', 'PDF', 'Image', 'Other'].map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: _accent.withOpacity(0.25),
                  checkmarkColor: _accent,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  labelStyle: TextStyle(
                    color: _filter == f ? Colors.white : Colors.white.withOpacity(0.65),
                    fontSize: 12, fontWeight: _filter == f ? FontWeight.w600 : FontWeight.normal),
                  side: BorderSide(
                    color: _filter == f ? _accent.withOpacity(0.55) : Colors.transparent),
                ),
              )).toList()),
            ),
          ),
          const SizedBox(height: 20),

          if (docs.isEmpty)
            _buildEmptyState()
          else
            ...docs.asMap().entries.map((e) => FadeSlideIn(
              delay: Duration(milliseconds: 200 + e.key * 60),
              child: _DocumentCard(
                doc: e.value,
                fileIcon: _fileIcon(e.value.filename),
                fileColor: _fileColor(e.value.fileType),
                onDelete: () => _confirmDelete(e.value),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.folder_open_outlined, size: 64, color: Colors.white.withOpacity(0.20)),
          const SizedBox(height: 16),
          Text('No Documents Yet',
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Upload PDFs, images, and legal files to your library.',
              style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickAndUpload,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload Document'),
          ),
        ]),
      ),
    );
  }

  Widget _buildError(String error) {
    final isMissing = error.toLowerCase().contains('relation') ||
        error.toLowerCase().contains('does not exist') ||
        error.toLowerCase().contains('42p01');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        borderColor: Colors.red.withOpacity(0.35),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.error_outline, color: Colors.red.shade400),
            const SizedBox(width: 10),
            const Text('Setup Required', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          if (isMissing) ...[
            Text('The lawyer_documents table is missing.\nRun this SQL in your Supabase dashboard:',
                style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.40),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: SelectableText(
                _kSql,
                style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ] else
            Text(error, style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(lawyerDocumentsProvider.notifier).load(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }

  static const _kSql = '''
CREATE TABLE lawyer_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lawyer_id UUID NOT NULL,
  filename TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size INTEGER,
  file_type TEXT,
  description TEXT,
  case_title TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Supabase Storage bucket (run once):
-- Create bucket named "documents" with public access.
''';
}

// ─── Document Card ────────────────────────────────────────────────────────────

class _DocumentCard extends StatefulWidget {
  final LawyerDocumentModel doc;
  final IconData fileIcon;
  final Color fileColor;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.doc,
    required this.fileIcon,
    required this.fileColor,
    required this.onDelete,
  });

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final dateStr = '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          borderColor: _hovered ? widget.fileColor.withOpacity(0.35) : Colors.transparent,
          child: Row(children: [
            // File icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: widget.fileColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.fileColor.withOpacity(0.30)),
              ),
              child: Icon(widget.fileIcon, color: widget.fileColor, size: 26),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(doc.filename,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (doc.caseTitle != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: SnapLawColors.lawyerPurple.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: SnapLawColors.lawyerPurple.withOpacity(0.35)),
                    ),
                    child: Text(doc.caseTitle!,
                        style: const TextStyle(color: SnapLawColors.lawyerPurple, fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                ],
                if (doc.formattedSize.isNotEmpty)
                  Text(doc.formattedSize,
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11)),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined, size: 10, color: Colors.white.withOpacity(0.40)),
                const SizedBox(width: 3),
                Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 11)),
              ]),
              if (doc.description != null && doc.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(doc.description!,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ])),

            // Actions
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: Icon(Icons.open_in_new, size: 18, color: Colors.white.withOpacity(0.55)),
                tooltip: 'Open',
                onPressed: () async {
                  final uri = Uri.parse(doc.fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open document'),
                          duration: Duration(seconds: 2)));
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                tooltip: 'Delete',
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 11)),
      ]),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.45), size: 18),
        filled: true,
        fillColor: const Color(0xFF0F1535).withOpacity(0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.15))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: SnapLawColors.lawyerPurple)),
      ),
    );
  }
}
