import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../models/task_status.dart';
import '../providers/filter_sort_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/filter_sort_sheet.dart';
import '../widgets/timeline_task_tile.dart';
import 'add_edit_task_screen.dart';

class AllTasksScreen extends ConsumerWidget {
  final bool showOverdueOnly;

  const AllTasksScreen({super.key, this.showOverdueOnly = false});

  bool _isOverdue(Task task, DateTime now, DateTime todayStart) {
    if (task.status == TaskStatus.done) return false;

    final taskDay = DateTime(task.date.year, task.date.month, task.date.day);
    if (taskDay.isBefore(todayStart)) return true;

    if (taskDay.year == todayStart.year &&
        taskDay.month == todayStart.month &&
        taskDay.day == todayStart.day &&
        task.time != null) {
      final due = DateTime(
        now.year,
        now.month,
        now.day,
        task.time!.hour,
        task.time!.minute,
      );
      return due.isBefore(now);
    }

    return false;
  }

  void _showEditTaskScreen(BuildContext context, Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(task: task),
      ),
    );
  }

  void _deleteTask(BuildContext context, WidgetRef ref, String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(taskProvider.notifier).deleteTask(taskId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const FilterSortSheet(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasks = ref.watch(filteredAndSortedTasksProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final headerDateFormat = DateFormat('EEE, MMM d');
    final displayTasks = showOverdueOnly
        ? allTasks.where((t) => _isOverdue(t, now, todayStart)).toList()
        : allTasks;

    // Precompute overdue tasks once, so the builder doesn't recompute for each row.
    final overdueIds = <String>{};
    if (showOverdueOnly) {
      for (final t in displayTasks) {
        overdueIds.add(t.id);
      }
    } else {
      for (final t in displayTasks) {
        if (_isOverdue(t, now, todayStart)) overdueIds.add(t.id);
      }
    }

    final doneCount = displayTasks.where((t) => t.status == TaskStatus.done).length;
    final shouldGroupByDate = !showOverdueOnly && sortOption == SortOption.date;

    final listItems = <Object>[];
    if (shouldGroupByDate) {
      DateTime? lastDay;
      for (final task in displayTasks) {
        final day = DateTime(task.date.year, task.date.month, task.date.day);
        final isNewDay = lastDay == null ||
            day.year != lastDay.year ||
            day.month != lastDay.month ||
            day.day != lastDay.day;
        if (isNewDay) {
          // Inline label computation using a reused formatter.
          if (day.year == todayStart.year &&
              day.month == todayStart.month &&
              day.day == todayStart.day) {
            listItems.add('Today');
          } else {
            final tomorrow = todayStart.add(const Duration(days: 1));
            if (day.year == tomorrow.year &&
                day.month == tomorrow.month &&
                day.day == tomorrow.day) {
              listItems.add('Tomorrow');
            } else {
              listItems.add(headerDateFormat.format(day));
            }
          }
          lastDay = day;
        }
        listItems.add(task);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(showOverdueOnly ? 'Overdue Tasks' : 'All Tasks'),
        actions: [
          IconButton(
            onPressed: () => _showFilterSortSheet(context),
            tooltip: 'Filter & Sort',
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: displayTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]
                        : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    showOverdueOnly ? 'No overdue tasks' : 'No tasks yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: (shouldGroupByDate ? listItems.length : displayTasks.length) + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final text = showOverdueOnly
                      ? 'Overdue ${displayTasks.length}'
                      : 'Done $doneCount / Total ${displayTasks.length}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }

                if (shouldGroupByDate) {
                  final item = listItems[index - 1];
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Text(
                        item,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    );
                  }

                  final task = item as Task;
                  final overdue = overdueIds.contains(task.id);
                  final isLastTask = index - 1 == listItems.length - 1;
                  return TimelineTaskTile(
                    task: task,
                    isLast: isLastTask,
                    showDate: true,
                    isOverdue: overdue,
                    onEdit: () => _showEditTaskScreen(context, task),
                    onDelete: () => _deleteTask(context, ref, task.id),
                  );
                }

                final task = displayTasks[index - 1];
                final overdue = overdueIds.contains(task.id);
                return TimelineTaskTile(
                  task: task,
                  isLast: index - 1 == displayTasks.length - 1,
                  showDate: true,
                  isOverdue: overdue,
                  onEdit: () => _showEditTaskScreen(context, task),
                  onDelete: () => _deleteTask(context, ref, task.id),
                );
              },
            ),
    );
  }
}
