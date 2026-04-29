# Architecture & Integration Guide

## How All Pieces Fit Together

### 1. **Data Flow Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                      MyApp (main.dart)                      │
│  (Reads theme mode & primary color from Riverpod)          │
└────────────────────────────────┬────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
            ┌───────▼────────┐      ┌────────▼──────────┐
            │ HomeScreen     │      │ SettingsScreen    │
            │ (Task List)    │      │ (Theme Settings)  │
            └───────┬────────┘      └────────┬──────────┘
                    │                        │
            Watches: taskProvider    Modifies:
            filterStatusProvider     themeModeProvider
            sortOptionProvider       customPrimaryColorProvider
                    │                        │
        ┌───────────┼───────────┬───────────┴──────┐
        │           │           │                  │
        │     ┌─────▼─────┐    │          ┌───────▼──────┐
        │     │ taskList  │    │          │ theme colors │
        │     │ (computed)│    │          │              │
        │     └─────▲─────┘    │          └──────────────┘
        │           │          │
        │  ┌────────┴──────┐   │
        │  │ taskProvider  │   │
        │  │ (StateNotif)  │   │
        │  └────────▲──────┘   │
        │           │          │
        └───────────┼──────────┘
                    │
        All screens share state
        via Riverpod providers
```

### 2. **Data Flow Example: Adding a Task**

```
HomeScreen
    │
    └─► _showAddTaskScreen()
        │
        └─► AddEditTaskScreen
            │
            ├─ User enters title, description, date
            │
            └─► Taps "Add Task"
                │
                └─► ref.read(taskProvider.notifier).addTask(...)
                    │
                    └─► TaskNotifier.addTask()
                        │
                        ├─ Creates new Task with UUID
                        │
                        └─ Updates state: state = [...state, newTask]
                            │
                            └─► HomeScreen rebuilds automatically
                                (watched taskProvider)
```

### 3. **Data Flow Example: Filtering Tasks**

```
HomeScreen (Filter Button ⓘ)
    │
    └─► _showFilterSortSheet()
        │
        └─► FilterSortSheet
            │
            ├─ User selects filter: "In Progress"
            │
            └─► ref.read(filterStatusProvider.notifier).state = TaskStatus.inProgress
                │
                └─► filterStatusProvider updated
                    │
                    └─► filteredAndSortedTasksProvider recalculates
                        (watches filterStatusProvider & taskProvider)
                        │
                        └─► Returns only "In Progress" tasks
                            │
                            └─► HomeScreen rebuilds (watches filteredAndSortedTasksProvider)
```

### 4. **Data Flow Example: Theme Change**

```
SettingsScreen
    │
    └─► User toggles Dark Mode switch
        │
        └─► ref.read(themeModeProvider.notifier).state = ThemeMode.dark
            │
            └─► themeModeProvider updated
                │
                └─► MyApp rebuilds
                    (watched themeModeProvider)
                    │
                    └─► Applies AppTheme.darkTheme(primaryColor)
                        │
                        └─► Entire app re-themed instantly
```

---

## File Relationships

### What Depends on What

```
main.dart
├─ Imports: theme_provider, home_screen
└─ Uses: themeModeProvider, customPrimaryColorProvider

home_screen.dart
├─ Imports: task_provider, filter_sort_provider, task_card
├─ Imports: add_edit_task_screen, settings_screen
├─ Imports: filter_sort_sheet
└─ Uses: taskProvider, filteredAndSortedTasksProvider

add_edit_task_screen.dart
├─ Imports: task_provider, task (model)
└─ Uses: taskProvider.notifier

settings_screen.dart
├─ Imports: theme_provider
└─ Uses: themeModeProvider, customPrimaryColorProvider

task_card.dart
├─ Imports: task_provider, task (model)
└─ Uses: taskProvider.notifier (for status updates)

filter_sort_sheet.dart
├─ Imports: filter_sort_provider
└─ Uses: filterStatusProvider, sortOptionProvider

task_provider.dart
├─ Imports: task (model), task_status
└─ Logic: Manages all task CRUD operations

filter_sort_provider.dart
├─ Imports: task_provider, task_status
└─ Logic: Filters and sorts tasks from taskProvider

theme_provider.dart
└─ Simple state holders: themeMode, primaryColor

task.dart & task_status.dart
└─ Pure data models (no dependencies)
```

---

## State Management Flow

### When User Adds a Task

```
1. User taps Floating Action Button
   └─ HomeScreen._showAddTaskScreen()

2. AddEditTaskScreen opens
   └─ State: Empty TextControllers

3. User enters data and taps "Add Task"
   └─ ref.read(taskProvider.notifier).addTask(title, desc, date)

4. TaskNotifier receives the call
   └─ Creates Task with uuid.v4()
   └─ Updates state: state = [...state, newTask]

5. taskProvider listeners notified
   └─ HomeScreen rebuilds (watched taskProvider)
   └─ filteredAndSortedTasksProvider recomputes
   
6. HomeScreen UI updates with new task
   └─ New task appears in list
```

### When User Changes Filter

```
1. User taps Filter button
   └─ FilterSortSheet shows

