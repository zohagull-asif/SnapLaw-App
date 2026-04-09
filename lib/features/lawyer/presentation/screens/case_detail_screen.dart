import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../client/data/models/case_model.dart';
import '../../../client/data/models/case_update_model.dart';
import '../../../client/presentation/providers/case_updates_provider.dart';
import '../providers/lawyer_cases_provider.dart';

class CaseDetailScreen extends ConsumerStatefulWidget {
  final CaseModel caseModel;

  const CaseDetailScreen({super.key, required this.caseModel});

  @override
  ConsumerState<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends ConsumerState<CaseDetailScreen> {
  late CaseModel _currentCase;

  @override
  void initState() {
    super.initState();
    _currentCase = widget.caseModel;
  }

  Color _getStatusColor() {
    switch (_currentCase.status) {
      case CaseStatus.open:
        return AppColors.statusOpen;
      case CaseStatus.inProgress:
        return AppColors.statusInProgress;
      case CaseStatus.closed:
        return AppColors.statusClosed;
      case CaseStatus.pending:
        return AppColors.warning;
    }
  }

  void _showUpdateStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.update, color: AppColors.lawyerPrimary),
            const SizedBox(width: 12),
            const Text('Update Case Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CaseStatus.values.map((status) {
            final isSelected = _currentCase.status == status;
            return ListTile(
              title: Text(
                status.name.toUpperCase(),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.lawyerPrimary : AppColors.textPrimary,
                ),
              ),
              leading: Radio<CaseStatus>(
                value: status,
                groupValue: _currentCase.status,
                activeColor: AppColors.lawyerPrimary,
                onChanged: (value) async {
                  if (value != null) {
                    print('🔄 Changing status from ${_currentCase.status} to $value');
                    Navigator.pop(context);
                    await _updateStatus(value);
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(CaseStatus newStatus) async {
    print('⏳ [CaseDetailScreen] Updating case status to: ${newStatus.name}');
    print('📋 Case ID: ${_currentCase.id}');
    print('👨‍⚖️ Lawyer ID: ${_currentCase.lawyerId}');
    print('👤 Client ID: ${_currentCase.clientId}');

    final success = await ref.read(lawyerCasesProvider.notifier).updateCaseStatus(
          caseId: _currentCase.id,
          newStatus: newStatus,
        );

    print('✅ Update result: $success');

    if (success && mounted) {
      setState(() {
        _currentCase = _currentCase.copyWith(status: newStatus);
      });
      print('✅ Local state updated successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Case status updated to ${newStatus.name.toUpperCase()}'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      print('❌ Failed to update case status');

      // Get error message from provider if available
      final errorMessage = ref.read(lawyerCasesProvider).errorMessage;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ?? 'Failed to update case status. Check console for details.',
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print case details
    print('🔍 Case Detail Screen - Case ID: ${_currentCase.id}');
    print('📄 Document URLs: ${_currentCase.documentUrls}');
    print('📊 Has documents: ${_currentCase.documentUrls != null && _currentCase.documentUrls!.isNotEmpty}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Update Status',
            onPressed: _showUpdateStatusDialog,
          ),
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Message Client',
            onPressed: () {
              context.push('/lawyer/message-client/${_currentCase.clientId}',
                  extra: _currentCase);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(), width: 2),
              ),
              child: Row(
                children: [
                  Icon(_getStatusIcon(), color: _getStatusColor(), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentCase.statusDisplayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                          ),
                        ),
                        Text(
                          'Case ID: ${_currentCase.id.substring(0, 8)}...',
                          style: AppStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  if (_currentCase.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.priority_high, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'URGENT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title
            _buildSection(
              'Case Title',
              Icons.title,
              Text(
                _currentCase.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),

            // Type
            _buildSection(
              'Case Type',
              Icons.category,
              Chip(
                label: Text(_currentCase.typeDisplayName),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            _buildSection(
              'Description',
              Icons.description,
              Text(
                _currentCase.description,
                style: AppStyles.bodyText1,
              ),
            ),
            const SizedBox(height: 16),

            // Dates
            _buildSection(
              'Timeline',
              Icons.calendar_today,
              Column(
                children: [
                  _buildInfoRow(
                    'Created',
                    DateFormat('MMM dd, yyyy - hh:mm a').format(_currentCase.createdAt),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Last Updated',
                    _currentCase.updatedAt != null
                        ? DateFormat('MMM dd, yyyy - hh:mm a')
                            .format(_currentCase.updatedAt!)
                        : 'Never',
                  ),
                  if (_currentCase.closedAt != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Closed',
                      DateFormat('MMM dd, yyyy - hh:mm a')
                          .format(_currentCase.closedAt!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            if (_currentCase.notes != null && _currentCase.notes!.isNotEmpty)
              _buildSection(
                'Notes',
                Icons.note,
                Text(
                  _currentCase.notes!,
                  style: AppStyles.bodyText1,
                ),
              ),

            // Documents Section
            if (_currentCase.documentUrls != null && _currentCase.documentUrls!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSection(
                'Uploaded Documents',
                Icons.attach_file,
                Column(
                  children: _currentCase.documentUrls!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    return _buildDocumentItem(url, index);
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Post Case Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPostUpdateDialog(context),
                icon: const Icon(Icons.post_add),
                label: const Text('Post Case Update'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showUpdateStatusDialog,
                    icon: const Icon(Icons.update),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.lawyerPrimary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/lawyer/message-client/${_currentCase.clientId}',
                          extra: _currentCase);
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message Client'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPostUpdateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final nextActionController = TextEditingController();
    UpdateType selectedType = UpdateType.general;
    DateTime? selectedHearingDate;
    bool isPosting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.post_add, color: Colors.teal),
              const SizedBox(width: 12),
              const Text('Post Case Update'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Hearing Scheduled',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe the update...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Update Type Dropdown
                DropdownButtonFormField<UpdateType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Update Type',
                    border: OutlineInputBorder(),
                  ),
                  items: UpdateType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name[0].toUpperCase() + type.name.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Next Action (optional)
                TextField(
                  controller: nextActionController,
                  decoration: const InputDecoration(
                    labelText: 'Next Action (optional)',
                    hintText: 'e.g., Submit documents by...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Next Hearing Date (optional)
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedHearingDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Next Hearing Date (optional)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      selectedHearingDate != null
                          ? DateFormat('MMM dd, yyyy').format(selectedHearingDate!)
                          : 'Tap to select',
                      style: TextStyle(
                        color: selectedHearingDate != null
                            ? AppColors.textPrimary
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isPosting
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty ||
                          descriptionController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Title and description are required'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isPosting = true);

                      final notifier = ref.read(
                        caseUpdatesProviderFamily(_currentCase.id).notifier,
                      );

                      final success = await notifier.postUpdate(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        type: selectedType,
                        nextAction: nextActionController.text.trim().isNotEmpty
                            ? nextActionController.text.trim()
                            : null,
                        nextHearingDate: selectedHearingDate,
                      );

                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Update posted successfully!'
                                  : 'Failed to post update',
                            ),
                            backgroundColor:
                                success ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: isPosting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Post Update'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_currentCase.status) {
      case CaseStatus.open:
        return Icons.folder_open;
      case CaseStatus.inProgress:
        return Icons.pending_actions;
      case CaseStatus.closed:
        return Icons.check_circle;
      case CaseStatus.pending:
        return Icons.schedule;
    }
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppStyles.bodyText2.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppStyles.bodyText2.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(String url, int index) {
    final fileName = _getFileNameFromUrl(url);
    final fileExtension = _getFileExtension(url);
    final fileIcon = _getFileIcon(fileExtension);

    return Container(
      margin: EdgeInsets.only(bottom: index < _currentCase.documentUrls!.length - 1 ? 12 : 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lawyerPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(fileIcon, color: AppColors.lawyerPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fileExtension.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                color: AppColors.lawyerPrimary,
                tooltip: 'View Document',
                onPressed: () => _openDocument(url),
              ),
              IconButton(
                icon: const Icon(Icons.download, size: 20),
                color: AppColors.secondary,
                tooltip: 'Download Document',
                onPressed: () => _downloadDocument(url, fileName),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final fileName = segments.last;
        // Remove timestamp prefix if exists (format: timestamp_filename)
        final parts = fileName.split('_');
        if (parts.length > 1 && int.tryParse(parts[0]) != null) {
          return parts.sublist(1).join('_');
        }
        return fileName;
      }
      return 'Document ${_currentCase.documentUrls!.indexOf(url) + 1}';
    } catch (e) {
      return 'Document ${_currentCase.documentUrls!.indexOf(url) + 1}';
    }
  }

  String _getFileExtension(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDot = path.lastIndexOf('.');
      if (lastDot != -1 && lastDot < path.length - 1) {
        return path.substring(lastDot + 1);
      }
      return 'file';
    } catch (e) {
      return 'file';
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
      case 'gif':
        return Icons.image;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _openDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open document'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening document: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _downloadDocument(String url, String fileName) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $fileName...'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot download document'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading document: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
