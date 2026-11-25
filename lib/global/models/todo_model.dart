/// A todo (task) from `/todos`.
class TodoModel {
  /// Creates a todo; every field is required.
  const TodoModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
  });

  /// Builds a [TodoModel] from the API's JSON object.
  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }

  /// Unique todo id.
  final int id;

  /// Id of the user the todo belongs to.
  final int userId;

  /// What has to be done.
  final String title;

  /// Whether the task is done.
  final bool completed;

  /// Converts the model back to JSON (e.g. to send it to the API).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'title': title,
    'completed': completed,
  };

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'TodoModel(id: $id, userId: $userId, title: $title, '
      'completed: $completed)';
}
