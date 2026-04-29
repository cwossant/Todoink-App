import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import 'task_provider.dart';

enum SortOption {
  date('Sort by Date'),
  alphabetical('Sort Alphabetically'),
  status('Sort by Status');

  final String displayName;
  const SortOption(this.displayName);
}

/// Provider for the selected filter status (null means show all)
final filterStatusProvider = StateProvider<TaskStatus?>((ref) => null);

/// Provider for the selected sort option
final sortOptionProvider = StateProvider<SortOption>((ref) => SortOption.date);

/// Computed provider that returns filtered and sorted tasks
final filteredAndSortedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  final filterStatus = ref.watch(filterStatusProvider);
  final sortOption = ref.watch(sortOptionProvider);

  // Apply filter
  List<Task> filtered = tasks;
  if (filterStatus != null) {
    filtered = tasks.where((task) => task.status == filterStatus).toList();
  }

  // Apply sort
  List<Task> sorted = [...filtered];
  switch (sortOption) {
    case SortOption.date:
      sorted.sort((a, b) => a.date.compareTo(b.date));
      break;
    case SortOption.alphabetical:
      sorted.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SortOption.status:
      sorted.sort((a, b) => a.status.index.compareTo(b.status.index));
      break;
  }

  return sorted;
});