2. User selects "In Progress" filter
   └─ ref.read(filterStatusProvider.notifier).state = TaskStatus.inProgress

3. filterStatusProvider notified
   └─ filteredAndSortedTasksProvider recalculates
      (because it watches filterStatusProvider)

4. HomeScreen rebuilds
   └─ Only displays "In Progress" tasks
   └─ Other status tasks hidden

5. User can switch filter back to "All"
   └─ ref.read(filterStatusProvider.notifier).state = null
   └─ All tasks reappear
```

### When User Toggles Dark Mode

```
1. User opens Settings
   └─ SettingsScreen loads

2. User taps Dark Mode switch
   └─ ref.read(themeModeProvider.notifier).state = ThemeMode.dark

3. themeModeProvider notified
   └─ MyApp rebuilds (watched themeModeProvider)

4. MyApp.build() re-executes
   └─ Reads: final themeMode = ref.watch(themeModeProvider);
   └─ Applies: darkTheme: AppTheme.darkTheme(primaryColor)
   └─ ThemeData applied to entire MaterialApp

5. Entire app instantly switches to dark colors
   └─ All screens update without navigation changes
```

---

## Key Riverpod Concepts

### 1. Provider Composition

`filteredAndSortedTasksProvider` depends on multiple sources:

```dart
final filteredAndSortedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);           // ⬅ Watch source 1
  final filterStatus = ref.watch(filterStatusProvider);  // ⬅ Watch source 2
  final sortOption = ref.watch(sortOptionProvider);     // ⬅ Watch source 3
  
  // Compute derived state
  List<Task> filtered = ...
  List<Task> sorted = ...
  return sorted;
});
```

**Result**: Any change to taskProvider, filterStatusProvider, or sortOptionProvider triggers this to recompute.

### 2. StateNotifier Pattern

```dart
class TaskNotifier extends StateNotifier<List<Task>> {
  TaskNotifier() : super([]);  // Initial state = empty list
  
  void addTask(...) {
    state = [...state, newTask];  // Update state
    // All listeners notified automatically
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});
```

**Usage**:
- Read: `ref.read(taskProvider)` → gets List<Task>
- Watch: `ref.watch(taskProvider)` → rebuilds on change
- Mutate: `ref.read(taskProvider.notifier).addTask(...)` → calls TaskNotifier method

### 3. Simple StateProvider

```dart
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;  // Initial value
});

// Usage:
ref.watch(themeModeProvider);  // Get current mode
ref.read(themeModeProvider.notifier).state = ThemeMode.dark;  // Set mode
```

---

## Real-World Scenario

### Scenario: User workflow to complete a task

**Step 1: Open App**
- MyApp loads
- Watches: themeModeProvider, customPrimaryColorProvider
- Applies theme to MaterialApp
- Shows HomeScreen

**Step 2: View Today's Tasks**
- HomeScreen loads
- Watches: taskProvider (all tasks)
- Watches: filteredAndSortedTasksProvider (filtered tasks)
- Displays tasks for today's date
- Initial filter: null (show all), sort: by date

**Step 3: Filter by Status**
- User taps Filter button
- FilterSortSheet opens
- User selects "Not Started"
- filterStatusProvider.state = TaskStatus.notStarted
- filteredAndSortedTasksProvider recalculates
- Only "Not Started" tasks shown

**Step 4: Click Task to Edit**
- User taps menu on a task
- Selects "Edit"
- AddEditTaskScreen opens with task data
- User changes status to "In Progress"
- User taps "Update Task"
- taskProvider.notifier.updateTask(modified task)
- TaskNotifier updates state
- HomeScreen rebuilds

**Step 5: Change Theme**
- User taps Settings
- SettingsScreen opens
- User toggles Dark Mode
- themeModeProvider.state = ThemeMode.dark
- MyApp rebuilds with dark theme
- Entire app changes color

**Step 6: Mark as Done**
- User taps status circle on task
- Status cycles to "Done"
- taskProvider.notifier.updateTaskStatus(taskId, TaskStatus.done)
- TaskNotifier updates
- HomeScreen rebuilds with strikethrough text

---

## Testing & Debugging

### Test Example: Adding a Task

```dart
test('adding a task updates the list', () {
  final container = ProviderContainer();
  
  container.read(taskProvider.notifier).addTask(
    'Test Task',
    'Description',
    DateTime.now(),
  );
  
  expect(container.read(taskProvider).length, 1);
  expect(container.read(taskProvider).first.title, 'Test Task');
});
```

### Debug: Riverpod DevTools

Add to pubspec.yaml:
```yaml
dev_dependencies:
  riverpod_generator: ^2.3.0
  riverpod_devtools: ^1.2.0
```

This provides a devtools panel to inspect providers and state changes.

---

## Performance Notes

- **Efficient Rebuilds**: Only widgets that watch a changed provider rebuild
- **Type Safety**: Dart's type system prevents many bugs
- **No Circular Dependencies**: Riverpod's dependency graph ensures acyclic dependencies
- **Lazy Loading**: Providers only computed when watched
- **Immutability**: State updates create new lists, preventing bugs

---

**Ready to extend? Add analytics, persistence, cloud sync, or real-time collaboration!** 🚀
