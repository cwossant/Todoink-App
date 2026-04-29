import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

/// Provider for managing the list of all tasks
final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});

class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]) {
    _loadTasksFromStorage();
  }

  /// Load tasks from Hive storage
  Future<void> _loadTasksFromStorage() async {
    try {
      final savedTasks = HiveService.getAllTasks();
      state = savedTasks;

      // Best-effort rescheduling of reminders for upcoming tasks.
      for (final task in savedTasks) {
        if (task.status == TaskStatus.done) {
          await NotificationService.instance.cancelTaskReminder(task.id);
        } else {
          await NotificationService.instance.scheduleTaskReminder(task);
        }
      }
    } catch (e) {
      print('Error loading tasks from storage: $e');
    }
  }

  /// Add a new task with optional time
  Future<void> addTask(String title, String description, DateTime date,
      {TimeOfDay? time}) async {
    const uuid = Uuid();
    final newTask = Task(
      id: uuid.v4(),
      title: title,
      description: description,
      date: date,
      time: time,
      status: TaskStatus.notStarted,
    );
    state = [...state, newTask];

    // Save to Hive
    await HiveService.saveTask(newTask);

    // Schedule reminder (if any)
    await NotificationService.instance.scheduleTaskReminder(newTask);
  }

  /// Update an existing task
  Future<void> updateTask(Task updatedTask) async {
    state = [
      for (final task in state)
        if (task.id == updatedTask.id) updatedTask else task,
    ];

    // Save to Hive
    await HiveService.saveTask(updatedTask);

    // Update reminder
    if (updatedTask.status == TaskStatus.done || updatedTask.time == null) {
      await NotificationService.instance.cancelTaskReminder(updatedTask.id);
    } else {
      await NotificationService.instance.scheduleTaskReminder(updatedTask);
    }
  }

  /// Delete a task by ID
  Future<void> deleteTask(String taskId) async {
    state = state.where((task) => task.id != taskId).toList();

    // Delete from Hive
    await HiveService.deleteTask(taskId);

    // Cancel reminder
    await NotificationService.instance.cancelTaskReminder(taskId);
  }

  /// Update task status
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    state = [
      for (final task in state)
        if (task.id == taskId) task.copyWith(status: newStatus) else task,
    ];

    // Find and save the updated task
    final updatedTask = state.firstWhere((task) => task.id == taskId);
    await HiveService.saveTask(updatedTask);

    // Update reminder
    if (newStatus == TaskStatus.done || updatedTask.time == null) {
      await NotificationService.instance.cancelTaskReminder(taskId);
    } else {
      await NotificationService.instance.scheduleTaskReminder(updatedTask);
    }
  }

  /// Get all tasks for a specific date
  List<Task> getTasksForDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return state
        .where((task) =>
            task.date.year == targetDate.year &&
            task.date.month == targetDate.month &&
            task.date.day == targetDate.day)
        .toList();
  }
}
