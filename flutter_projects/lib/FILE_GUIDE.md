# File Organization & Integration Guide

This document explains how to piece together all the files for the Daily To-Do List app.

---

## 📋 Complete File Listing

### Root Configuration
```
pubspec.yaml
```
Contains all dependencies needed for the app. Run `flutter pub get` to install them.

**Key dependencies:**
- `flutter_riverpod` - State management
- `intl` - Date formatting
- `uuid` - Unique IDs
- Build tools for code generation

---

### Entry Point
```
lib/main.dart
```
**Purpose**: App bootstrap and theme setup

**What it does**:
1. Wraps app with `ProviderScope` (enables Riverpod)
2. Watches `themeModeProvider` for light/dark switch
3. Watches `customPrimaryColorProvider` for color changes
4. Applies dynamic themes to MaterialApp
5. Routes to HomeScreen

**Key imports**: theme_provider, home_screen, app_theme

**When to modify**: If you want to add new root-level logic or screens

---

## 📁 Models Folder

### task_status.dart
**Purpose**: Define the three task status states

**Contains**:
```dart
enum TaskStatus {
  notStarted('Not Started'),
  inProgress('In Progress'),
  done('Done')
}
```

**Features**:
- Display names for UI
- `fromString()` method to convert strings

**When to modify**: Add new statuses (e.g., `archived`, `cancelled`)

### task.dart
**Purpose**: Task data model

**Contains**:
```dart
class Task {
  String id              // Unique identifier (UUID)
  String title           // Task title (required)
  String description     // Optional description
  DateTime date          // Due date
  TaskStatus status      // Current status
  DateTime createdAt     // Creation timestamp
}
```

**Features**:
- `copyWith()` for immutable updates
- Equality/hash for comparisons
- Immutable by design

**Dependencies**: task_status.dart

**When to modify**: Add new task fields (e.g., priority, assignee, tags)

---

## 🎨 Theme Folder

### app_theme.dart
**Purpose**: Define light and dark themes

**Contains**:
- `lightTheme(Color primaryColor)` - Light theme with primary color
- `darkTheme(Color primaryColor)` - Dark theme with primary color

**Features**:
- Material Design 3 support
- Customizable primary colors
- Consistent styling for all widgets
- Input field styling
- AppBar theming

**When to modify**: Change colors, padding, border radius, or add new themed components

---

## 📊 Providers Folder

These files manage application state using Riverpod.

### task_provider.dart
**Purpose**: Manage the task list (primary data source)

**Contains**:
```dart
final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>
```

**Features**:
- `addTask(title, description, date)` - Add new task
- `updateTask(updatedTask)` - Modify existing task
- `deleteTask(taskId)` - Remove task
- `updateTaskStatus(taskId, newStatus)` - Change status
- `getTasksForDate(date)` - Filter tasks by date

**Initial State**: Empty list `[]`

**Dependencies**: task.dart, task_status.dart, uuid package

**Key Pattern**: StateNotifierProvider with custom notifier class

**When to modify**: Add new task operations (e.g., bulk delete, archive)

### theme_provider.dart
**Purpose**: Manage theme state (light/dark mode and colors)

**Contains**:
- `themeModeProvider` - Switch between light/dark (StateProvider)
- `customPrimaryColorProvider` - Current primary color (StateNotifierProvider)

**Features**:
- `PrimaryColorNotifier.setColor(color)` - Change primary color
- `PrimaryColorNotifier.reset()` - Reset to default blue

**Initial State**: Light mode, Blue primary color

**Key Pattern**: StateProvider for simple values, StateNotifierProvider for complex logic

**When to modify**: Add secondary colors, accent colors, or font theme switching

### filter_sort_provider.dart
**Purpose**: Manage filtering and sorting state

**Contains**:
```dart
enum SortOption {
  date('Sort by Date'),
  alphabetical('Sort Alphabetically'),
  status('Sort by Status')
}

final filterStatusProvider           // Which status to filter
final sortOptionProvider              // How to sort
final filteredAndSortedTasksProvider  // Computed result
```

**Features**:
- Three sort options
- Optional status filter (null = show all)
- Computed provider that combines filters and sorts

**Initial State**: No filter, sort by date

**Key Pattern**: Provider (computed) that watches multiple sources

**Dependencies**: task_provider.dart, task_status.dart

**When to modify**: Add new sort options, change sort logic, add search filters

