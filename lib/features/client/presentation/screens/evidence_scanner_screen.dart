import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/app_colors.dart';

class EvidenceScannerScreen extends ConsumerStatefulWidget {
  const EvidenceScannerScreen({super.key});

  @override
  ConsumerState<EvidenceScannerScreen> createState() =>
      _EvidenceScannerScreenState();
}

class _EvidenceScannerScreenState extends ConsumerState<EvidenceScannerScreen> {
  PlatformFile? _selectedFile;
  bool _isScanning = false;
  int _scanStep = 0;
  Map<String, dynamic>? _result;
  String? _error;

  String get _baseUrl =>
      dotenv.env['RAG_BACKEND_URL'] ?? 'http://localhost:8000';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'bmp', 'tiff', 'webp'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        _showSnackBar('File too large. Maximum size is 10MB.', isError: true);
        return;
      }
      setState(() {
        _selectedFile = file;
        _result = null;
        _error = null;
      });
    }
  }

  Future<void> _scanDocument() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) return;

    setState(() {
      _isScanning = true;
      _scanStep = 1;
      _result = null;
      _error = null;
    });

    // Animate steps
    _animateSteps();

    try {
      final uri = Uri.parse('$_baseUrl/api/scan-document');
      final request = http.MultipartRequest('POST', uri);

      final ext = _selectedFile!.extension?.toLowerCase() ?? 'jpg';
      String mimeType = 'image/jpeg';
      if (ext == 'pdf') mimeType = 'application/pdf';
      else if (ext == 'png') mimeType = 'image/png';
      else if (ext == 'jpg' || ext == 'jpeg') mimeType = 'image/jpeg';
      else if (ext == 'webp') mimeType = 'image/webp';
      else if (ext == 'tiff') mimeType = 'image/tiff';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _selectedFile!.bytes!,
        filename: _selectedFile!.name,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data;
          _isScanning = false;
        });
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _error = errorData['detail'] ?? 'Scan failed';
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection failed. Make sure the backend server is running.';
        _isScanning = false;
      });
    }
  }

  void _animateSteps() async {
    for (int i = 2; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted && _isScanning) {
        setState(() => _scanStep = i);
      }
    }
  }

  void _reset() {
    setState(() {
      _selectedFile = null;
      _result = null;
      _error = null;
      _isScanning = false;
      _scanStep = 0;
    });
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Text copied to clipboard!');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2B4A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evidence Scanner', style: TextStyle(fontSize: 18)),
            Text(
              'Extract text & redact private info',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_result == null && !_isScanning) _buildUploadSection(),
            if (_isScanning) _buildLoadingSection(),
            if (_error != null) _buildErrorSection(),
            if (_result != null) ...[
              _buildResultsSection(),
              const SizedBox(height: 20),
              _buildRedactionSummary(),
              const SizedBox(height: 20),
              _buildScanAnotherButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Document',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B4A),
            ),
          ),
          const SizedBox(height: 16),

          // Upload area
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFile != null
                      ? AppColors.success
                      : const Color(0xFF1A2B4A).withOpacity(0.2),
                  width: 2,
                  style: _selectedFile != null
                      ? BorderStyle.solid
                      : BorderStyle.none,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null
                        ? Icons.check_circle
                        : Icons.description_outlined,
                    size: 48,
                    color: _selectedFile != null
                        ? AppColors.success
                        : const Color(0xFF1A2B4A).withOpacity(0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile != null
                        ? _selectedFile!.name
                        : 'Click to upload or drag and drop',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _selectedFile != null
                          ? const Color(0xFF1A2B4A)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFile != null
                        ? _formatFileSize(_selectedFile!.size)
                        : 'PDF, JPG, PNG supported  •  Max 10MB',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Scan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selectedFile != null ? _scanDocument : null,
              icon: const Icon(Icons.search),
              label: const Text(
                'Scan Document',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B4A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    final steps = [
      {'icon': Icons.menu_book, 'text': 'Reading document...'},
      {'icon': Icons.text_fields, 'text': 'Extracting text...'},
      {'icon': Icons.shield, 'text': 'Detecting private information...'},
      {'icon': Icons.content_cut, 'text': 'Applying redaction...'},
    ];

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF1A2B4A),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          const Text(
            'Scanning document...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2B4A),
            ),
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = _scanStep > index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 400),
                    child: Icon(
                      isActive ? Icons.check_circle : step['icon'] as IconData,
                      color: isActive
                          ? AppColors.success
                          : const Color(0xFF1A2B4A),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.3,
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      step['text'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive
                            ? const Color(0xFF1A2B4A)
                            : Colors.grey[400],
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A2B4A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final originalCard = _buildTextCard(
          title: 'Original Extracted Text',
          icon: Icons.description,
          borderColor: Colors.blue,
          text: _result!['extracted_text'] ?? '',
          pages: _result!['pages'] ?? 1,
          onCopy: () => _copyText(_result!['extracted_text'] ?? ''),
          copyLabel: 'Copy Text',
        );

        final isClean = _result!['is_clean'] == true;
        final totalRedacted = _result!['total_redacted'] ?? 0;

        final redactedCard = _buildTextCard(
          title: 'Redacted Version',
          icon: Icons.shield,
          borderColor: isClean ? AppColors.success : AppColors.error,
          text: _result!['redacted_text'] ?? '',
          badge: isClean
              ? 'No private data found'
              : '$totalRedacted items redacted',
          badgeColor: isClean ? AppColors.success : Colors.orange,
          onCopy: () => _copyText(_result!['redacted_text'] ?? ''),
          copyLabel: 'Copy Redacted Text',
          highlightRedacted: true,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: originalCard),
              const SizedBox(width: 16),
              Expanded(child: redactedCard),
            ],
          );
        } else {
          return Column(
            children: [
              originalCard,
              const SizedBox(height: 16),
              redactedCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildTextCard({
    required String title,
    required IconData icon,
    required Color borderColor,
    required String text,
    int? pages,
    String? badge,
    Color? badgeColor,
    required VoidCallback onCopy,
    required String copyLabel,
    bool highlightRedacted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: borderColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A2B4A),
                        ),
                      ),
                    ),
                  ],
                ),
                if (pages != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$pages page${pages > 1 ? 's' : ''} • OCR completed',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
                if (badge != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            height: 300,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: SingleChildScrollView(
              child: highlightRedacted
                  ? _buildHighlightedText(text)
                  : SelectableText(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Color(0xFF333333),
                        fontFamily: 'monospace',
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: Text(copyLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A2B4A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text) {
    // Find [TYPE REDACTED] patterns and highlight them
    final regex = RegExp(r'\[[A-Z_\s]+ REDACTED\]');
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: Color(0xFF333333),
            fontFamily: 'monospace',
          ),
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          fontSize: 13,
          height: 1.6,
          color: Colors.red,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0x20FF0000),
          fontFamily: 'monospace',
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(
          fontSize: 13,
          height: 1.6,
          color: Color(0xFF333333),
          fontFamily: 'monospace',
        ),
      ));
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  Widget _buildRedactionSummary() {
    final items = _result!['redacted_items'] as List? ?? [];
    final isClean = _result!['is_clean'] == true;

    // Group by type
    final typeCount = <String, int>{};
    for (final item in items) {
      final type = (item as Map)['type'] as String? ?? 'Unknown';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClean
              ? AppColors.success.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isClean ? Icons.verified_user : Icons.privacy_tip,
                color: isClean ? AppColors.success : Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Redaction Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isClean)
            Text(
              'This document contains no detectable private information.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: typeCount.entries.map((entry) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value} found',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildScanAnotherButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _reset,
        icon: const Icon(Icons.refresh),
        label: const Text(
          'Scan Another Document',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A2B4A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: Color(0xFF1A2B4A)),
        ),
      ),
    );
  }
}
