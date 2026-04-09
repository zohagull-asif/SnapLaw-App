import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/supabase_service.dart';

class PrivacyVaultScreen extends StatefulWidget {
  const PrivacyVaultScreen({super.key});

  @override
  State<PrivacyVaultScreen> createState() => _PrivacyVaultScreenState();
}

class _PrivacyVaultScreenState extends State<PrivacyVaultScreen> {
  static const String _baseUrl = 'http://localhost:8000';

  List<Map<String, dynamic>> _files = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isUploading = false;

  String get _userId => SupabaseService.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFiles();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/vault/categories'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categories = ['All', ...List<String>.from(data['categories'])];
        });
      }
    } catch (e) {
      debugPrint('Failed to load categories: $e');
      setState(() {
        _categories = ['All', 'Property', 'Family', 'Criminal', 'Employment', 'Contract', 'Court Orders', 'FIR', 'General'];
      });
    }
  }

  Future<void> _loadFiles() async {
    if (_userId.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      String url = '$_baseUrl/api/vault/files/$_userId';
      if (_selectedCategory != 'All') {
        url += '?category=$_selectedCategory';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _files = List<Map<String, dynamic>>.from(data['files']);
        });
      }
    } catch (e) {
      _showError('Failed to load files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    if (file.size > 20 * 1024 * 1024) {
      _showError('File too large. Maximum size is 20MB.');
      return;
    }

    _showUploadDialog(file);
  }

  void _showUploadDialog(PlatformFile file) {
    String category = 'General';
    String description = '';
    String password = '';
    String confirmPassword = '';
    bool obscurePassword = true;
    bool obscureConfirm = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.upload_file, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Upload to Vault'),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(_getFileIcon(file.name), color: AppColors.primary, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(file.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                Text('${(file.size / 1024).toStringAsFixed(1)} KB', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: (_categories.where((c) => c != 'All').toList())
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => category = v ?? 'General'),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                      onChanged: (v) => description = v,
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Encryption Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 4) return 'Password must be at least 4 characters';
                        return null;
                      },
                      onChanged: (v) => password = v,
                    ),
                    const SizedBox(height: 12),

                    // Confirm password
                    TextFormField(
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != password) return 'Passwords do not match';
                        return null;
                      },
                      onChanged: (v) => confirmPassword = v,
                    ),
                    const SizedBox(height: 12),

                    // Warning
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Remember your password! Files cannot be recovered without it.',
                              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: _isUploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock),
              label: Text(_isUploading ? 'Encrypting...' : 'Encrypt & Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _isUploading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {});
                      setState(() => _isUploading = true);

                      try {
                        final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/vault/upload'));
                        request.fields['user_id'] = _userId;
                        request.fields['password'] = password;
                        request.fields['category'] = category;
                        request.fields['description'] = description;
                        request.files.add(http.MultipartFile.fromBytes(
                          'file',
                          file.bytes!,
                          filename: file.name,
                          contentType: MediaType.parse(_getMimeType(file.name)),
                        ));

                        final streamed = await request.send();
                        final response = await http.Response.fromStream(streamed);

                        if (response.statusCode == 200) {
                          if (mounted) Navigator.pop(ctx);
                          _showSuccess('File encrypted and uploaded successfully!');
                          _loadFiles();
                        } else {
                          final err = jsonDecode(response.body);
                          _showError(err['detail'] ?? 'Upload failed');
                        }
                      } catch (e) {
                        _showError('Upload failed: $e');
                      } finally {
                        setState(() => _isUploading = false);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    String password = '';
    bool obscure = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock_open, color: Colors.teal),
              const SizedBox(width: 8),
              const Text('Decrypt File'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(_getFileIcon(file['filename']), color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(file['filename'], style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Enter encryption password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                  ),
                  onChanged: (v) => password = v,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Decrypt & Download'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || password.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/vault/download/${file['id']}'));
      request.fields['user_id'] = _userId;
      request.fields['password'] = password;

      final streamed = await request.send();
      if (streamed.statusCode == 200) {
        final bytes = await streamed.stream.toBytes();
        _showDecryptedPreview(file['filename'], bytes, file['file_type']);
      } else {
        final response = await http.Response.fromStream(streamed);
        final err = jsonDecode(response.body);
        _showError(err['detail'] ?? 'Decryption failed. Wrong password?');
      }
    } catch (e) {
      _showError('Download failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDecryptedPreview(String filename, Uint8List bytes, String fileType) {
    // PDFs: open in new browser tab using blob URL (native browser PDF viewer)
    if (fileType == 'application/pdf') {
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        Future.delayed(const Duration(seconds: 2), () => html.Url.revokeObjectUrl(url));
        _showSuccess('PDF opened in new tab!');
      } else {
        _showPdfDialog(filename, bytes);
      }
      return;
    }

    // Images and text: show inline in dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(filename, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 500,
          child: Column(
            children: [
              // File info bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_open, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Decrypted · ${(bytes.length / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: fileType.startsWith('image/')
                      ? InteractiveViewer(
                          child: Image.memory(bytes, fit: BoxFit.contain),
                        )
                      : fileType == 'text/plain'
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  utf8.decode(bytes, allowMalformed: true),
                                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.insert_drive_file, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text('File decrypted successfully', style: TextStyle(color: Colors.grey[600])),
                                  Text('${(bytes.length / 1024).toStringAsFixed(1)} KB', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.download),
                                    label: const Text('Save File'),
                                    onPressed: () => _saveFileToDevice(filename, bytes, fileType),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (fileType.startsWith('image/') || fileType == 'text/plain')
            TextButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Save'),
              onPressed: () => _saveFileToDevice(filename, bytes, fileType),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPdfDialog(String filename, Uint8List bytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(filename, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SizedBox(
          width: 700,
          height: 600,
          child: PdfPreview(
            build: (format) async => bytes,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: filename,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _saveFileToDevice(String filename, Uint8List bytes, String fileType) {
    if (kIsWeb) {
      final blob = html.Blob([bytes], fileType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSuccess('Download started!');
    }
  }

  Future<void> _shareFile(Map<String, dynamic> file) async {
    int hours = 24;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.share, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Create Share Link'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Create a temporary share link for "${file['filename']}"'),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: hours,
                decoration: const InputDecoration(
                  labelText: 'Link expires in',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 hour')),
                  DropdownMenuItem(value: 6, child: Text('6 hours')),
                  DropdownMenuItem(value: 24, child: Text('24 hours')),
                  DropdownMenuItem(value: 72, child: Text('3 days')),
                  DropdownMenuItem(value: 168, child: Text('7 days')),
                ],
                onChanged: (v) => setDialogState(() => hours = v ?? 24),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Create Link'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/vault/share/${file['id']}'));
      request.fields['user_id'] = _userId;
      request.fields['hours'] = hours.toString();

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSuccess('Share link created! Token: ${data['share_token'].toString().substring(0, 12)}... Expires in $hours hours.');
        _loadFiles();
      } else {
        _showError('Failed to create share link');
      }
    } catch (e) {
      _showError('Failed to create share link: $e');
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete File'),
          ],
        ),
        content: Text('Are you sure you want to delete "${file['filename']}" from your vault? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/vault/delete/${file['id']}?user_id=$_userId'),
      );
      if (response.statusCode == 200) {
        _showSuccess('File deleted from vault');
        _loadFiles();
      } else {
        _showError('Failed to delete file');
      }
    } catch (e) {
      _showError('Failed to delete: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Property':
        return Colors.blue;
      case 'Family':
        return Colors.pink;
      case 'Criminal':
        return Colors.red;
      case 'Employment':
        return Colors.orange;
      case 'Contract':
        return Colors.purple;
      case 'Court Orders':
        return Colors.indigo;
      case 'FIR':
        return Colors.deepOrange;
      default:
        return Colors.teal;
    }
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Privacy Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Encrypted Document Storage',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your files are encrypted with AES-256. Only you can decrypt them.',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E3A5F),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _uploadFile,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Category filter chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedCategory = cat);
                          _loadFiles();
                        },
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF1E3A5F) : Colors.white,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // File count
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Text(
                  '${_files.length} file${_files.length == 1 ? '' : 's'} in vault',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          // File list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: _files.length,
                        itemBuilder: (context, index) => _buildFileCard(_files[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadFile,
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Upload'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No files in your vault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Upload your first encrypted document', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _uploadFile,
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file) {
    final catColor = _getCategoryColor(file['category'] ?? 'General');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // File icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getFileIcon(file['filename'] ?? ''), color: catColor, size: 24),
            ),
            const SizedBox(width: 16),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file['filename'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          file['category'] ?? 'General',
                          style: TextStyle(fontSize: 11, color: catColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.lock, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('Encrypted', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      const SizedBox(width: 8),
                      Text(_formatFileSize(file['size'] ?? 0), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      if (file['has_share_link'] == true) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.link, size: 12, color: Colors.blue[400]),
                        const SizedBox(width: 2),
                        Text('Shared', style: TextStyle(fontSize: 11, color: Colors.blue[400])),
                      ],
                    ],
                  ),
                  if (file['description'] != null && file['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      file['description'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Upload date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(file['uploaded_at'] ?? DateTime.now().toIso8601String()),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Action buttons
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onSelected: (action) {
                switch (action) {
                  case 'download':
                    _downloadFile(file);
                    break;
                  case 'share':
                    _shareFile(file);
                    break;
                  case 'delete':
                    _deleteFile(file);
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'download', child: ListTile(leading: Icon(Icons.download, color: Colors.teal), title: Text('Decrypt & Download'), dense: true)),
                const PopupMenuItem(value: 'share', child: ListTile(leading: Icon(Icons.share, color: Colors.blue), title: Text('Create Share Link'), dense: true)),
                const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete'), dense: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
