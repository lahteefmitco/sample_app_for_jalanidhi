/// Every user-visible text of the app, in one place.
///
/// Keeping strings here (instead of inline in widgets) makes them easy to
/// find, reuse and later translate.
abstract final class AppStrings {
  // General

  /// Label of buttons that repeat a failed action.
  static const String retry = 'Retry';

  /// Label of buttons that close a dialog without doing anything.
  static const String cancel = 'Cancel';

  /// Label of buttons that accept a confirmation dialog.
  static const String confirm = 'Confirm';

  /// Label of delete buttons and menu items.
  static const String delete = 'Delete';

  /// Label of edit buttons and menu items.
  static const String edit = 'Edit';

  /// Label of save buttons in forms.
  static const String save = 'Save';

  /// Hint text of search boxes.
  static const String search = 'Search';

  /// Label of the button that shows the next page of a list.
  static const String loadMore = 'Load more';

  /// Shown when a search or filter matches nothing.
  static const String noResults = 'No results found';

  /// Generic error title.
  static const String somethingWentWrong = 'Something went wrong';

  /// Validation error for an empty required form field.
  static const String requiredField = 'This field is required';

  // Errors

  /// Shown when the device has no connection.
  static const String networkError =
      'No internet connection. Please check your network and try again.';

  /// Shown when the server takes too long to answer.
  static const String timeoutError = 'The request timed out. Please try again.';

  /// Shown when the server answers with an error status (e.g. 500).
  static const String serverError =
      'The server could not process the request. Please try again later.';

  /// Shown when the server's answer cannot be parsed.
  static const String invalidResponse =
      'The server returned an unexpected response.';

  /// Shown for any error the app does not recognise.
  static const String unexpectedError =
      'An unexpected error occurred. Please try again.';

  // Theme

  /// Tooltip of the theme menu button.
  static const String theme = 'Theme';

  /// Theme menu item: follow the device setting.
  static const String themeSystem = 'System default';

  /// Theme menu item: always light.
  static const String themeLight = 'Day (light)';

  /// Theme menu item: always dark.
  static const String themeDark = 'Night (dark)';

  // Authentication

  /// Login screen title and button label.
  static const String login = 'Login';

  /// Register screen title and button label.
  static const String register = 'Register';

  /// Logout button label.
  static const String logout = 'Logout';

  /// Label of email fields.
  static const String email = 'Email';

  /// Label of password fields.
  static const String password = 'Password';

  /// Label of the "repeat password" field on the register screen.
  static const String confirmPassword = 'Confirm password';

  /// Label of the name field on the register screen.
  static const String fullName = 'Full name';

  /// Heading of the login screen.
  static const String welcomeBack = 'Welcome back';

  /// Heading of the register screen.
  static const String createAccount = 'Create account';

  /// Link from the login screen to the register screen.
  static const String noAccountYet = "Don't have an account? Register";

  /// Link from the register screen back to the login screen.
  static const String haveAccount = 'Already have an account? Login';

  /// Note explaining that accounts are only simulated locally.
  static const String authDisclaimer =
      'JSONPlaceholder has no authentication. Accounts are simulated on this '
      'device only.';

  /// Validation error for a badly formatted email.
  static const String invalidEmail = 'Enter a valid email address';

  /// Validation error for a password below the minimum length.
  static const String passwordTooShort = 'Password is too short';

  /// Validation error when the two password fields differ.
  static const String passwordsDoNotMatch = 'Passwords do not match';

  /// Login error for a wrong email or password.
  static const String invalidCredentials = 'Invalid email or password';

  /// Register error when the email is already used.
  static const String accountExists = 'An account with this email exists';

  /// Title of the logout confirmation dialog.
  static const String confirmLogoutTitle = 'Log out?';

  /// Message of the logout confirmation dialog.
  static const String confirmLogoutMessage =
      'You will need to log in again to continue.';

  // Home

  /// Title of the home screen.
  static const String dashboard = 'Dashboard';

  /// Heading of the home screen's navigation section.
  static const String navigation = 'Explore';

  /// Heading of the home screen's counts section.
  static const String summary = 'Summary';

  // Users

  /// Title of the user list screen.
  static const String users = 'Users';

  /// Title of the user details screen.
  static const String userDetails = 'User details';

  /// Heading of the user's posts on the user details screen.
  static const String userPosts = 'Posts by this user';

  /// City filter option that shows every city.
  static const String allCities = 'All cities';

  /// Label of the sort menu.
  static const String sortBy = 'Sort';

  /// Empty state of the user list.
  static const String noUsers = 'No users match your search';

  // Posts

  /// Title of the post list screen.
  static const String posts = 'Posts';

  /// Title of the post details screen.
  static const String postDetails = 'Post details';

  /// Title of the post form in create mode.
  static const String newPost = 'New post';

  /// Title of the post form in edit mode.
  static const String editPost = 'Edit post';

  /// Label of the post title field.
  static const String postTitle = 'Title';

  /// Label of the post body field.
  static const String postBody = 'Body';

  /// Label of the post author selector.
  static const String author = 'Author';

  /// Author filter option that shows every author.
  static const String allAuthors = 'All authors';

  /// Empty state of the post list.
  static const String noPosts = 'No posts found';

  /// Title of the delete-post confirmation dialog.
  static const String confirmDeletePostTitle = 'Delete post?';

  /// Message of the delete-post confirmation dialog.
  static const String confirmDeletePostMessage =
      'This removes the post from this session. JSONPlaceholder does not '
      'persist changes.';

  /// Snackbar shown after a post was saved.
  static const String postSaved = 'Post saved (simulated, not persisted)';

  /// Snackbar shown after a post was deleted.
  static const String postDeleted = 'Post deleted (simulated, not persisted)';

  // Comments

  /// Title of the comment list screen.
  static const String comments = 'Comments';

  /// Empty state of the comment list.
  static const String noComments = 'No comments found';

  // Todos

  /// Title of the todo list screen.
  static const String todos = 'Todos';

  /// Todo filter option that shows every todo.
  static const String all = 'All';

  /// Todo filter option for todos not done yet.
  static const String pending = 'Pending';

  /// Todo filter option for finished todos.
  static const String completed = 'Completed';

  /// Empty state of the todo list.
  static const String noTodos = 'No todos found';

  // Albums

  /// Title of the album list screen.
  static const String albums = 'Albums';

  /// Heading of an album's photo grid.
  static const String photos = 'Photos';

  /// Empty state of the album list.
  static const String noAlbums = 'No albums found';

  /// Empty state of an album without photos.
  static const String noPhotos = 'No photos in this album';
}
