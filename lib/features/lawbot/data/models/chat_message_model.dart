class ChatMessageModel {
  final String id;
  final String text;
  final bool isBot;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.isBot,
    required this.timestamp,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isBot: json['is_bot'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_bot': isBot,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? text,
    bool? isBot,
    DateTime? timestamp,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      isBot: isBot ?? this.isBot,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