---

## 🖥️ Screens Folder

Screens are full-page widgets that users navigate to.

### home_screen.dart
**Purpose**: Main task list display (primary UI)

**Features**:
- 7-day date carousel (horizontal swipe)
- Task list for selected date
- Filter/sort button
- Settings button
- Floating action button to add tasks
- Tap to cycle task status
- Edit/delete context menu

**State Watching**:
- `filteredAndSortedTasksProvider` - Display filtered/sorted tasks
- Manages `selectedDate` locally with setState

**Interactions**:
- Tap date: `setState` to change selectedDate
- Tap FAB: Navigate to AddEditTaskScreen
- Tap filter icon: Show FilterSortSheet
- Tap settings icon: Navigate to SettingsScreen
- Tap status circle: Call `updateTaskStatus`
- Tap edit: Navigate to AddEditTaskScreen with task
- Tap delete: Show confirmation, call `deleteTask`

**Dependencies**: task_provider, filter_sort_provider, task_card, filter_sort_sheet, add_edit_task_screen, settings_screen

**When to modify**: Change date carousel style, restructure task list layout, add new actions

---

### add_edit_task_screen.dart
**Purpose**: Create and edit tasks (form UI)

**Features**:
- Title field (required, with validation)
- Description field (optional, multi-line)
- Date picker (calendar dialog)
- Status chips (only when editing)
- Save button with validation

**State Management**:
- Local TextEditingControllers for form fields
- Local DateTime for selected date
- Local TaskStatus for selected status (edit mode only)

**Interactions**:
- Validate on save (title required)
- Show date picker dialog
- Call `taskProvider.addTask()` for new tasks
- Call `taskProvider.updateTask()` for edits
- Navigate back on save
- Show snackbar on validation error

**Constructor Parameters**:
- `task` - Optional. If provided, enter edit mode

**Dependencies**: task_provider, task (model), task_status

**When to modify**: Add new task fields, change form layout, add more validation

---

### settings_screen.dart
**Purpose**: App settings and customization

**Features**:
- Dark mode toggle switch
- Primary color picker (16 colors in a grid)
- Reset to default color button
- About section with app info

**State Watching**:
- `themeModeProvider` - Current theme mode
- `customPrimaryColorProvider` - Current color

**Interactions**:
- Toggle switch: Update `themeModeProvider`
- Tap color: Update `customPrimaryColorProvider`
- Tap reset: Call `.reset()` on color notifier
- Color picker dialog shows 16 pre-selected colors

**Dependencies**: theme_provider

**When to modify**: Add more settings (font size, language, notifications), restructure settings layout

---

## 🧩 Widgets Folder

Reusable widget components.

### task_card.dart
**Purpose**: Display individual task in list

**Features**:
- Color-coded status circle (click to cycle status)
- Task title with strikethrough for completed tasks
- Description text (truncated with ellipsis)
- Formatted due date
- Edit/delete menu button

**Properties**:
```dart
final Task task              // Task to display
final VoidCallback onEdit    // Edit button callback
final VoidCallback onDelete  // Delete button callback
```

**Interactions**:
- Tap status circle: Cycle to next status (calls `updateTaskStatus`)
- Tap menu: Show popup menu
- Select "Edit": Call onEdit (HomeScreen navigates to form)
- Select "Delete": Call onDelete (HomeScreen shows confirmation)

**Visual Indicators**:
- Grey circle: Not Started
- Orange circle: In Progress
- Green circle: Done (with checkmark)

**Dependencies**: task_provider, task (model), task_status, intl

**When to modify**: Change status circle design, add animations, add priority/tag display

---

### filter_sort_sheet.dart
**Purpose**: Modal bottom sheet for filter and sort controls

**Features**:
- Filter chips (All, Not Started, In Progress, Done)
- Sort chips (Date, Alphabetical, Status)
- Reset filters button

**State Watching**:
- `filterStatusProvider` - Currently selected filter
- `sortOptionProvider` - Currently selected sort

**Interactions**:
- Tap filter chip: Update `filterStatusProvider`
- Tap sort chip: Update `sortOptionProvider`
- Tap "Reset Filters": Set filter to null, sort to date

**Design**:
- Shows in bottom modal sheet with rounded top corners
- FilterChips highlight when selected
- Reset button is styled differently

**Dependencies**: filter_sort_provider, task_status

