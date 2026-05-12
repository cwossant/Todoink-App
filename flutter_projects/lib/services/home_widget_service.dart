import 'package:home_widget/home_widget.dart';

import '../models/task.dart';
import 'hive_service.dart';

class HomeWidgetService {
  static const String _androidWidgetProvider = 'TodoinkPinnedWidgetProvider';

  static const String _keyPinned1 = 'pinned_1';
  static const String _keyPinned2 = 'pinned_2';
  static const String _keyPinned3 = 'pinned_3';

  static String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<void> updatePinnedTasksWidget({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();

    // Best-effort: this runs only when the app is alive.
    final pinnedByDay = await HiveService.getPinnedTaskIdsByDay();
    final pinnedIds = pinnedByDay[_dayKey(targetDate)] ?? const <String>[];

    final tasks = HiveService.getAllTasks();
    final tasksById = <String, Task>{for (final t in tasks) t.id: t};

    final titles = <String>[];
    for (final id in pinnedIds) {
      final task = tasksById[id];
      if (task == null) continue;
      if (task.title.trim().isEmpty) continue;
      titles.add(task.title.trim());
      if (titles.length >= 3) break;
    }

    await HomeWidget.saveWidgetData<String>(_keyPinned1, titles.isNotEmpty ? titles[0] : '');
    await HomeWidget.saveWidgetData<String>(_keyPinned2, titles.length > 1 ? titles[1] : '');
    await HomeWidget.saveWidgetData<String>(_keyPinned3, titles.length > 2 ? titles[2] : '');

    await HomeWidget.updateWidget(androidName: _androidWidgetProvider);
  }
}
