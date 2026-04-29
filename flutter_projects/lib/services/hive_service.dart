import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/task_status.dart';

/// Service for managing local data persistence using Hive
class HiveService {
  static const String tasksBoxName = 'tasks';

  /// Initialize Hive and open the tasks box
  static Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(tasksBoxName);
  }

  /// Get all saved tasks
  static List<Task> getAllTasks() {
    try {
      final box = Hive.box<Map>(tasksBoxName);
      final tasks = <Task>[];

      for (final value in box.values) {
        final task = _mapToTask(value.cast<String, dynamic>());
        if (task != null) {
          tasks.add(task);
        }
      }

      return tasks;
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  /// Save a single task
  static Future<void> saveTask(Task task) async {
    try {
      final box = Hive.box<Map>(tasksBoxName);
      final taskMap = _taskToMap(task);
      await box.put(task.id, taskMap);
    } catch (e) {
      print('Error saving task: $e');
    }
  }

  /// Save all tasks (batch operation)
  static Future<void> saveTasks(List<Task> tasks) async {
    try {
      final box = Hive.box<Map>(tasksBoxName);
      final tasksMap = <String, Map<String, dynamic>>{};

      for (final task in tasks) {
        tasksMap[task.id] = _taskToMap(task).cast<String, dynamic>();
      }

      await box.putAll(tasksMap);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  /// Delete a specific task
  static Future<void> deleteTask(String taskId) async {
    try {
      final box = Hive.box<Map>(tasksBoxName);
      await box.delete(taskId);
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  /// Clear all tasks
  static Future<void> clearAllTasks() async {
    try {
      final box = Hive.box<Map>(tasksBoxName);
      await box.clear();
    } catch (e) {
      print('Error clearing tasks: $e');
    }
  }

  /// Convert Task to Map for storage
  static Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'date': task.date.toIso8601String(),
      'time': task.time != null ? '${task.time!.hour}:${task.time!.minute}' : null,
      'status': task.status.toString(),
      'createdAt': task.createdAt.toIso8601String(),
    };
  }

  /// Convert Map to Task
  static Task? _mapToTask(Map<String, dynamic> map) {
    try {
      TimeOfDay? time;
      if (map['time'] != null) {
        final timeParts = (map['time'] as String).split(':');
        time = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      }

      final statusString = map['status'] as String;
      TaskStatus status;
      if (statusString.contains('done')) {
        status = TaskStatus.done;
      } else if (statusString.contains('inProgress')) {
        status = TaskStatus.inProgress;
      } else {
        status = TaskStatus.notStarted;
      }

      return Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
        time: time,
        status: status,
        createdAt: DateTime.parse(map['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      print('Error converting map to task: $e');
      return null;
    }
  }
}
