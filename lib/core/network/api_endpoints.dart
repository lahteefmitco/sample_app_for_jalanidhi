/// Single source of truth for the backend URL and its endpoints.
///
/// Paths are relative to [baseUrl], which Dio adds automatically.
abstract final class ApiEndpoints {
  /// Root URL of the JSONPlaceholder demo API.
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Every user.
  static const String users = '/users';

  /// One user, by [id].
  static String user(int id) => '/users/$id';

  /// Every post written by the user with [id].
  static String userPosts(int id) => '/users/$id/posts';

  /// Every post (also the target of "create post").
  static const String posts = '/posts';

  /// One post, by [id] (also the target of update and delete).
  static String post(int id) => '/posts/$id';

  /// Every comment (filter with `?postId=`).
  static const String comments = '/comments';

  /// Every album.
  static const String albums = '/albums';

  /// Every photo (filter with `?albumId=`).
  static const String photos = '/photos';

  /// Every todo.
  static const String todos = '/todos';

  /// One todo, by [id].
  static String todo(int id) => '/todos/$id';
}
