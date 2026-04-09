import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/local_contract_analyzer.dart';
import '../../../../services/document_text_extractor.dart';
import '../../data/models/case_model.dart';
import '../providers/cases_provider.dart';
import '../providers/lawyers_provider.dart';
import 'contract_risk_analysis_screen.dart';

class CreateCaseScreen extends ConsumerStatefulWidget {
  final LawyerModel? selectedLawyer;

  const CreateCaseScreen({super.key, this.selectedLawyer});

  @override
  ConsumerState<CreateCaseScreen> createState() => _CreateCaseScreenState();
}

class _CreateCaseScreenState extends ConsumerState<CreateCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  CaseType _selectedType = CaseType.civil;
  bool _isUrgent = false;
  bool _isLoading = false;
  List<PlatformFile> _selectedFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        withData: true, // CRITICAL: This loads file bytes for upload
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
        print('✅ Selected ${result.files.length} file(s)');
        for (final file in result.files) {
          print('📄 File: ${file.name} (${file.size} bytes, has bytes: ${file.bytes != null})');
        }
      }
    } catch (e) {
      print('❌ Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  /// Analyzes a document for risk using local Pakistani law dataset
  Future<void> _analyzeDocument(PlatformFile file) async {
    try {
      print('📄 [RISK RADAR] Starting analysis for: ${file.name}');
      print('   File size: ${file.size} bytes');
      print('   File extension: ${file.extension}');
      print('   Has bytes: ${file.bytes != null}');
      print('   Bytes length: ${file.bytes?.length ?? 0}');

      // CRITICAL: Check if file has bytes loaded
      if (file.bytes == null || file.bytes!.isEmpty) {
        print('❌ ERROR: File has no bytes loaded!');
        print('⚠️ This means withData: true might not be working');
        throw Exception(
          'Cannot read file data. Please try:\n'
          '1. Selecting the file again\n'
          '2. Using a different file\n'
          '3. Restarting the app');
      }

      print('✅ File bytes loaded successfully');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing document...'),
                  SizedBox(height: 8),
                  Text(
                    'Using local Pakistani law patterns',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      print('📄 [LOCAL] Analyzing document: ${file.name}');

      // Step 1: Extract text from document
      final textExtractor = DocumentTextExtractor();

      if (!textExtractor.isSupportedFileType(file.extension)) {
        Navigator.pop(context); // Close loading dialog
        throw Exception(
            'Unsupported file type. Please use TXT or PDF files for analysis.');
      }

      String documentText;
      try {
        documentText = await textExtractor.extractTextFromFile(file);
        print('✅ Extracted ${documentText.length} characters from document');
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        throw Exception('Could not read document: ${e.toString()}');
      }

      if (documentText.length < 100) {
        Navigator.pop(context); // Close loading dialog
        throw Exception(
            'Document is too short or empty. Please provide a valid legal document.');
      }

      // Step 2: Validate document using local analyzer
      print('🔍 Validating document with local patterns...');
      final validation = await LocalContractAnalyzer.validateDocument(documentText);

      if (!validation.isValid) {
        Navigator.pop(context); // Close loading dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  const Text('Invalid Document'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(validation.reason),
                  const SizedBox(height: 16),
                  const Text(
                    'Please upload a valid legal document such as:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Contracts (sale, lease, employment)\n'
                    '• Legal notices\n'
                    '• Court petitions\n'
                    '• Agreements (NDA, MOU, etc.)',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _removeFile(_selectedFiles.indexOf(file));
                  },
                  child: const Text('Remove File'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Keep Anyway'),
                ),
              ],
            ),
          );
        }
        return;
      }

      print('✅ Document validated: ${validation.documentType}');

      // Step 3: Analyze contract risk using local patterns
      print('🔍 Analyzing contract risk with local dataset...');
      final analysis = await LocalContractAnalyzer.analyzeContract(documentText);

      // Close loading dialog
      Navigator.pop(context);

      print('✅ Analysis complete: ${analysis.overallRiskLevel}');

      // Step 4: Navigate to analysis screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContractRiskAnalysisScreen(
              analysis: analysis,
              documentName: file.name,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error analyzing document: $e');
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog if still open
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<List<String>> _uploadDocuments() async {
    final uploadedUrls = <String>[];

    print('📦 Starting document upload for ${_selectedFiles.length} file(s)');

    for (final file in _selectedFiles) {
      try {
        print('📄 Processing file: ${file.name}');
        print('   Size: ${file.size} bytes');
        print('   Extension: ${file.extension}');
        print('   Has bytes: ${file.bytes != null}');

        if (file.bytes == null) {
          print('⚠️ File ${file.name} has no bytes, skipping');
          print('⚠️ HINT: Make sure withData: true is set in FilePicker.pickFiles()');
          continue;
        }

        // Create unique file name with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${timestamp}_${file.name}';
        final filePath = 'case_documents/$fileName';

        print('📤 Uploading ${file.name} to Supabase...');
        print('   Path: $filePath');
        print('   Bucket: documents');
        print('   Size: ${file.bytes!.length} bytes');

        // Upload to Supabase Storage
        final uploadResponse = await SupabaseService.storage
            .from('documents')
            .uploadBinary(
              filePath,
              file.bytes!,
            );

        print('📡 Upload response: $uploadResponse');

        // Get public URL
        final url = SupabaseService.storage
            .from('documents')
            .getPublicUrl(filePath);

        uploadedUrls.add(url);
        print('✅ Successfully uploaded ${file.name}');
        print('   Public URL: $url');
      } catch (e, stackTrace) {
        print('❌ Error uploading ${file.name}: $e');
        print('📚 Stack trace: $stackTrace');

        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload ${file.name}: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    print('📊 Upload summary: ${uploadedUrls.length}/${_selectedFiles.length} files uploaded');
    return uploadedUrls;
  }

  Future<void> _handleCreateCase() async {
    if (widget.selectedLawyer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a lawyer first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Upload documents first if any
      List<String>? documentUrls;
      if (_selectedFiles.isNotEmpty) {
        print('📤 Uploading ${_selectedFiles.length} documents...');
        documentUrls = await _uploadDocuments();
        print('✅ Uploaded ${documentUrls.length} documents');
      }

      final success = await ref.read(casesProvider.notifier).createCase(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            type: _selectedType,
            isUrgent: _isUrgent,
            lawyerId: widget.selectedLawyer!.id,
            documentUrls: documentUrls,
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                documentUrls != null && documentUrls.isNotEmpty
                    ? 'Case created with ${documentUrls.length} document(s)!'
                    : 'Case created successfully!',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        } else {
          final errorMessage = ref.read(casesProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Error creating case'),
              backgroundColor: AppColors.error,
            ),
          );
          ref.read(casesProvider.notifier).clearError();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createCase),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Selected Lawyer Card
              if (widget.selectedLawyer != null) ...[
                _buildSelectedLawyerCard(),
                const SizedBox(height: 16),
              ],

              // Case Title
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: AppStyles.inputDecoration(
                  labelText: AppStrings.caseTitle,
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a case title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Case Type
              DropdownButtonFormField<CaseType>(
                value: _selectedType,
                decoration: AppStyles.inputDecoration(
                  labelText: AppStrings.caseType,
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                items: CaseType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Case Description
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                decoration: AppStyles.inputDecoration(
                  labelText: AppStrings.caseDescription,
                  hintText: 'Describe your legal issue in detail...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please provide a description';
                  }
                  if (value.length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Urgent Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isUrgent
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.priority_high,
                        color: _isUrgent
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mark as Urgent',
                            style: AppStyles.subtitle1,
                          ),
                          Text(
                            'This case requires immediate attention',
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isUrgent,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent = value;
                        });
                      },
                      activeColor: AppColors.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attach Documents Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          AppStrings.attachDocuments,
                          style: AppStyles.subtitle1,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload relevant documents like contracts, agreements, or evidence (Optional)',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose Files'),
                      style: AppStyles.outlinedButtonStyle,
                    ),
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedFiles.length,
                        itemBuilder: (context, index) {
                          final file = _selectedFiles[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getFileIcon(file.extension ?? ''),
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        style: AppStyles.bodyText2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _formatFileSize(file.size),
                                        style: AppStyles.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Analyze Risk Button
                                IconButton(
                                  icon: const Icon(Icons.analytics_outlined, size: 20),
                                  onPressed: () => _analyzeDocument(file),
                                  tooltip: 'Analyze Risk',
                                  color: AppColors.secondary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => _removeFile(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateCase,
                  style: AppStyles.primaryButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textLight,
                            ),
                          ),
                        )
                      : const Text(
                          AppStrings.createCase,
                          style: AppStyles.button,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedLawyerCard() {
    final lawyer = widget.selectedLawyer!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: lawyer.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      lawyer.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 28,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Submitting to:',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (lawyer.isVerified) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  lawyer.name,
                  style: AppStyles.subtitle1.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  lawyer.specialization ?? 'General Practice',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Rating
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lawyer.rating.toStringAsFixed(1),
                    style: AppStyles.subtitle2,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '\$${lawyer.hourlyRate.toStringAsFixed(0)}/hr',
                style: AppStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(CaseType type) {
    switch (type) {
      case CaseType.criminal:
        return 'Criminal';
      case CaseType.civil:
        return 'Civil';
      case CaseType.family:
        return 'Family';
      case CaseType.corporate:
        return 'Corporate';
      case CaseType.immigration:
        return 'Immigration';
      case CaseType.realEstate:
        return 'Real Estate';
      case CaseType.intellectualProperty:
        return 'Intellectual Property';
      case CaseType.labor:
        return 'Labor';
      case CaseType.tax:
        return 'Tax';
      case CaseType.other:
        return 'Other';
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
