import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/supabase_service.dart';
import '../../../shared/presentation/providers/appointments_provider.dart';
import '../providers/cases_provider.dart';
import '../../data/models/case_model.dart';

class LawyerBookingScreen extends ConsumerStatefulWidget {
  final String lawyerId;
  final String lawyerName;

  const LawyerBookingScreen({
    super.key,
    required this.lawyerId,
    required this.lawyerName,
  });

  @override
  ConsumerState<LawyerBookingScreen> createState() =>
      _LawyerBookingScreenState();
}

class _LawyerBookingScreenState extends ConsumerState<LawyerBookingScreen> {
  final _notesController = TextEditingController();
  CaseModel? _selectedCase;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    setState(() => _isSubmitting = true);

    // Fetch lawyer name if not passed (fallback)
    String lawyerName = widget.lawyerName;
    if (lawyerName.isEmpty || lawyerName == 'Lawyer') {
      try {
        final profile = await SupabaseService.from('profiles')
            .select('full_name')
            .eq('id', widget.lawyerId)
            .single();
        lawyerName = profile['full_name'] as String? ?? 'Lawyer';
      } catch (_) {}
    }

    final success = await ref
        .read(appointmentsProvider.notifier)
        .requestAppointment(
          lawyerId: widget.lawyerId,
          lawyerName: lawyerName,
          caseTitle: _selectedCase?.title ?? 'General Consultation',
          clientNotes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send request. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Request Sent!',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              '${widget.lawyerName} will review your request and confirm the date, time and meeting details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('Done',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final casesState = ref.watch(casesProvider);
    final casesWithThisLawyer = casesState.cases
        .where((c) => c.lawyerId == widget.lawyerId)
        .toList();

    // Auto-select first matching case
    if (_selectedCase == null && casesWithThisLawyer.isNotEmpty) {
      _selectedCase = casesWithThisLawyer.first;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Request Consultation',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Lawyer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.85)
                  ],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.lawyerName.isNotEmpty
                          ? widget.lawyerName[0].toUpperCase()
                          : 'L',
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lawyerName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified,
                                color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Verified Lawyer',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Send a consultation request. The lawyer will confirm the date, time and meeting format.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Case selector (if client has cases with this lawyer)
                  if (casesWithThisLawyer.isNotEmpty) ...[
                    const Text('Related Case',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CaseModel>(
                          isExpanded: true,
                          value: _selectedCase,
                          items: casesWithThisLawyer.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(c.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14),
                                      overflow: TextOverflow.ellipsis),
                                  Text(c.typeDisplayName,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCase = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notes
                  const Text('Message to Lawyer',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Describe what you\'d like to discuss (optional)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. I need advice on my employment contract dispute...',
                        hintStyle: TextStyle(
                            color: Colors.grey[400], fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'Sending Request...'
                            : 'Send Consultation Request',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSubmitting ? null : _sendRequest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
