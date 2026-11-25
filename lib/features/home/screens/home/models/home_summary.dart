/// Aggregated numbers shown on the dashboard.
///
/// Built by `HomeCubit.load` from the lists returned by the repositories;
/// only the counts are kept, not the lists themselves.
class HomeSummary {
  /// Creates the summary from already-calculated counts.
  const HomeSummary({
    required this.userCount,
    required this.postCount,
    required this.commentCount,
    required this.albumCount,
    required this.completedTodoCount,
    required this.pendingTodoCount,
  });

  /// Number of users.
  final int userCount;

  /// Number of posts.
  final int postCount;

  /// Number of comments.
  final int commentCount;

  /// Number of albums.
  final int albumCount;

  /// Number of todos marked as done.
  final int completedTodoCount;

  /// Number of todos not done yet.
  final int pendingTodoCount;

  /// Total number of todos (completed + pending).
  int get todoCount => completedTodoCount + pendingTodoCount;

  /// Share of completed todos, `0.0`..`1.0`.
  ///
  /// Returns 0 when there are no todos, to avoid dividing by zero.
  double get todoCompletionRate =>
      todoCount == 0 ? 0 : completedTodoCount / todoCount;

  /// Readable description used in logs and while debugging.
  @override
  String toString() =>
      'HomeSummary(users: $userCount, posts: $postCount, '
      'comments: $commentCount, albums: $albumCount, '
      'completedTodos: $completedTodoCount, pendingTodos: $pendingTodoCount)';
}
