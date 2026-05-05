import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/task_status.dart';

/// Service for managing local data persistence using Hive
class HiveService {
  static const String tasksBoxName = 'tasks';
  static const String prefsBoxName = 'prefs';

  static const String _pinnedByDayKey = 'pinnedByDay';
  static const String _filterStatusKey = 'filterStatus';
  static const String _sortOptionKey = 'sortOption';
  static const String _themeModeKey = 'themeMode';

  /// Initialize Hive and open the tasks box
  static Future<void> initHive() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(tasksBoxName);
    await Hive.openBox(prefsBoxName);
  }

  static Future<void> ensurePrefsBoxOpen() async {
    try {
      if (Hive.isBoxOpen(prefsBoxName)) return;
      await Hive.openBox(prefsBoxName);
    } catch (e) {
      print('Error opening prefs box: $e');
    }
  }

  /// Returns a map of dayKey (yyyy-MM-dd) -> pinned task IDs.
  static Future<Map<String, List<String>>> getPinnedTaskIdsByDay() async {
    try {
      await ensurePrefsBoxOpen();
      final box = Hive.box(prefsBoxName);
      final raw = box.get(_pinnedByDayKey);
      if (raw is! Map) return {};

      final result = <String, List<String>>{};
      raw.forEach((key, value) {
        if (key is! String) return;
        if (value is List) {
          result[key] = value.whereType<String>().toList();
        }
      });
      return result;
    } catch (e) {
      print('Error loading pinned tasks: $e');
      return {};
    }
  }

  static Future<void> savePinnedTaskIdsByDay(
      Map<String, List<String>> pinnedByDay) async {
    try {
      await ensurePrefsBoxOpen();
      final box = Hive.box(prefsBoxName);
      final storable = <String, dynamic>{
        for (final entry in pinnedByDay.entries)
          entry.key: entry.value.toList(growable: false),
      };
      await box.put(_pinnedByDayKey, storable);
    } catch (e) {
      print('Error saving pinned tasks: $e');
    }
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

  static Future<void> clearPrefs() async {
    try {
      await ensurePrefsBoxOpen();
      final box = Hive.box(prefsBoxName);
      await box.clear();
    } catch (e) {
      print('Error clearing prefs: $e');
    }
  }

  static Future<void> clearAllData() async {
    await clearAllTasks();
    await clearPrefs();
  }

  static String? getSavedFilterStatus() {
    try {
      if (!Hive.isBoxOpen(prefsBoxName)) return null;
      final box = Hive.box(prefsBoxName);
      final value = box.get(_filterStatusKey);
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  static String? getSavedSortOption() {
    try {
      if (!Hive.isBoxOpen(prefsBoxName)) return null;
      final box = Hive.box(prefsBoxName);
      final value = box.get(_sortOptionKey);
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveFilterStatus(String? statusName) async {
    try {
      await ensurePrefsBoxOpen();
      final box = Hive.box(prefsBoxName);
      await box.put(_filterStatusKey, statusName);
    } catch (e) {
      print('Error saving filter status: $e');
    }
  }

  static Future<void> saveSortOption(String sortName) async {
    try {
      await ensurePrefsBoxOpen();
      final box = Hive.box(prefsBoxName);
      await box.put(_sortOptionKey, sortName);
    } catch (e) {
      print('Error saving sort option: $e');
    }
  }

  static ThemeMode? getSavedThemeMode() {
    try {
      if (!Hive.isBoxOpen(prefsBoxName)) return null;
      final box = Hive.box(prefsBoxName);
      final value = box.get(_themeModeKey);
      if (value is! String) return null;

      switch (value) {
        case 'system':
          return ThemeMode.system;
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      await ensurePrefsBoxOpen();
      final box = Hive.box(prefsBoxName);

      final value = switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

      await box.put(_themeModeKey, value);
    } catch (e) {
      print('Error saving theme mode: $e');
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
