import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import '../providers/task_provider.dart';
import '../providers/filter_sort_provider.dart';
import '../providers/pinned_tasks_provider.dart';
import '../widgets/filter_sort_sheet.dart';
import '../widgets/timeline_task_tile.dart';
import '../services/notification_service.dart';
import 'add_edit_task_screen.dart';
import 'all_tasks_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  final String userName = 'Teya';

  Future<bool?>? _notificationsEnabledFuture;

  @override
  void initState() {
    super.initState();
    _notificationsEnabledFuture =
        NotificationService.instance.areNotificationsEnabled();
  }

  void _showAddTaskScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditTaskScreen(),
      ),
    );
  }

  void _showEditTaskScreen(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditTaskScreen(task: task),
      ),
    );
  }

  void _deleteTask(String taskId) {
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

  void _showFilterSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const FilterSortSheet(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  String _greetingForTime(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Evening';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAllTasksScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AllTasksScreen(),
      ),
    );
  }

  Future<void> _setDailyReminder() async {
    final enabledBefore =
        await NotificationService.instance.areNotificationsEnabled();
    final enabledAfter =
        await NotificationService.instance.ensureNotificationPermission();

    if (mounted) {
      setState(() {
        _notificationsEnabledFuture =
            NotificationService.instance.areNotificationsEnabled();
      });
    }

    if (!mounted) return;
    final message = enabledAfter
        ? (enabledBefore == true
            ? 'Notifications already enabled'
            : 'Notifications enabled')
        : 'Notifications permission not granted';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isOverdue(Task task, DateTime now, DateTime todayStart) {
    if (task.status == TaskStatus.done) return false;

    final taskDay = DateTime(task.date.year, task.date.month, task.date.day);
    if (taskDay.isBefore(todayStart)) return true;

    if (_isSameDate(taskDay, todayStart) && task.time != null) {
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

  Future<void> _togglePin(Task task) async {
    final result = await ref
        .read(pinnedTasksByDayProvider.notifier)
        .togglePinForDay(selectedDate, task.id);

    if (!mounted) return;
    if (result.status == PinToggleStatus.limitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can pin up to 3 tasks per day')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = ref.watch(filteredAndSortedTasksProvider);
    final pinnedByDay = ref.watch(pinnedTasksByDayProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final headerDateFormat = DateFormat('EEEE, dd MMMM, yyyy');
    final dayLabelFormat = DateFormat('EEE');
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);
    final isSelectedToday = _isSameDate(selectedDate, baseDate);

    // Precompute which of the next 7 days have tasks (for the dot indicator)
    // to avoid scanning the full list 7 times.
    final weekStart = baseDate;
    final weekEndExclusive = baseDate.add(const Duration(days: 7));
    final hasTasksDayKeys = <String>{};
    for (final task in filteredTasks) {
      final taskDay = DateTime(task.date.year, task.date.month, task.date.day);
      if (taskDay.isBefore(weekStart) || !taskDay.isBefore(weekEndExclusive)) {
        continue;
      }
      hasTasksDayKeys.add(PinnedTasksByDayNotifier.dayKey(taskDay));
    }

    // Get tasks for the selected date (single pass)
    final tasksForDate = <Task>[];
    for (final task in filteredTasks) {
      if (_isSameDate(task.date, selectedDate)) {
        tasksForDate.add(task);
      }
    }

    final doneCountForDate =
      tasksForDate.where((t) => t.status == TaskStatus.done).length;

    final overdueCount = filteredTasks
      .where((t) => _isOverdue(t, now, baseDate))
      .length;

    final pinnedIdsForSelectedDay =
      pinnedByDay[PinnedTasksByDayNotifier.dayKey(selectedDate)] ??
        const <String>[];

    final tasksById = <String, Task>{
      for (final task in tasksForDate) task.id: task,
    };

    final pinnedTasksForDate = <Task>[];
    for (final id in pinnedIdsForSelectedDay) {
      final task = tasksById[id];
      if (task != null) pinnedTasksForDate.add(task);
    }
    final unpinnedTasksForDate = tasksForDate
      .where((t) => !pinnedIdsForSelectedDay.contains(t.id))
      .toList();
    final displayTasksForDate = [...pinnedTasksForDate, ...unpinnedTasksForDate];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greetingForTime(now)}, $userName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            headerDateFormat.format(now),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Date selector (circular)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 86,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final date = baseDate.add(Duration(days: index));
                    final isSelected = _isSameDate(date, selectedDate);
                    final hasTasksForDay =
                        hasTasksDayKeys.contains(PinnedTasksByDayNotifier.dayKey(date));

                    final dayLabelStyle = Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        );

                    final dayNumberStyle =
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                            );

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          dayLabelFormat.format(date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: dayLabelStyle,
                        ),
                        const SizedBox(height: 10),
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              setState(() {
                                selectedDate = date;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.outlineVariant,
                                  width: isSelected ? 0 : 1,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '${date.day}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: dayNumberStyle,
                                  ),
                                  if (hasTasksForDay)
                                    Positioned(
                                      bottom: 8,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Set reminder card
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set the reminder',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Never miss your routine! Set a reminder to stay on track.',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 36,
                              child: FutureBuilder<bool?>(
                                future: _notificationsEnabledFuture ??=
                                    NotificationService.instance
                                        .areNotificationsEnabled(),
                                builder: (context, snapshot) {
                                  final enabled = snapshot.data == true;
                                  return ElevatedButton(
                                    onPressed: enabled ? null : _setDailyReminder,
                                    child: Text(
                                      enabled ? 'Notifications enabled' : 'Set Now',
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: colorScheme.primary,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Daily routine header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tasks',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (isSelectedToday && overdueCount > 0)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AllTasksScreen(showOverdueOnly: true),
                                ),
                              );
                            },
                            child: Text('Overdue ($overdueCount)'),
                          ),
                        TextButton(
                          onPressed: _showAllTasksScreen,
                          child: const Text('See all'),
                        ),
                        IconButton(
                          onPressed: _showFilterSortSheet,
                          tooltip: 'Filter & Sort',
                          icon: const Icon(Icons.tune),
                        ),
                      ],
                    ),
                    Text(
                      'Done $doneCountForDate / Total ${tasksForDate.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            // Task list
            if (tasksForDate.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
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
                        'No tasks for this date',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = displayTasksForDate[index];
                    final isPinned = pinnedIdsForSelectedDay.contains(task.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TimelineTaskTile(
                        task: task,
                        isLast: index == displayTasksForDate.length - 1,
                        onEdit: () => _showEditTaskScreen(task),
                        onDelete: () => _deleteTask(task.id),
                        isPinned: isPinned,
                        onTogglePin: () => _togglePin(task),
                      ),
                    );
                  },
                  childCount: displayTasksForDate.length,
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskScreen,
        tooltip: 'Add new task',
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
