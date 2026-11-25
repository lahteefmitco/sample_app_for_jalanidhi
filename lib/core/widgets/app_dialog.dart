import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';

/// Opens dialogs with the app's animation instead of Flutter's plain fade.
///
/// The animation ([transition]):
///  * the dialog fades in,
///  * grows from 85 % to 100 % with a small "pop" overshoot,
///  * rises a few pixels,
///  * and the background is dimmed smoothly.
/// Closing plays the same animation backwards.
///
/// Every dialog of the app (confirmations, the progress loader) goes through
/// this class, so they all look and feel the same.
abstract final class AppDialog {
  /// How long the dialog takes to appear.
  static const Duration openDuration = Duration(milliseconds: 280);

  /// How long the dialog takes to disappear (a little quicker).
  static const Duration closeDuration = Duration(milliseconds: 200);

  /// Color of the dimmed background behind a dialog.
  static const Color barrierColor = Color(0x99000000);

  /// The animation used by every dialog: fade + pop-in scale + small rise.
  ///
  /// [animation] runs from 0 (hidden) to 1 (fully shown) and back on close.
  static Widget transition(Animation<double> animation, Widget child) {
    // Opening overshoots slightly (the "pop"); closing just eases out.
    final CurvedAnimation curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    // Fading must stay between 0 and 1, so it uses a curve without overshoot.
    final CurvedAnimation fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }

  /// Shows [dialog] with the app's animation and returns what it pops.
  ///
  /// With [dismissible] true the user can close it by tapping the dimmed
  /// background or pressing back.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget dialog,
    bool dismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      // Screen readers announce this when the dialog opens.
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor,
      transitionDuration: openDuration,
      transitionBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return transition(animation, child);
          },
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            // SafeArea + Center keep the dialog away from notches and
            // centered on any screen size.
            return SafeArea(child: Center(child: dialog));
          },
    );
  }

  /// Shows an [AppConfirmDialog] and returns `true` when the user confirms,
  /// `false` when they cancel, and `null` when they tap outside.
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    bool isDestructive = false,
  }) {
    return show<bool>(
      context: context,
      dialog: AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
      ),
    );
  }
}

/// A rounded confirmation card: icon, title, message and two buttons.
///
/// A destructive action (e.g. delete) gets a red icon and a red confirm
/// button, so the user notices that it cannot be undone.
class AppConfirmDialog extends StatelessWidget {
  /// Creates the card. Pops `true` on confirm and `false` on cancel.
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.isDestructive = false,
  });

  /// Bold heading.
  final String title;

  /// Explanation of what will happen.
  final String message;

  /// Text of the confirm button.
  final String confirmLabel;

  /// Colors the icon and confirm button red when true.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    // Red for destructive actions, the brand color otherwise.
    final Color accent = isDestructive ? colors.error : colors.primary;
    final Color accentBackground = isDestructive
        ? colors.errorContainer
        : colors.primaryContainer;

    // Material gives the card its surface color, elevation and rounded shape.
    return Material(
      color: colors.surfaceContainerHigh,
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        // Never wider than a phone dialog, even on desktop.
        constraints: const BoxConstraints(maxWidth: 380, minWidth: 280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Round icon badge at the top.
              CircleAvatar(
                radius: 28,
                backgroundColor: accentBackground,
                child: Icon(
                  isDestructive ? Icons.delete_outline : Icons.help_outline,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // Title.
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              // Explanation.
              Text(
                message,
                textAlign: TextAlign.center,
                // `apply` tints the standard body style (no new style needed).
                style: theme.textTheme.bodyMedium?.apply(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              // Cancel (left) and confirm (right) buttons, equally wide.
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isDestructive
                            ? colors.onError
                            : colors.onPrimary,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
