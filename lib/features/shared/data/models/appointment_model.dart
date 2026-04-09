class AppointmentModel {
  final String id;
  final String clientId;
  final String lawyerId;
  final String lawyerName;
  final String clientName;
  final String? caseTitle;
  final DateTime appointmentDate;
  final String timeSlot;
  final String consultationType; // in-person, video, phone
  final String status; // pending, confirmed, cancelled, completed
  final int duration; // in minutes
  final String? notes;
  final String? location;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AppointmentModel({
    required this.id,
    required this.clientId,
    required this.lawyerId,
    required this.lawyerName,
    required this.clientName,
    this.caseTitle,
    required this.appointmentDate,
    required this.timeSlot,
    this.consultationType = 'in-person',
    this.status = 'pending',
    this.duration = 60,
    this.notes,
    this.location,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      lawyerId: json['lawyer_id'] as String,
      lawyerName: json['lawyer_name'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      caseTitle: json['case_title'] as String?,
      appointmentDate: DateTime.parse(json['appointment_date'] as String),
      timeSlot: json['time_slot'] as String,
      consultationType: json['consultation_type'] as String? ?? 'in-person',
      status: json['status'] as String? ?? 'pending',
      duration: json['duration'] as int? ?? 60,
      notes: json['notes'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'lawyer_id': lawyerId,
      'lawyer_name': lawyerName,
      'client_name': clientName,
      'case_title': caseTitle,
      'appointment_date': appointmentDate.toIso8601String().split('T')[0],
      'time_slot': timeSlot,
      'consultation_type': consultationType,
      'status': status,
      'duration': duration,
      'notes': notes,
      'location': location,
    };
  }

  String get consultationTypeDisplay {
    switch (consultationType) {
      case 'in-person':
        return 'In-Person';
      case 'video':
        return 'Video Call';
      case 'phone':
        return 'Phone Call';
      default:
        return consultationType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
      status != 'cancelled' &&
      status != 'completed';

  bool get isPast =>
      appointmentDate.isBefore(DateTime.now()) || status == 'completed';

  AppointmentModel copyWith({String? status}) {
    return AppointmentModel(
      id: id,
      clientId: clientId,
      lawyerId: lawyerId,
      lawyerName: lawyerName,
      clientName: clientName,
      caseTitle: caseTitle,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      consultationType: consultationType,
      status: status ?? this.status,
      duration: duration,
      notes: notes,
      location: location,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
