class CaseUpdateModel {
  final String id;
  final String caseId;
  final String title;
  final String description;
  final UpdateType type;
  final DateTime timestamp;
  final String? lawyerName;
  final String? nextAction;
  final DateTime? nextHearingDate;
  final List<String>? attachments;

  const CaseUpdateModel({
    required this.id,
    required this.caseId,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.lawyerName,
    this.nextAction,
    this.nextHearingDate,
    this.attachments,
  });

  factory CaseUpdateModel.fromJson(Map<String, dynamic> json) {
    return CaseUpdateModel(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: UpdateType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => UpdateType.general,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      lawyerName: json['lawyer_name'] as String?,
      nextAction: json['next_action'] as String?,
      nextHearingDate: json['next_hearing_date'] != null
          ? DateTime.parse(json['next_hearing_date'] as String)
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List<dynamic>).cast<String>()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'title': title,
      'description': description,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'lawyer_name': lawyerName,
      'next_action': nextAction,
      'next_hearing_date': nextHearingDate?.toIso8601String(),
      'attachments': attachments,
    };
  }
}

enum UpdateType {
  hearing,
  document,
  evidence,
  status,
  general,
  deadline,
}
