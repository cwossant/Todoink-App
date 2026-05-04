import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/pinned_tasks_provider.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<bool?>? _notificationsEnabledFuture;

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<void> _handleNotificationsTap(BuildContext context) async {
    final enabledBefore =
        await NotificationService.instance.areNotificationsEnabled();

    if (!context.mounted) return;

    if (enabledBefore == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications already enabled')),
      );
      setState(() {
        _notificationsEnabledFuture =
            NotificationService.instance.areNotificationsEnabled();
      });
      return;
    }

    await NotificationService.instance.ensureNotificationPermission();
    final enabledNow =
        await NotificationService.instance.areNotificationsEnabled();

    if (!context.mounted) return;

    setState(() {
      _notificationsEnabledFuture =
          NotificationService.instance.areNotificationsEnabled();
    });

    if (enabledNow == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications enabled')),
      );
      return;
    }

    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Notifications'),
        content: const Text(
          'Notifications are still disabled. You can enable them in your phone settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (open == true) {
      await openAppSettings();
    }
  }

  Future<bool> _confirm(BuildContext context,
      {required String title,
      required String message,
      required String confirmText,
      bool destructive = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmText,
              style: destructive
                  ? const TextStyle(color: Colors.red)
                  : null,
            ),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Section
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Theme Mode Selector
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'System, Light, or Dark',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox.shrink(),
                    items: ThemeMode.values
                        .map(
                          (mode) => DropdownMenuItem(
                            value: mode,
                            child: Text(_themeLabel(mode)),
                          ),
                        )
                        .toList(),
                    onChanged: (mode) {
                      if (mode == null) return;
                      ref.read(themeModeProvider.notifier).state = mode;
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Notifications Section
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: FutureBuilder<bool?>(
              future: _notificationsEnabledFuture ??=
                  NotificationService.instance.areNotificationsEnabled(),
              builder: (context, snapshot) {
                final enabled = snapshot.data == true;
                final statusText = enabled ? 'Enabled' : 'Disabled';
                final statusColor = enabled
                    ? Theme.of(context).colorScheme.primary
                    : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600]);

                return ListTile(
                  title: const Text('Notifications'),
                  subtitle: Text('Status: $statusText'),
                  trailing: Text(
                    statusText,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                  ),
                  onTap: () => _handleNotificationsTap(context),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Data Section
          Text(
            'Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Clear completed tasks'),
                  subtitle: const Text('Deletes all tasks marked as done'),
                  onTap: () async {
                    final ok = await _confirm(
                      context,
                      title: 'Clear completed tasks',
                      message:
                          'This will permanently delete all completed tasks.',
                      confirmText: 'Clear',
                      destructive: true,
                    );
                    if (!ok) return;

                    final count = await ref
                        .read(taskProvider.notifier)
                        .clearCompletedTasks();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          count == 0
                              ? 'No completed tasks to clear'
                              : 'Cleared $count completed task(s)',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Reset app data'),
                  subtitle: const Text('Deletes all tasks and pinned items'),
                  onTap: () async {
                    final ok = await _confirm(
                      context,
                      title: 'Reset app data',
                      message:
                          'This will permanently delete all tasks and pinned items. This cannot be undone.',
                      confirmText: 'Reset',
                      destructive: true,
                    );
                    if (!ok) return;

                    await ref.read(taskProvider.notifier).resetTasks();
                    await ref.read(pinnedTasksByDayProvider.notifier).clearAll();
                    await HiveService.clearPrefs();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App data reset')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // About Section
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'App Name',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Expanded(
                        child: Text(
                          'To Do List ni teyang',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Version',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '3.2.1',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Developed by',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Mark Dwayne DC',
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
