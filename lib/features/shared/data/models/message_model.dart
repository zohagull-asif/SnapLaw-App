class MessageModel {
  final String id;
  final String caseId;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String senderRole; // 'client' or 'lawyer'
  final String content;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.caseId,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      senderName: json['sender_name'] as String,
      senderRole: json['sender_role'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  MessageModel copyWith({
    String? id,
    String? caseId,
    String? senderId,
    String? receiverId,
    String? senderName,
    String? senderRole,
    String? content,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
