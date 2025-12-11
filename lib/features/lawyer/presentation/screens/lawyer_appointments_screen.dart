import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_styles.dart';

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
  DateTime _selectedDate = DateTime.now();
  final List<_AppointmentModel> _appointments = [];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mySchedule),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textLight,
          unselectedLabelColor: AppColors.textLight.withOpacity(0.6),
          indicatorColor: AppColors.secondary,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildPastTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final upcomingAppointments = _appointments
        .where((a) => a.dateTime.isAfter(DateTime.now()))
        .toList();

    if (upcomingAppointments.isEmpty) {
      return _buildEmptyState(
        'No upcoming appointments',
        'Your scheduled appointments will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingAppointments.length,
      itemBuilder: (context, index) {
        return _AppointmentCard(appointment: upcomingAppointments[index]);
      },
    );
  }

  Widget _buildPastTab() {
    final pastAppointments = _appointments
        .where((a) => a.dateTime.isBefore(DateTime.now()))
        .toList();

    if (pastAppointments.isEmpty) {
      return _buildEmptyState(
        'No past appointments',
        'Your completed appointments will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pastAppointments.length,
      itemBuilder: (context, index) {
        return _AppointmentCard(
          appointment: pastAppointments[index],
          isPast: true,
        );
      },
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        // Simple Calendar Header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: AppStyles.heading3,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Week Days Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Text(
                          day,
                          style: AppStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),

        // Calendar Grid
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday % 7;

    final days = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < startingWeekday; i++) {
      days.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final isToday = _isSameDay(date, DateTime.now());
      final hasAppointments = _appointments.any(
        (a) => _isSameDay(a.dateTime, date),
      );

      days.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary
                  : _isSameDay(date, _selectedDate)
                      ? AppColors.primary.withOpacity(0.1)
                      : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: isToday
                        ? AppColors.textLight
                        : AppColors.textPrimary,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (hasAppointments)
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.secondary
                            : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      padding: const EdgeInsets.all(16),
      children: days,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppStyles.subtitle1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppStyles.bodyText2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentModel {
  final String id;
  final String clientName;
  final String caseTitle;
  final DateTime dateTime;
  final int duration;
  final String? notes;
  final bool isConfirmed;

  _AppointmentModel({
    required this.id,
    required this.clientName,
    required this.caseTitle,
    required this.dateTime,
    required this.duration,
    this.notes,
    this.isConfirmed = false,
  });
}

class _AppointmentCard extends StatelessWidget {
  final _AppointmentModel appointment;
  final bool isPast;

  const _AppointmentCard({
    required this.appointment,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        DateFormat('dd').format(appointment.dateTime),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(appointment.dateTime),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.clientName,
                        style: AppStyles.subtitle1,
                      ),
                      Text(
                        appointment.caseTitle,
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appointment.isConfirmed
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      appointment.isConfirmed ? 'Confirmed' : 'Pending',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: appointment.isConfirmed
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('h:mm a').format(appointment.dateTime)} - ${appointment.duration} min',
                  style: AppStyles.caption,
                ),
              ],
            ),
            if (!isPast) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Reschedule
                      },
                      child: const Text('Reschedule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Start meeting
                      },
                      child: const Text('Start'),
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
