import 'package:flutter/material.dart';
import 'task_status.dart';

/// Represents a single task in the to-do list.
class Task {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay? time;
  final TaskStatus status;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.time,
    this.status = TaskStatus.notStarted,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this task with optional field overrides.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    TaskStatus? status,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          date == other.date &&
          time == other.time &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      date.hashCode ^
      time.hashCode ^
      status.hashCode;
}
