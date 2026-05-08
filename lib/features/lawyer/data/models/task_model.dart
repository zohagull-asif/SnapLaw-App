import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low: return 'Low';
      case TaskPriority.medium: return 'Medium';
      case TaskPriority.high: return 'High';
      case TaskPriority.urgent: return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low: return const Color(0xFF00C896);
      case TaskPriority.medium: return const Color(0xFFF4A324);
      case TaskPriority.high: return const Color(0xFFF4A324);
      case TaskPriority.urgent: return const Color(0xFFFF4757);
    }
  }

  static TaskPriority fromString(String value) {
    switch (value) {
      case 'low': return TaskPriority.low;
      case 'high': return TaskPriority.high;
      case 'urgent': return TaskPriority.urgent;
      default: return TaskPriority.medium;
    }
  }
}

class TaskModel {
  final String id;
  final String lawyerId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final bool isCompleted;
  final String? caseTitle;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.lawyerId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.isCompleted = false,
    this.caseTitle,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      lawyerId: json['lawyer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriorityX.fromString(json['priority'] as String? ?? 'medium'),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      caseTitle: json['case_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lawyer_id': lawyerId,
    'title': title,
    'description': description,
    'priority': priority.name,
    'due_date': dueDate?.toIso8601String(),
    'is_completed': isCompleted,
    'case_title': caseTitle,
    'created_at': createdAt.toIso8601String(),
  };

  TaskModel copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? dueDate,
    bool? isCompleted,
    String? caseTitle,
  }) {
    return TaskModel(
      id: id,
      lawyerId: lawyerId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      caseTitle: caseTitle ?? this.caseTitle,
      createdAt: createdAt,
    );
  }
}
