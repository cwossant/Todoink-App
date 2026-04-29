/// Enum representing the status of a task.
enum TaskStatus {
  notStarted('Not Started'),
  inProgress('In Progress'),
  done('Done');

  final String displayName;
  const TaskStatus(this.displayName);

  /// Returns the TaskStatus from its string representation.
  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TaskStatus.notStarted,
    );
  }
}
