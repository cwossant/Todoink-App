import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/hive_service.dart';
import '../services/home_widget_service.dart';

enum PinToggleStatus {
  pinned,
  unpinned,
  limitReached,
}

class PinToggleResult {
  final PinToggleStatus status;
  const PinToggleResult(this.status);
}

final pinnedTasksByDayProvider =
    StateNotifierProvider<PinnedTasksByDayNotifier, Map<String, List<String>>>(
  (ref) => PinnedTasksByDayNotifier(),
);

class PinnedTasksByDayNotifier
    extends StateNotifier<Map<String, List<String>>> {
  PinnedTasksByDayNotifier() : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    final loaded = await HiveService.getPinnedTaskIdsByDay();
    state = loaded;
  }

  static String dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<String> pinnedIdsFor(DateTime date) {
    return state[dayKey(date)] ?? const <String>[];
  }

  Future<PinToggleResult> togglePinForDay(DateTime date, String taskId,
      {int maxPinsPerDay = 3}) async {
    final key = dayKey(date);
    final current = List<String>.from(state[key] ?? const <String>[]);

    if (current.contains(taskId)) {
      current.remove(taskId);
      final next = {...state, key: current};
      state = next;
      await HiveService.savePinnedTaskIdsByDay(next);
      await HomeWidgetService.updatePinnedTasksWidget(date: date);
      return const PinToggleResult(PinToggleStatus.unpinned);
    }

    if (current.length >= maxPinsPerDay) {
      return const PinToggleResult(PinToggleStatus.limitReached);
    }

    // Keep most-recent pins at the top.
    current.insert(0, taskId);
    final next = {...state, key: current};
    state = next;
    await HiveService.savePinnedTaskIdsByDay(next);
    await HomeWidgetService.updatePinnedTasksWidget(date: date);
    return const PinToggleResult(PinToggleStatus.pinned);
  }

  Future<void> clearAll() async {
    state = const {};
    await HiveService.savePinnedTaskIdsByDay(state);
    await HomeWidgetService.updatePinnedTasksWidget();
  }
}
