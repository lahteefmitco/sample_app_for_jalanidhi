/// Route names (kept free of imports so Cubits can use them without creating
/// dependency cycles with the screens that the router builds).
abstract final class RouteNames {
  /// Login screen.
  static const String login = '/login';

  /// Register (create account) screen.
  static const String register = '/register';

  /// Home dashboard, shown after a successful login.
  static const String home = '/home';

  /// List of all users.
  static const String userList = '/users';

  /// One user's details; expects the user id (`int`) as argument.
  static const String userDetails = '/users/details';

  /// List of all posts.
  static const String postList = '/posts';

  /// One post's details; expects the post id (`int`) as argument.
  static const String postDetails = '/posts/details';

  /// Create or edit a post; expects a post id (`int?`, null to create).
  static const String postForm = '/posts/form';

  /// List of all comments.
  static const String commentList = '/comments';

  /// List of all todos.
  static const String todoList = '/todos';

  /// List of all albums.
  static const String albumList = '/albums';

  /// One album's photos; expects the `AlbumModel` as argument.
  static const String albumDetails = '/albums/details';
}
