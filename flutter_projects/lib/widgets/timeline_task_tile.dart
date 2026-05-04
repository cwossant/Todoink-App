import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../models/task_status.dart';
import '../providers/task_provider.dart';

class TimelineTaskTile extends ConsumerWidget {
  final Task task;
  final bool isLast;
  final bool showDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isPinned;
  final VoidCallback? onTogglePin;
  final bool isOverdue;

  const TimelineTaskTile({
    super.key,
    required this.task,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
    this.showDate = false,
    this.isPinned = false,
    this.onTogglePin,
    this.isOverdue = false,
  });

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.schedule;
      case TaskStatus.done:
        return Icons.check_circle;
    }
  }

  TaskStatus _nextStatus(TaskStatus current) {
    const statuses = TaskStatus.values;
    final currentIndex = statuses.indexOf(current);
    return statuses[(currentIndex + 1) % statuses.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _getStatusColor(task.status);

    final timeText = task.time == null
        ? null
        : DateFormat('h:mm a').format(
            DateTime(2024, 1, 1, task.time!.hour, task.time!.minute),
          );

    final subtitle = showDate
        ? DateFormat('MMM dd, yyyy').format(task.date)
        : (task.description.isNotEmpty
            ? task.description
            : task.status.displayName);

    final titleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w700,
          decoration: task.status == TaskStatus.done
              ? TextDecoration.lineThrough
              : null,
          color: task.status == TaskStatus.done
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]
                  : Colors.grey)
              : null,
        );

    return SizedBox(
      height: 86,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const circleSize = 32.0;
                const connectorGap = 6.0;
                final circleTop = (constraints.maxHeight - circleSize) / 2;

                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isLast)
                      Positioned(
                        top: circleTop + circleSize + connectorGap,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _DottedConnector(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                    Positioned(
                      top: circleTop,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          final next = _nextStatus(task.status);
                          ref
                              .read(taskProvider.notifier)
                              .updateTaskStatus(task.id, next);
                        },
                        child: Center(
                          child: Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getStatusIcon(task.status),
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onEdit,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (timeText != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          timeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isOverdue
                                        ? colorScheme.error
                                        : colorScheme.primary,
                                  ),
                        ),
                      ],
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'pin') {
                            onTogglePin?.call();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          if (onTogglePin != null)
                            PopupMenuItem(
                              value: 'pin',
                              child: Row(
                                children: [
                                  Icon(
                                    isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isPinned ? 'Unpin' : 'Pin'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedConnector extends StatelessWidget {
  final Color color;

  const _DottedConnector({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dotHeight = 3.0;
        const gap = 4.0;
        final full = dotHeight + gap;
        final count = (constraints.maxHeight / full).floor();
        final dotCount = count < 1 ? 1 : count;

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dotCount, (_) {
            return Container(
              width: 2,
              height: dotHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}
