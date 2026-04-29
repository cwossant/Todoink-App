import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/filter_sort_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/filter_sort_sheet.dart';
import '../widgets/timeline_task_tile.dart';
import 'add_edit_task_screen.dart';

class AllTasksScreen extends ConsumerWidget {
  const AllTasksScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          IconButton(
            onPressed: () => _showFilterSortSheet(context),
            tooltip: 'Filter & Sort',
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: allTasks.isEmpty
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
                    'No tasks yet',
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
              itemCount: allTasks.length,
              itemBuilder: (context, index) {
                final task = allTasks[index];
                return TimelineTaskTile(
                  task: task,
                  isLast: index == allTasks.length - 1,
                  showDate: true,
                  onEdit: () => _showEditTaskScreen(context, task),
                  onDelete: () => _deleteTask(context, ref, task.id),
                );
              },
            ),
    );
  }
}
