import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../services/supabase_service.dart';
import '../../../shared/data/models/appointment_model.dart';
import '../../../shared/presentation/providers/appointments_provider.dart';
import '../providers/cases_provider.dart';
import '../../data/models/case_model.dart';

class ClientAppointmentsScreen extends ConsumerWidget {
  const ClientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Appointments'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(appointmentsProvider.notifier).refresh(),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: state.isLoading && state.appointments.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.errorMessage != null && state.appointments.isEmpty
                ? _buildErrorView(context, ref, state.errorMessage!)
                : TabBarView(
                    children: [
                      _buildAppointmentsList(context, ref, state.upcoming, false),
                      _buildAppointmentsList(context, ref, state.past, true),
                    ],
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showRequestDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Request Appointment'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showRequestDialog(BuildContext context, WidgetRef ref) {
    final casesState = ref.read(casesProvider);
    final casesWithLawyer = casesState.cases
        .where((c) => c.lawyerId != null && c.lawyerId!.isNotEmpty)
        .toList();

    if (casesWithLawyer.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No Active Cases'),
          content: const Text(
              'You need a case with an assigned lawyer to request an appointment.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/client/cases');
              },
              child: const Text('View Cases'),
            ),
          ],
        ),
      );
      return;
    }

    _showCasePickerDialog(context, ref, casesWithLawyer);
  }

  void _showCasePickerDialog(
      BuildContext context, WidgetRef ref, List<CaseModel> cases) {
    CaseModel? selectedCase = cases.first;
    final notesController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_month,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Request Appointment',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Case',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CaseModel>(
                      isExpanded: true,
                      value: selectedCase,
                      items: cases.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c.title,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
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
                          setDialogState(() => selectedCase = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Your lawyer will confirm the date, time and meeting details.',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Notes to Lawyer (optional)',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Preferred time, what to discuss...',
                    hintStyle: TextStyle(
                        color: Colors.grey[400], fontSize: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 18),
              label: Text(isSubmitting ? 'Sending...' : 'Send Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting || selectedCase == null
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);

                      // Fetch lawyer name
                      String lawyerName = 'Your Lawyer';
                      try {
                        final profile = await SupabaseService.from('profiles')
                            .select('full_name')
                            .eq('id', selectedCase!.lawyerId!)
                            .single();
                        lawyerName =
                            profile['full_name'] as String? ?? 'Your Lawyer';
                      } catch (_) {}

                      final success = await ref
                          .read(appointmentsProvider.notifier)
                          .requestAppointment(
                            lawyerId: selectedCase!.lawyerId!,
                            lawyerName: lawyerName,
                            caseTitle: selectedCase!.title,
                            clientNotes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? 'Request sent! Waiting for lawyer to confirm.'
                              : 'Failed to send request. Please try again.'),
                          backgroundColor:
                              success ? AppColors.success : AppColors.error,
                          duration: const Duration(seconds: 3),
                        ));
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(
      BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(appointmentsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(BuildContext context, WidgetRef ref,
      List<AppointmentModel> appointments, bool isPast) {
    if (appointments.isEmpty) {
      return _buildEmptyState(
        isPast ? 'No past appointments' : 'No upcoming appointments',
        isPast
            ? 'Your completed appointments will appear here'
            : 'Tap "Request Appointment" to schedule with your lawyer',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return _AppointmentCard(
          appointment: appointments[index],
          isPast: isPast,
          onCancel: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Cancel Appointment'),
                content: const Text(
                    'Are you sure you want to cancel this appointment?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error),
                    child: const Text('Yes, Cancel',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              final success = await ref
                  .read(appointmentsProvider.notifier)
                  .cancelAppointment(appointments[index].id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Appointment cancelled'
                      : 'Failed to cancel'),
                  backgroundColor:
                      success ? AppColors.success : AppColors.error,
                ));
              }
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(Icons.calendar_today_outlined,
                  size: 60, color: AppColors.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: AppStyles.heading3
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: AppStyles.bodyText2
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isPast;
  final VoidCallback? onCancel;

  const _AppointmentCard({
    required this.appointment,
    this.isPast = false,
    this.onCancel,
  });

  Color _getStatusColor() {
    switch (appointment.status) {
      case 'confirmed':
        return AppColors.success;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return AppColors.error;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (appointment.consultationType) {
      case 'video':
        return Icons.videocam;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = appointment.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? BorderSide(color: Colors.orange.withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Date badge / status icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.1)
                        : isPast
                            ? AppColors.textSecondary.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isPending
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_top,
                                color: Colors.orange, size: 28),
                            Text('TBD',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('dd')
                                  .format(appointment.appointmentDate),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isPast
                                    ? AppColors.textSecondary
                                    : AppColors.primary,
                              ),
                            ),
                            Text(
                              DateFormat('MMM')
                                  .format(appointment.appointmentDate),
                              style: TextStyle(
                                fontSize: 11,
                                color: isPast
                                    ? AppColors.textSecondary
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.lawyerName, style: AppStyles.subtitle1),
                      if (appointment.caseTitle != null)
                        Text(appointment.caseTitle!,
                            style: AppStyles.bodyText2.copyWith(
                                color: AppColors.textSecondary)),
                      if (!isPending) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${appointment.timeSlot} · ${appointment.duration} min',
                              style: AppStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.statusDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),

            // Pending notice
            if (isPending) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Request sent. Your lawyer will confirm the date, time and meeting details.',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Confirmed meeting details box
            if (!isPending && appointment.status == 'confirmed') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Meeting Details',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.green)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(_getTypeIcon(),
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(appointment.consultationTypeDisplay,
                            style: TextStyle(
                                fontSize: 13, color: AppColors.primary)),
                      ],
                    ),
                    if (appointment.location != null &&
                        appointment.location!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            appointment.consultationType == 'video'
                                ? Icons.link
                                : Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(appointment.location!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700])),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Notes
            if (appointment.notes != null &&
                appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(appointment.notes!,
                          style: AppStyles.bodyText2
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ],

            // Cancel button
            if (!isPast && appointment.status != 'cancelled') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error),
                  ),
                ],
              ),
            ],

            // Rate Lawyer on completed past
            if (isPast && appointment.status == 'completed') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_outline,
                      size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text('How was your experience?',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.star_rounded, size: 16),
                    label: const Text('Rate Lawyer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => context.push(
                      '/client/rate-lawyer/${appointment.lawyerId}'
                      '?name=${Uri.encodeComponent(appointment.lawyerName)}'
                      '&caseTitle=${Uri.encodeComponent(appointment.caseTitle ?? '')}',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
