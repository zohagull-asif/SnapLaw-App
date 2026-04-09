import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Service for extracting text from various document types
class DocumentTextExtractor {
  /// Extract text from a PlatformFile
  /// For now, supports text files and attempts to read PDF as text
  /// For production, you should use proper PDF parsing libraries
  Future<String> extractTextFromFile(PlatformFile file) async {
    try {
      if (file.bytes == null) {
        throw Exception('File has no data');
      }

      final extension = file.extension?.toLowerCase() ?? '';

      switch (extension) {
        case 'txt':
          return _extractFromText(file.bytes!);
        case 'pdf':
          return await _extractFromPDF(file.bytes!);
        case 'doc':
        case 'docx':
          // For DOC/DOCX, you need additional libraries
          // For now, return a message asking user to convert
          throw Exception(
              'DOC/DOCX files require conversion. Please save as PDF or TXT');
        default:
          throw Exception('Unsupported file type: $extension');
      }
    } catch (e) {
      print('❌ Error extracting text from file: $e');
      rethrow;
    }
  }

  /// Extract text from plain text file
  String _extractFromText(Uint8List bytes) {
    return String.fromCharCodes(bytes);
  }

  /// Extract text from PDF
  /// NOTE: This is a simplified version. For production, use:
  /// - pdf_text package
  /// - syncfusion_flutter_pdf package
  /// - Or server-side PDF processing
  Future<String> _extractFromPDF(Uint8List bytes) async {
    // For this implementation, we'll return a placeholder
    // In production, you should use a proper PDF parsing library
    print('⚠️ PDF text extraction not fully implemented');
    print('📄 PDF file size: ${bytes.length} bytes');

    // Temporary: Try to extract as text (will only work for simple PDFs)
    try {
      final text = String.fromCharCodes(bytes);
      // Basic cleaning - remove null chars and control characters
      final cleaned = text.replaceAll(RegExp(r'[\x00-\x1F]'), ' ').trim();

      if (cleaned.length > 100) {
        return cleaned;
      }
    } catch (e) {
      print('⚠️ Could not extract as plain text: $e');
    }

    throw Exception(
      'PDF text extraction requires additional setup. '
      'Please install pdf_text package or use server-side processing. '
      'For testing, convert PDF to TXT file.',
    );
  }

  /// Download file from URL and extract text
  Future<String> extractTextFromUrl(String url) async {
    try {
      // This would require downloading the file first
      // For now, throw an error
      throw Exception('URL text extraction not implemented yet');
    } catch (e) {
      print('❌ Error extracting text from URL: $e');
      rethrow;
    }
  }

  /// Validate if file type is supported
  bool isSupportedFileType(String? extension) {
    if (extension == null) return false;
    final ext = extension.toLowerCase();
    return ['txt', 'pdf', 'doc', 'docx'].contains(ext);
  }

  /// Get list of supported file extensions
  List<String> get supportedExtensions => ['txt', 'pdf'];
}
