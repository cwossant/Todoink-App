fl# Quick Start Guide

## 🚀 Get Running in 3 Steps

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Generate Riverpod Code
```bash
flutter pub run build_runner build
```

Or for watch mode (auto-rebuild):
```bash
flutter pub run build_runner watch
```

### Step 3: Run the App
```bash
flutter run
```

✅ **Done!** The app should now be running on your device/emulator.

---

## 📱 What You'll See

### Home Screen
- **Date Carousel**: Swipe to see next 7 days
- **Task List**: Today's tasks displayed
- **Floating Button**: Tap to add new task
- **Filter Icon**: Click to filter & sort
- **Settings Icon**: Tap to customize theme

### First Things to Try

1. **Add a Task**: Tap ➕ button
   - Enter title (required)
   - Add description (optional)
   - Pick a date
   - Tap "Add Task"

2. **Change Task Status**: Tap the colored circle on any task
   - Cycles through: Not Started → In Progress → Done

3. **Edit a Task**: Tap ⋮ menu → Edit
   - Change any field
   - Update date/status
   - Tap "Update Task"

4. **Filter Tasks**: Tap 🔍 icon
   - Select: "Not Started", "In Progress", "Done", or "All"
   - Changes apply instantly

5. **Sort Tasks**: Tap 🔍 icon
   - Choose: Date, Alphabetical, or Status
   - Click "Reset Filters" to return to default

6. **Switch to Dark Mode**: Tap ⚙️ settings icon
   - Toggle "Dark Mode" switch
   - Entire app instantly changes

7. **Change Primary Color**: Tap ⚙️ settings icon
   - Click "Change" button
   - Pick a color from the grid (16 options)
   - Tap "Reset to Default" to restore

---

## 📁 File Structure at a Glance

```
lib/
├── main.dart                    # App starts here
├── models/
│   ├── task.dart               # Task data class
│   └── task_status.dart        # Status enum (3 values)
├── providers/
│   ├── task_provider.dart      # Task list state
│   ├── theme_provider.dart     # Theme state
│   └── filter_sort_provider.dart  # Filter/sort state
├── theme/
│   └── app_theme.dart          # Light/dark themes
├── screens/
│   ├── home_screen.dart        # Main page
│   ├── add_edit_task_screen.dart   # Add/edit page
│   └── settings_screen.dart    # Settings page
└── widgets/
    ├── task_card.dart          # Single task display
    └── filter_sort_sheet.dart  # Filter/sort modal
```

---

## 🎯 Key Features

✅ **Task Management**: Create, read, update, delete tasks
✅ **Status Tracking**: Not Started, In Progress, Done
✅ **Filtering**: By status or show all tasks
✅ **Sorting**: By date, alphabetically, or by status
✅ **Date Selection**: View tasks by specific dates (7-day carousel)
✅ **Theming**: Light/dark mode + 16 custom colors
✅ **State Management**: Riverpod for reactive updates
✅ **Material Design 3**: Modern, responsive UI
✅ **No Persistence**: (Easy to add with SQLite/Hive)

---

## 🔧 Troubleshooting

### "flutter: Unable to run generator..."
```bash
flutter pub run build_runner clean
flutter pub run build_runner build
```

### "UnknownSourceException: build_runner"
Make sure you're in the project directory:
```bash
cd your_project_directory
```

### App crashes on startup
1. Clean everything:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build
```

2. Run again:
```bash
flutter run
```

### Emulator slow?
Try running on a physical device or increase emulator RAM in AVD settings.

---

## 📚 Learn More

- **Full README**: See `README.md` for detailed documentation
- **Architecture**: See `ARCHITECTURE.md` for how components work together
- **Riverpod**: https://riverpod.dev/
- **Flutter Docs**: https://flutter.dev/docs

---

## 💡 Next Steps

### Want to Add Features?

**1. Persist Tasks to Database**
- Add `sqflite` package
- Store tasks in SQLite
- Load on app startup

**2. Add Due Time (not just date)**
- Add `TimeOfDay` field to Task model
- Add time picker to AddEditTaskScreen
- Sort by time in filter_sort_provider

**3. Add Task Categories/Tags**
- Add `tags: List<String>` to Task
- Create tag_provider.dart
- Add tag filtering UI

**4. Add Notifications**
- Use `flutter_local_notifications`
- Show reminder when task is due
- Snooze functionality

**5. Cloud Sync**
- Use Firebase Firestore
- Sync tasks across devices
- Real-time updates

---

**Happy coding! 🎉**

Need help? Check `README.md` or `ARCHITECTURE.md` for detailed info.
