import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/app_dialog.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/square_loader.dart';

/// Centralised, duplicate-safe modal progress indicator (the square loader).
///
/// Shown/hidden from `ScreenEffectListener` in reaction to
/// `ShowProgressEffect` / `HideProgressEffect`.
abstract final class ProgressDialog {
  /// The dialog route currently shown, or null when hidden.
  static RawDialogRoute<void>? _route;

  /// The navigator the dialog was pushed on, needed to remove it later.
  static NavigatorState? _navigator;

  /// Whether the progress dialog is on screen right now.
  static bool get isShowing => _route?.isActive ?? false;

  /// Shows the non-dismissible progress dialog (only one at a time).
  static void show(BuildContext context) {
    if (isShowing) return; // never stack two progress dialogs
    // Root navigator, so the dialog covers the whole app (not one tab).
    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final RawDialogRoute<void> route = RawDialogRoute<void>(
      barrierDismissible: false,
      // Same dimmed background as every other dialog.
      barrierColor: AppDialog.barrierColor,
      barrierLabel: 'Loading',
      transitionDuration: AppDialog.openDuration,
      // The loader fades and pops in like the other dialogs.
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return AppDialog.transition(animation, child);
          },
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            // PopScope blocks the back button: only hide() may close it.
            return const PopScope(canPop: false, child: SquareLoader());
          },
    );
    _navigator = navigator;
    _route = route;
    navigator.push(route);
    screenLog('progress shown', funtionName: 'ProgressDialog.show');
  }

  /// Removes the dialog if it is showing; safe to call at any time.
  static void hide() {
    // Copy to locals and clear the fields first, so a second hide() call
    // can never remove the same route twice.
    final RawDialogRoute<void>? route = _route;
    final NavigatorState? navigator = _navigator;
    _route = null;
    _navigator = null;
    if (route != null && route.isActive && navigator != null) {
      if (route.isCurrent) {
        // On top of the stack: pop it, so it plays its closing animation.
        navigator.pop();
      } else {
        // Something was pushed above it: remove it without waiting.
        navigator.removeRoute(route);
      }
      screenLog('progress hidden', funtionName: 'ProgressDialog.hide');
    }
  }
}
