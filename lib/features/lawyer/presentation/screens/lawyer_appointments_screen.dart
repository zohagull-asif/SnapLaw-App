import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../shared/data/models/appointment_model.dart';
import '../../../shared/presentation/providers/appointments_provider.dart';

class LawyerAppointmentsScreen extends ConsumerStatefulWidget {
  const LawyerAppointmentsScreen({super.key});

  @override
  ConsumerState<LawyerAppointmentsScreen> createState() =>
      _LawyerAppointmentsScreenState();
}

class _LawyerAppointmentsScreenState
    extends ConsumerState<LawyerAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentsProvider);
    final pendingCount =
        state.appointments.where((a) => a.status == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withOpacity(0.6),
          indicatorColor: AppColors.secondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Requests'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Upcoming'),
            const Tab(text: 'Past'),
          ],
        ),
      ),
      body: state.isLoading && state.appointments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingRequests(state.appointments
                    .where((a) => a.status == 'pending')
                    .toList()),
                _buildAppointmentsList(state.upcoming, false),
                _buildAppointmentsList(state.past, true),
              ],
            ),
    );
  }

  // ─── Pending Requests Tab ───
  Widget _buildPendingRequests(List<AppointmentModel> pending) {
    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No pending requests',
                style: AppStyles.subtitle1
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('New appointment requests from clients will appear here',
                style: AppStyles.bodyText2
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        return _PendingRequestCard(
          appointment: pending[index],
          onSchedule: () => _showScheduleDialog(pending[index]),
          onDecline: () => _declineRequest(pending[index]),
        );
      },
    );
  }

  void _showScheduleDialog(AppointmentModel appt) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 3));
    String selectedTime = '10:00 AM';
    String selectedType = 'in-person';
    final locationController = TextEditingController();
    final notesController = TextEditingController(text: appt.notes ?? '');
    int selectedDuration = 60;
    bool isSubmitting = false;

    final times = [
      '09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM',
      '11:30 AM', '12:00 PM', '12:30 PM', '01:00 PM', '01:30 PM',
      '02:00 PM', '02:30 PM', '03:00 PM', '03:30 PM', '04:00 PM',
      '04:30 PM', '05:00 PM',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.lawyerPrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Schedule Meeting',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('with ${appt.clientName}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13)),
                      if (appt.caseTitle != null) ...[
                        const SizedBox(height: 2),
                        Text('Case: ${appt.caseTitle}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12)),
                      ],
                    ],
                  ),
                ),

                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        const Text('Date',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 180)),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy')
                                      .format(selectedDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Time
                        const Text('Time',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedTime,
                              items: times
                                  .map((t) => DropdownMenuItem(
                                      value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (v) => setDialogState(
                                  () => selectedTime = v!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Meeting type
                        const Text('Meeting Type',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MeetingTypeChip(
                              icon: Icons.person,
                              label: 'In-Person',
                              value: 'in-person',
                              selected: selectedType == 'in-person',
                              onTap: () => setDialogState(
                                  () => selectedType = 'in-person'),
                            ),
                            const SizedBox(width: 8),
                            _MeetingTypeChip(
                              icon: Icons.videocam,
                              label: 'Video',
                              value: 'video',
                              selected: selectedType == 'video',
                              onTap: () => setDialogState(
                                  () => selectedType = 'video'),
                            ),
                            const SizedBox(width: 8),
                            _MeetingTypeChip(
                              icon: Icons.phone,
                              label: 'Phone',
                              value: 'phone',
                              selected: selectedType == 'phone',
                              onTap: () => setDialogState(
                                  () => selectedType = 'phone'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Location / Link
                        Text(
                          selectedType == 'video'
                              ? 'Video Call Link'
                              : selectedType == 'phone'
                                  ? 'Phone Number / Instructions'
                                  : 'Office Address / Location',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            hintText: selectedType == 'video'
                                ? 'e.g. https://meet.google.com/abc-xyz'
                                : selectedType == 'phone'
                                    ? 'e.g. +92 300 1234567'
                                    : 'e.g. Office 3, Floor 5, XYZ Plaza, Lahore',
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            prefixIcon: Icon(
                              selectedType == 'video'
                                  ? Icons.link
                                  : selectedType == 'phone'
                                      ? Icons.phone
                                      : Icons.location_on,
                              color: AppColors.primary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Duration
                        const Text('Duration',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Row(
                          children: [30, 60, 90, 120].map((d) {
                            final isSelected = selectedDuration == d;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setDialogState(
                                    () => selectedDuration = d),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.lawyerPrimary
                                        : Colors.grey[100],
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${d}min',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Notes for client
                        const Text('Instructions / Notes for Client',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Please bring your documents, parking info...',
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
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle, size: 18),
                          label: Text(
                              isSubmitting ? 'Confirming...' : 'Confirm & Send'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lawyerPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setDialogState(() => isSubmitting = true);

                                  final success = await ref
                                      .read(appointmentsProvider.notifier)
                                      .confirmWithSchedule(
                                        appointmentId: appt.id,
                                        date: selectedDate,
                                        timeSlot: selectedTime,
                                        consultationType: selectedType,
                                        location: locationController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : locationController.text.trim(),
                                        duration: selectedDuration,
                                        notes: notesController.text.trim().isEmpty
                                            ? null
                                            : notesController.text.trim(),
                                      );

                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(success
                                          ? 'Appointment confirmed! Client has been notified.'
                                          : 'Failed to confirm. Please try again.'),
                                      backgroundColor: success
                                          ? AppColors.success
                                          : AppColors.error,
                                    ));
                                  }
                                },
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
    );
  }

  Future<void> _declineRequest(AppointmentModel appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Request'),
        content: Text(
            'Decline appointment request from ${appt.clientName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Decline',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final success = await ref
          .read(appointmentsProvider.notifier)
          .cancelAppointment(appt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Request declined' : 'Failed to decline'),
          backgroundColor: success ? Colors.grey : AppColors.error,
        ));
      }
    }
  }

  // ─── Upcoming / Past Tabs ───
  Widget _buildAppointmentsList(
      List<AppointmentModel> appointments, bool isPast) {
    final nonPending =
        appointments.where((a) => a.status != 'pending').toList();

    if (nonPending.isEmpty) {
      return _buildEmptyState(
        isPast ? 'No past appointments' : 'No upcoming appointments',
        isPast
            ? 'Your completed appointments will appear here'
            : 'Confirmed appointments will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: nonPending.length,
      itemBuilder: (context, index) {
        return _LawyerAppointmentCard(
          appointment: nonPending[index],
          isPast: isPast,
          onConfirm: () => _updateStatus(nonPending[index].id, 'confirmed'),
          onComplete: () =>
              _updateStatus(nonPending[index].id, 'completed'),
          onCancel: () => _cancelAppointment(nonPending[index]),
        );
      },
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    final success = await ref
        .read(appointmentsProvider.notifier)
        .updateAppointmentStatus(appointmentId: id, newStatus: status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Appointment ${status == 'confirmed' ? 'confirmed' : 'completed'}!'
            : 'Failed to update'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
    }
  }

  Future<void> _cancelAppointment(AppointmentModel appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
            'Cancel appointment with ${appt.clientName} on ${DateFormat('MMM d').format(appt.appointmentDate)} at ${appt.timeSlot}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await ref
          .read(appointmentsProvider.notifier)
          .cancelAppointment(appt.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(success ? 'Appointment cancelled' : 'Failed to cancel'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ));
      }
    }
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available,
              size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title,
              style: AppStyles.subtitle1
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: AppStyles.bodyText2
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Pending Request Card ──
class _PendingRequestCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onSchedule;
  final VoidCallback onDecline;

  const _PendingRequestCard({
    required this.appointment,
    required this.onSchedule,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add,
                      color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.clientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      if (appointment.caseTitle != null)
                        Text(
                          'Case: ${appointment.caseTitle}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('New Request',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                ),
              ],
            ),
            if (appointment.notes != null &&
                appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.notes!,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onSchedule,
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Schedule & Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lawyerPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
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
}

// ── Meeting Type Chip ──
class _MeetingTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _MeetingTypeChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.lawyerPrimary
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppColors.lawyerPrimary
                  : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? Colors.white : Colors.grey[600]),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirmed Appointment Card (Upcoming/Past) ──
class _LawyerAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isPast;
  final VoidCallback? onConfirm;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;

  const _LawyerAppointmentCard({
    required this.appointment,
    this.isPast = false,
    this.onConfirm,
    this.onComplete,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd')
                            .format(appointment.appointmentDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        DateFormat('MMM')
                            .format(appointment.appointmentDate),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.clientName,
                          style: AppStyles.subtitle1),
                      if (appointment.caseTitle != null)
                        Text(
                          appointment.caseTitle!,
                          style: AppStyles.caption.copyWith(
                              color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    appointment.statusDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                    '${appointment.timeSlot} · ${appointment.duration} min',
                    style: AppStyles.caption),
                const SizedBox(width: 16),
                Icon(_getTypeIcon(), size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(appointment.consultationTypeDisplay,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ],
            ),
            if (appointment.location != null &&
                appointment.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    appointment.consultationType == 'video'
                        ? Icons.link
                        : Icons.location_on,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(appointment.location!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ),
                ],
              ),
            ],
            if (appointment.notes != null &&
                appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(appointment.notes!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (!isPast && appointment.status != 'cancelled') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (appointment.status == 'confirmed')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  if (appointment.status == 'confirmed')
                    const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
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
