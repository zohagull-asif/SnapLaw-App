import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/supabase_service.dart';
import '../../data/models/appointment_model.dart';

class AppointmentsState {
  final List<AppointmentModel> appointments;
  final bool isLoading;
  final String? errorMessage;

  const AppointmentsState({
    this.appointments = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AppointmentsState copyWith({
    List<AppointmentModel>? appointments,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppointmentsState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  List<AppointmentModel> get upcoming =>
      appointments.where((a) => a.isUpcoming).toList()
        ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

  List<AppointmentModel> get past =>
      appointments.where((a) => a.isPast).toList()
        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
}

class AppointmentsNotifier extends StateNotifier<AppointmentsState> {
  StreamSubscription? _subscription;

  AppointmentsNotifier() : super(const AppointmentsState()) {
    loadAppointments();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribeToUpdates() {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) return;

    _subscription = SupabaseService.from('appointments')
        .stream(primaryKey: ['id'])
        .listen((data) {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final filtered = data.where((row) =>
          row['client_id'] == userId || row['lawyer_id'] == userId);

      final appointments =
          filtered.map((json) => AppointmentModel.fromJson(json)).toList();
      state = state.copyWith(appointments: appointments, isLoading: false);
    });
  }

  Future<void> loadAppointments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, errorMessage: 'Not logged in');
        return;
      }

      // Fetch appointments where user is client OR lawyer
      final clientAppts = await SupabaseService.from('appointments')
          .select()
          .eq('client_id', user.id)
          .order('appointment_date', ascending: false);

      final lawyerAppts = await SupabaseService.from('appointments')
          .select()
          .eq('lawyer_id', user.id)
          .order('appointment_date', ascending: false);

      // Merge and deduplicate
      final allData = <String, dynamic>{};
      for (final row in [...(clientAppts as List), ...(lawyerAppts as List)]) {
        allData[row['id']] = row;
      }

      final appointments = allData.values
          .map((json) => AppointmentModel.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      state = state.copyWith(appointments: appointments, isLoading: false);
    } on PostgrestException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load appointments: ${e.message}',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }

  /// Book a new appointment
  Future<bool> bookAppointment({
    required String lawyerId,
    required String lawyerName,
    required DateTime date,
    required String timeSlot,
    required String consultationType,
    String? notes,
  }) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return false;

      // Get client name from profiles
      final profile = await SupabaseService.from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      final clientName = profile['full_name'] ?? 'Client';

      await SupabaseService.from('appointments').insert({
        'client_id': user.id,
        'lawyer_id': lawyerId,
        'lawyer_name': lawyerName,
        'client_name': clientName,
        'appointment_date': date.toIso8601String().split('T')[0],
        'time_slot': timeSlot,
        'consultation_type': consultationType,
        'status': 'confirmed',
        'duration': 60,
        'notes': notes,
      });

      await loadAppointments();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to book appointment: ${e.toString()}',
      );
      return false;
    }
  }

  /// Get booked slots for a specific lawyer on a specific date
  Future<List<String>> getBookedSlots({
    required String lawyerId,
    required DateTime date,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await SupabaseService.from('appointments')
          .select('time_slot')
          .eq('lawyer_id', lawyerId)
          .eq('appointment_date', dateStr)
          .neq('status', 'cancelled');

      return (response as List)
          .map((row) => row['time_slot'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Update appointment status (confirm, cancel, complete)
  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String newStatus,
  }) async {
    try {
      await SupabaseService.from('appointments')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);

      await loadAppointments();
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update: ${e.toString()}',
      );
      return false;
    }
  }

  /// Cancel an appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    return updateAppointmentStatus(
      appointmentId: appointmentId,
      newStatus: 'cancelled',
    );
  }

  /// Complete an appointment
  Future<bool> completeAppointment(String appointmentId) async {
    return updateAppointmentStatus(
      appointmentId: appointmentId,
      newStatus: 'completed',
    );
  }

  /// Client requests an appointment with their lawyer for a specific case
  Future<bool> requestAppointment({
    required String lawyerId,
    required String lawyerName,
    required String caseTitle,
    String? clientNotes,
  }) async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) return false;

      final profile = await SupabaseService.from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      final clientName = profile['full_name'] as String? ?? 'Client';

      // Placeholder date — lawyer will set real date when confirming
      final placeholder = DateTime.now().add(const Duration(days: 30));

      await SupabaseService.from('appointments').insert({
        'client_id': user.id,
        'lawyer_id': lawyerId,
        'lawyer_name': lawyerName,
        'client_name': clientName,
        'case_title': caseTitle,
        'appointment_date': placeholder.toIso8601String().split('T')[0],
        'time_slot': 'TBD',
        'consultation_type': 'in-person',
        'status': 'pending',
        'duration': 60,
        'notes': clientNotes,
      });

      await loadAppointments();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to request: ${e.toString()}');
      return false;
    }
  }

  /// Lawyer confirms a pending request with full schedule details
  Future<bool> confirmWithSchedule({
    required String appointmentId,
    required DateTime date,
    required String timeSlot,
    required String consultationType,
    String? location,
    int duration = 60,
    String? notes,
  }) async {
    try {
      await SupabaseService.from('appointments')
          .update({
            'status': 'confirmed',
            'appointment_date': date.toIso8601String().split('T')[0],
            'time_slot': timeSlot,
            'consultation_type': consultationType,
            'location': location,
            'duration': duration,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId);

      await loadAppointments();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to confirm: ${e.toString()}');
      return false;
    }
  }

  Future<void> refresh() async {
    await loadAppointments();
  }
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, AppointmentsState>(
  (ref) => AppointmentsNotifier(),
);