**When to modify**: Add more filter options, redesign chip layout, add search

---

## 🔄 Integration Flow

### How the App Launches

```
main.dart (entry point)
  ↓
ProviderScope wraps MyApp
  ↓
MyApp watches theme providers
  ↓
Apply theme to MaterialApp
  ↓
HomeScreen loads
  ↓
HomeScreen watches filteredAndSortedTasksProvider
  ↓
Display tasks for today
```

### How Adding a Task Works

```
HomeScreen (tap FAB)
  ↓
AddEditTaskScreen opens
  ↓
User fills form and taps "Add Task"
  ↓
ValidationCheck (title empty?)
  ↓
ref.read(taskProvider.notifier).addTask(...)
  ↓
TaskNotifier.addTask() executes
  ↓
state = [...state, newTask]
  ↓
taskProvider listeners notified
  ↓
filteredAndSortedTasksProvider recomputes
  ↓
HomeScreen rebuilds
  ↓
New task appears in list
  ↓
Navigation back to HomeScreen
```

### How Filtering Works

```
HomeScreen (tap filter icon)
  ↓
FilterSortSheet shows
  ↓
User selects "In Progress"
  ↓
ref.read(filterStatusProvider.notifier).state = TaskStatus.inProgress
  ↓
filterStatusProvider listeners notified
  ↓
filteredAndSortedTasksProvider recalculates
  ↓
HomeScreen rebuilds with filtered tasks
```

### How Theming Works

```
SettingsScreen (toggle dark mode)
  ↓
ref.read(themeModeProvider.notifier).state = ThemeMode.dark
  ↓
themeModeProvider listeners notified
  ↓
MyApp rebuilds
  ↓
ThemeMode.dark picked from build logic
  ↓
darkTheme: AppTheme.darkTheme(primaryColor) applied
  ↓
MaterialApp.themeData updated
  ↓
Entire app re-themed instantly
```

---

## 🎯 File Organization Principles

### By Purpose

**Models** (pure data):
- task.dart
- task_status.dart

**State Management** (Riverpod providers):
- task_provider.dart
- theme_provider.dart
- filter_sort_provider.dart

**Styling** (theming):
- app_theme.dart

**Screens** (full pages):
- home_screen.dart
- add_edit_task_screen.dart
- settings_screen.dart

**Widgets** (reusable components):
- task_card.dart
- filter_sort_sheet.dart

**Bootstrap** (app entry):
- main.dart

---

## 🚀 How to Extend

### Adding a New Feature (e.g., Task Categories)

1. **Add Model** (models/category.dart)
   ```dart
   class Category {
     String id, name, color
   }
   ```

2. **Add Provider** (providers/category_provider.dart)
   ```dart
   final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>
   ```

3. **Update Task Model** (models/task.dart)
   ```dart
   String? categoryId  // Add this field
   ```

4. **Create Widget** (widgets/category_chip.dart)
   ```dart
   class CategoryChip extends ConsumerWidget
   ```

5. **Update Screens**
   - Add category selection to add_edit_task_screen.dart
   - Add category filter to filter_sort_sheet.dart

6. **Update Home Screen**
   - Show category tags on task_card.dart

---

## ✅ Dependency Tree

```
main.dart
├─ theme_provider.dart
├─ app_theme.dart
└─ home_screen.dart

home_screen.dart
├─ task_provider.dart
├─ filter_sort_provider.dart
├─ task_card.dart
├─ filter_sort_sheet.dart
├─ add_edit_task_screen.dart
└─ settings_screen.dart

add_edit_task_screen.dart
├─ task_provider.dart
├─ task.dart
└─ task_status.dart

settings_screen.dart
└─ theme_provider.dart

task_card.dart
├─ task_provider.dart
├─ task.dart
└─ task_status.dart

filter_sort_sheet.dart
├─ filter_sort_provider.dart
└─ task_status.dart

task_provider.dart
├─ task.dart
├─ task_status.dart
└─ uuid (package)

filter_sort_provider.dart
├─ task_provider.dart
└─ task_status.dart

task.dart
└─ task_status.dart

theme_provider.dart
└─ (no dependencies)

task_status.dart
└─ (no dependencies)

app_theme.dart
└─ (no dependencies)
```

---

**Now you have a complete understanding of how all files fit together!** 🎉

Check `QUICKSTART.md` to run the app or `README.md` for full documentation.
