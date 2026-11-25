import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';

/// One todo tile: checkbox (toggle), title (struck through when done) and user.
///
/// It is a plain widget (no Cubit access): the parent passes the todo and the
/// callbacks, which keeps the tile easy to reuse and test.
class TodoListItem extends StatelessWidget {
  /// Creates a tile for [todo].
  const TodoListItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onTap,
  });

  /// The todo to show.
  final TodoModel todo;

  /// Called when the user taps the checkbox (marks it done / not done).
  final VoidCallback onToggle;

  /// Called when the user taps the rest of the tile (opens the details).
  final VoidCallback onTap;

  /// Builds the card with a [ListTile]: checkbox, title and user line.
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        // Checkbox showing the done state. The new value is ignored: the
        // Cubit flips the current value itself.
        leading: Checkbox(
          value: todo.completed,
          onChanged: (bool? value) => onToggle(),
        ),
        // Title, struck through when the todo is completed.
        title: Text(
          todo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
          ),
        ),
        // Owner of the todo.
        subtitle: Text('User #${todo.userId}'),
      ),
    );
  }
}
