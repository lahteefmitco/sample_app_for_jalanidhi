/// One-time UI effects (the "ListenerState" side of a screen state).
///
/// Effects are consumed by `ScreenEffectListener` (a BlocListener) and are
/// never read while building widgets.
abstract class UiEffect {
  /// Lets subclasses have `const` constructors.
  const UiEffect();
}

/// Shows the modal progress dialog (e.g. while saving).
class ShowProgressEffect extends UiEffect {
  /// Creates the effect; it carries no data.
  const ShowProgressEffect();

  /// Readable description, handy in logs.
  @override
  String toString() => 'ShowProgressEffect()';
}

/// Hides the modal progress dialog opened by [ShowProgressEffect].
class HideProgressEffect extends UiEffect {
  /// Creates the effect; it carries no data.
  const HideProgressEffect();

  /// Readable description, handy in logs.
  @override
  String toString() => 'HideProgressEffect()';
}

/// The look of a snackbar, which decides its background color.
enum SnackbarType {
  /// Green: an action worked.
  success,

  /// Red: something failed.
  error,

  /// Blue: neutral information.
  info,
}

/// Shows a snackbar with [message] at the bottom of the screen.
class ShowSnackbarEffect extends UiEffect {
  /// Creates the effect; the [type] defaults to an info snackbar.
  const ShowSnackbarEffect(this.message, {this.type = SnackbarType.info});

  /// Text shown in the snackbar.
  final String message;

  /// Look of the snackbar (success, error or info).
  final SnackbarType type;

  /// Readable description, handy in logs.
  @override
  String toString() => 'ShowSnackbarEffect(type: $type, message: $message)';
}

/// How a [NavigateEffect] changes the navigation stack.
enum NavigationStyle {
  /// Opens the page on top; the back button returns here.
  push,

  /// Replaces the current page (e.g. login -> home).
  replace,

  /// Removes every page and opens the new one (e.g. after logout).
  clearStack,
}

/// Opens another page by its route name.
class NavigateEffect extends UiEffect {
  /// Creates the effect; [mode] defaults to a normal push.
  const NavigateEffect(
    this.routeName, {
    this.arguments,
    this.mode = NavigationStyle.push,
  });

  /// Route to open (see `RouteNames`).
  final String routeName;

  /// Value passed to the route (e.g. an id), or null.
  final Object? arguments;

  /// How the navigation stack is changed.
  final NavigationStyle mode;

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'NavigateEffect(routeName: $routeName, arguments: $arguments, '
      'mode: $mode)';
}

/// Closes the current page, optionally returning [result] to the caller.
class PopEffect extends UiEffect {
  /// Creates the effect with an optional [result].
  const PopEffect([this.result]);

  /// Value handed back to the previous page (e.g. `'saved'`), or null.
  final Object? result;

  /// Readable description, handy in logs.
  @override
  String toString() => 'PopEffect(result: $result)';
}

/// Asks the user to confirm an action. When confirmed, the listener calls
/// `ScreenCubit.onConfirmed(actionId)`.
class ShowConfirmationEffect extends UiEffect {
  /// Creates the effect; the confirm button says "Confirm" by default.
  const ShowConfirmationEffect({
    required this.actionId,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.isDestructive = false,
  });

  /// Identifies the action, so the Cubit knows what was confirmed.
  final String actionId;

  /// Dialog title.
  final String title;

  /// Dialog text explaining the action.
  final String message;

  /// Label of the confirm button.
  final String confirmLabel;

  /// True for actions that cannot be undone (delete): the dialog then uses a
  /// red icon and a red confirm button.
  final bool isDestructive;

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'ShowConfirmationEffect(actionId: $actionId, '
      'isDestructive: $isDestructive)';
}

/// Opens a bottom sheet listing label/value pairs (details of an item).
class ShowInfoSheetEffect extends UiEffect {
  /// Creates the effect with a [title] and the rows to show.
  const ShowInfoSheetEffect({required this.title, required this.fields});

  /// Heading of the bottom sheet.
  final String title;

  /// Rows of the sheet: `key` is the label, `value` is the text.
  final List<MapEntry<String, String>> fields;

  /// Readable description, handy in logs.
  @override
  String toString() => 'ShowInfoSheetEffect(title: $title)';
}
