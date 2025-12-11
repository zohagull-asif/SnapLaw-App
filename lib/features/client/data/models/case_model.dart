enum CaseStatus { open, inProgress, closed, pending }

enum CaseType {
  criminal,
  civil,
  family,
  corporate,
  immigration,
  realEstate,
  intellectualProperty,
  labor,
  tax,
  other
}

class CaseModel {
  final String id;
  final String clientId;
  final String? lawyerId;
  final String title;
  final String description;
  final CaseType type;
  final CaseStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? closedAt;
  final List<String>? documentUrls;
  final String? notes;
  final bool isUrgent;

  CaseModel({
    required this.id,
    required this.clientId,
    this.lawyerId,
    required this.title,
    required this.description,
    required this.type,
    this.status = CaseStatus.open,
    required this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.documentUrls,
    this.notes,
    this.isUrgent = false,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      lawyerId: json['lawyer_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      type: CaseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CaseType.other,
      ),
      status: CaseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CaseStatus.open,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
      documentUrls: json['document_urls'] != null
          ? List<String>.from(json['document_urls'] as List)
          : null,
      notes: json['notes'] as String?,
      isUrgent: json['is_urgent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'lawyer_id': lawyerId,
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'document_urls': documentUrls,
      'notes': notes,
      'is_urgent': isUrgent,
    };
  }

  CaseModel copyWith({
    String? id,
    String? clientId,
    String? lawyerId,
    String? title,
    String? description,
    CaseType? type,
    CaseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    List<String>? documentUrls,
    String? notes,
    bool? isUrgent,
  }) {
    return CaseModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      lawyerId: lawyerId ?? this.lawyerId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      documentUrls: documentUrls ?? this.documentUrls,
      notes: notes ?? this.notes,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  String get typeDisplayName {
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

  String get statusDisplayName {
    switch (status) {
      case CaseStatus.open:
        return 'Open';
      case CaseStatus.inProgress:
        return 'In Progress';
      case CaseStatus.closed:
        return 'Closed';
      case CaseStatus.pending:
        return 'Pending';
    }
  }
}
