class LawyerDocumentModel {
  final String id;
  final String lawyerId;
  final String filename;
  final String fileUrl;
  final int? fileSize;
  final String? fileType;
  final String? description;
  final String? caseTitle;
  final DateTime createdAt;

  LawyerDocumentModel({
    required this.id,
    required this.lawyerId,
    required this.filename,
    required this.fileUrl,
    this.fileSize,
    this.fileType,
    this.description,
    this.caseTitle,
    required this.createdAt,
  });

  factory LawyerDocumentModel.fromJson(Map<String, dynamic> json) {
    return LawyerDocumentModel(
      id: json['id'] as String,
      lawyerId: json['lawyer_id'] as String,
      filename: json['filename'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: json['file_size'] as int?,
      fileType: json['file_type'] as String?,
      description: json['description'] as String?,
      caseTitle: json['case_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lawyer_id': lawyerId,
    'filename': filename,
    'file_url': fileUrl,
    'file_size': fileSize,
    'file_type': fileType,
    'description': description,
    'case_title': caseTitle,
    'created_at': createdAt.toIso8601String(),
  };

  String get formattedSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
