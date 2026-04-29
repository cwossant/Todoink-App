# Daily To-Do List App - Complete Guide

A production-ready Flutter To-Do List application with filtering, sorting, theming, and modern state management using Riverpod.

## 📋 Table of Contents

1. [Project Structure](#project-structure)
2. [Setup Instructions](#setup-instructions)
3. [File Breakdown](#file-breakdown)
4. [Features Explained](#features-explained)
5. [How to Use](#how-to-use)
6. [State Management Overview](#state-management-overview)

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   ├── task.dart                      # Task model class
│   └── task_status.dart               # Task status enum
├── providers/
│   ├── task_provider.dart             # Task list state management
│   ├── theme_provider.dart            # Theme mode & color state
│   └── filter_sort_provider.dart      # Filter & sort state
├── theme/
│   └── app_theme.dart                 # Theme definitions (light/dark)
├── screens/
│   ├── home_screen.dart               # Main task list screen
│   ├── add_edit_task_screen.dart      # Add/edit task screen
│   └── settings_screen.dart           # Settings & theme screen
└── widgets/
    ├── task_card.dart                 # Individual task display
    └── filter_sort_sheet.dart         # Filter/sort UI
pubspec.yaml                           # Dependencies
```

---

## 🚀 Setup Instructions

### Step 1: Update Dependencies
Open your terminal and run:
```bash
cd your_project_directory
flutter pub get
```

This will download and install all dependencies listed in `pubspec.yaml`.

### Step 2: Build Riverpod (Code Generation)
Riverpod uses code generation. Run:
```bash
flutter pub run build_runner build
```

Or for watch mode (auto-rebuild on changes):
```bash
flutter pub run build_runner watch
```

### Step 3: Run the App
```bash
flutter run
```

---

## 📚 File Breakdown

### **main.dart** - Application Entry Point
- Wraps the app with `ProviderScope` to enable Riverpod
- Watches theme mode and primary color from Riverpod providers
- Applies themes dynamically based on user settings
- Routes to `HomeScreen` as the initial screen

```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

### **models/task_status.dart** - Enum Definition
Defines three strictly defined task statuses:
- `notStarted` - Task not yet started
- `inProgress` - Task currently being worked on
- `done` - Task completed

Includes a helper method `fromString()` for converting strings to enums.

### **models/task.dart** - Data Model
The `Task` class represents a single to-do item with:
- `id` - Unique identifier (UUID)
- `title` - Task title (required)
- `description` - Optional description
- `date` - Due date
- `status` - Current status (TaskStatus enum)
- `createdAt` - Timestamp of creation

Includes:
- `copyWith()` method for immutable updates
- Equality and hash code overrides for comparison

### **theme/app_theme.dart** - Theme Configuration
Contains two static methods:
- `lightTheme(Color primaryColor)` - Light theme with customizable primary color
- `darkTheme(Color primaryColor)` - Dark theme with customizable primary color

Both use Material Design 3 with `useMaterial3: true` and respect the primary color seed.

### **providers/task_provider.dart** - Task Management State
Uses Riverpod's `StateNotifierProvider` to manage the task list.

**Methods:**
- `addTask()` - Add a new task with auto-generated UUID
- `updateTask()` - Update an existing task
- `deleteTask()` - Remove a task by ID
- `updateTaskStatus()` - Change a task's status
- `getTasksForDate()` - Retrieve tasks for a specific date

### **providers/theme_provider.dart** - Theme State
Two providers handle theming:
- `themeModeProvider` - Switch between light/dark modes
- `customPrimaryColorProvider` - Custom color selection with reset functionality

### **providers/filter_sort_provider.dart** - Filtering & Sorting
Manages filtering and sorting logic:
- `filterStatusProvider` - Filter tasks by status (or show all)
- `sortOptionProvider` - Choose sort order
- `filteredAndSortedTasksProvider` - Computed provider that applies both filter and sort

**Sort Options:**
- By Date (earliest first)
- Alphabetically (A-Z)
- By Status (Not Started → In Progress → Done)

### **screens/home_screen.dart** - Main Task List
The primary user interface with:
- **Date Selector**: Swipeable date carousel (next 7 days)
- **Task List**: Displays tasks for the selected date
- **Floating Action Button**: Add new task
- **Filter/Sort Button**: Opens bottom sheet
- **Settings Button**: Navigate to settings

**Task Cards** are interactive:
- Tap status circle to cycle through statuses
- Long press or menu button to edit/delete
- Strikethrough text for completed tasks

### **screens/add_edit_task_screen.dart** - Task Form
Form to create or edit tasks with:
- **Title Field** (required)
- **Description Field** (optional)
- **Date Picker** (select due date)
- **Status Chips** (only shown when editing)
- **Save Button** (validates and saves)

Uses date picker dialog for date selection. Auto-populates fields when editing.

### **screens/settings_screen.dart** - Customization
Settings screen with:
- **Dark Mode Toggle** - Switch between light/dark themes
- **Primary Color Picker** - Choose from 16 colors
- **Reset to Default** - Restore original color
- **About Section** - App info

The color picker displays a grid of 16 pre-selected colors for easy selection.

### **widgets/task_card.dart** - Task Display Component
Displays individual tasks with:
- **Status Indicator**: Color-coded circle showing status
- **Title & Description**: Task details
- **Date**: Formatted due date
- **Menu Button**: Edit/delete options
- **Status Cycling**: Tap circle to change status

Color coding:
- Grey: Not Started
- Orange: In Progress
- Green: Done

### **widgets/filter_sort_sheet.dart** - Bottom Sheet UI
Modal bottom sheet for filtering and sorting with:
- **Filter Chips** - Select one status or "All"
- **Sort Chips** - Choose sort method
- **Reset Button** - Clear all filters and return to default sort

---

## ✨ Features Explained

### 1. Task Model & Properties ✓
- **Title**: Required string
- **Description**: Optional string
- **Date**: DateTime for due date
- **Status**: Enum with 3 strictly defined states
- Auto-generated UUID for unique identification

### 2. Core UI & Navigation ✓
- **Daily List View**: Main screen shows tasks by date
- **Date Selector**: Quick navigation to view next 7 days
- **Add/Edit/Delete**: Full CRUD operations on tasks
- **Navigation**: Screens connected with MaterialPageRoute

### 3. Filtering and Sorting ✓
- **Filter**: By Status (Not Started, In Progress, Done) or show all
- **Sort**: By Date, Alphabetically, or by Status
- **UI Controls**: Bottom sheet with chip selections
- **Computed State**: Filtered list updates automatically

### 4. Customizable Theming ✓
- **Light/Dark Modes**: Toggle in settings
- **16 Primary Colors**: Color picker in settings
- **Material Design 3**: Modern, responsive design
- **Dynamic Theming**: Changes apply instantly app-wide

### 5. State Management ✓
- **Riverpod**: Modern, lightweight state management
- **No Build Context Issues**: Riverpod handles state efficiently
- **Reactive Updates**: UI automatically rebuilds when state changes
- **Provider Composition**: Complex state derived from simple providers

---

## 🎯 How to Use

### Running the App
1. Ensure all dependencies are installed: `flutter pub get`
2. Run Riverpod code generation: `flutter pub run build_runner build`
3. Start the app: `flutter run`

### Adding a Task
1. Tap the floating action button (➕)
2. Enter task title (required)
3. Enter description (optional)
4. Select due date using calendar picker
5. Tap "Add Task"

### Editing a Task
1. Tap the menu (⋮) on any task card
2. Select "Edit"
3. Modify title, description, date, or status
4. Tap "Update Task"

### Managing Task Status
- **Tap the status circle** on a task card to cycle through statuses
- Or use the "Edit" option to explicitly set status

### Deleting a Task
1. Tap the menu (⋮) on any task card
2. Select "Delete"
3. Confirm deletion

### Filtering Tasks
1. Tap the filter icon (🔍) in the app bar
2. Select a status or "All"
3. Chips highlight active filters

### Sorting Tasks
1. Tap the filter icon (🔍) in the app bar
2. Choose a sort option
3. Changes apply immediately

### Changing Appearance
1. Tap settings icon (⚙️) in app bar
2. Toggle "Dark Mode" switch
3. Or tap "Change" to select a primary color
4. Tap "Reset to Default" to restore original color

### Viewing Different Dates
1. Swipe left/right through the date carousel at the top
2. Or tap a date to jump to it
3. Task list updates to show tasks for that date

---

## 🔄 State Management Overview (Riverpod)

### Why Riverpod?
- **Compile-time Safety**: Errors caught at build time
- **No Context Required**: Access state anywhere without BuildContext
- **Testable**: Easy to mock and test providers
- **Composable**: Providers can depend on other providers
- **Performance**: Only rebuilds affected widgets

### Provider Types Used

#### **StateNotifierProvider**
```dart
final taskProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  return TaskNotifier();
});
```
Used for mutable state (task list). The `TaskNotifier` class contains logic.

#### **StateProvider**
```dart
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
});
```
Simple state without logic. Typically for toggles and selections.

#### **Provider** (Computed)
```dart
final filteredAndSortedTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(taskProvider);
  final filterStatus = ref.watch(filterStatusProvider);
  // ... compute filtered list
  return sorted;
});
```
Derived state computed from other providers. Automatically updates.

### Key Patterns

**Watching a Provider** (rebuilds when provider changes):
```dart
final tasks = ref.watch(taskProvider);
```

**Reading a Provider** (one-time read, no rebuild):
```dart
ref.read(taskProvider.notifier).addTask(...);
```

**Modifying State**:
```dart
ref.read(taskProvider.notifier).updateTask(updatedTask);
```

---

## 🎨 Customization

### Adding a New Status
1. Edit [models/task_status.dart](models/task_status.dart)
2. Add new enum value:
   ```dart
   enum TaskStatus {
     notStarted('Not Started'),
     inProgress('In Progress'),
     done('Done'),
     newStatus('New Status'),  // Add here
   ```

### Adding a New Sort Option
1. Edit [providers/filter_sort_provider.dart](providers/filter_sort_provider.dart)
2. Add to `SortOption` enum
3. Add sort logic in `filteredAndSortedTasksProvider`

### Changing Theme Colors
Edit [theme/app_theme.dart](theme/app_theme.dart) to customize:
- AppBar styling
- Input field appearance
- FloatingActionButton colors
- Border radius and padding

### Adding Persistence
To save tasks locally, integrate with:
- **SQLite**: `sqflite` package
- **Hive**: `hive` package
- **Firebase**: `firebase_database` package

Store and restore in `TaskNotifier`:
```dart
Future<void> loadTasks() async {
  // Load from database
}

Future<void> saveTasks() async {
  // Save to database
}
```

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `riverpod_annotation` | Annotations for Riverpod |
| `build_runner` | Code generation |
| `riverpod_generator` | Generate Riverpod code |
| `intl` | Date & time formatting |
| `uuid` | Generate unique task IDs |
| `cupertino_icons` | iOS-style icons |

---

## 🤝 Contributing

This is a learning/starter template. Feel free to:
- Extend features
- Add persistence
- Improve UI/UX
- Add animations
- Integrate with backend APIs

---

## ✅ Checklist for First Run

- [ ] Run `flutter pub get`
- [ ] Run `flutter pub run build_runner build`
- [ ] Run `flutter run`
- [ ] Add a few test tasks
- [ ] Try filtering and sorting
- [ ] Toggle dark mode
- [ ] Change primary color
- [ ] Edit and delete tasks
- [ ] View different dates

---

**Happy task managing! 🎉**
