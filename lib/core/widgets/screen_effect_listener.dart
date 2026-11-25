import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/app_dialog.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/app_snackbar.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/progress_dialog.dart';

/// Screen-specific effect handler passed as `onEffect`.
///
/// Return `true` from `onEffect` when a screen-specific effect was handled.
typedef EffectHandler = bool Function(BuildContext context, UiEffect effect);

/// BlocListener wrapper that executes the one-time UI effects of a screen
/// (progress, snackbars, navigation, dialogs, bottom sheets).
///
/// It also logs the screen lifecycle. It is a StatefulWidget only to hook
/// `initState`/`dispose`; it never calls `setState`.
///
/// `C` is the screen Cubit type and `B` its BuildState type.
class ScreenEffectListener<C extends ScreenCubit<B>, B> extends StatefulWidget {
  /// Wraps [child] and runs the effects emitted by the Cubit of type `C`.
  const ScreenEffectListener({
    super.key,
    required this.screenName,
    required this.child,
    this.onEffect,
  });

  /// Screen name used in logs, e.g. `UserListScreen`.
  final String screenName;

  /// The screen content.
  final Widget child;

  /// Optional handler for effects that only this screen understands.
  /// It runs first; return `true` to skip the default handling.
  final EffectHandler? onEffect;

  /// Creates the state object that does the listening.
  @override
  State<ScreenEffectListener<C, B>> createState() =>
      _ScreenEffectListenerState<C, B>();
}

/// State of [ScreenEffectListener]: logs the lifecycle and runs effects.
class _ScreenEffectListenerState<C extends ScreenCubit<B>, B>
    extends State<ScreenEffectListener<C, B>> {
  /// Logs that the screen appeared.
  @override
  void initState() {
    super.initState();
    screenLog('${widget.screenName} initialised', funtionName: 'initState');
  }

  /// Cleans up and logs that the screen went away.
  @override
  void dispose() {
    // Never leave a progress dialog behind if the screen goes away.
    ProgressDialog.hide();
    screenLog('${widget.screenName} disposed', funtionName: 'dispose');
    super.dispose();
  }

  /// Builds a [BlocListener] around the screen content.
  @override
  Widget build(BuildContext context) {
    // Listens to the screen Cubit `C` and runs each new effect once; it never
    // rebuilds anything (widget.child is returned as is).
    return BlocListener<C, ScreenState<B>>(
      // Run only when a *new* effect was emitted: the effectId guarantees an
      // old effect is never replayed when the build state changes.
      listenWhen: (ScreenState<B> previous, ScreenState<B> current) =>
          current.effect != null && previous.effectId != current.effectId,
      listener: (BuildContext context, ScreenState<B> state) =>
          _handle(context, state.effect!),
      child: widget.child,
    );
  }

  /// Runs one [effect]: the screen's own handler first, then the defaults.
  void _handle(BuildContext context, UiEffect effect) {
    // The screen handled it itself: nothing else to do.
    if (widget.onEffect?.call(context, effect) ?? false) return;

    // Pattern matching on the effect's class; inside each case `effect` is
    // already the matching subtype (e.g. ShowSnackbarEffect).
    switch (effect) {
      case ShowProgressEffect():
        ProgressDialog.show(context);
      case HideProgressEffect():
        ProgressDialog.hide();
      case ShowSnackbarEffect():
        AppSnackbar.show(context, effect.message, type: effect.type);
      case NavigateEffect():
        _navigate(context, effect);
      case PopEffect():
        Navigator.of(context).pop(effect.result);
      case ShowConfirmationEffect():
        _confirm(context, effect);
      case ShowInfoSheetEffect():
        _showInfoSheet(context, effect);
      default:
        generalLog(
          'Unhandled effect: $effect',
          funtionName: '${widget.screenName}._handle',
        );
    }
  }

  /// Opens a route as described by [effect] (push, replace or clear stack).
  void _navigate(BuildContext context, NavigateEffect effect) {
    screenLog(
      '${widget.screenName} -> ${effect.routeName} (${effect.mode.name})',
      funtionName: 'navigate',
    );
    final NavigatorState navigator = Navigator.of(context);
    // Read now: after an `await` the context may no longer be usable.
    final C cubit = context.read<C>();
    switch (effect.mode) {
      case NavigationStyle.push:
        navigator
            .pushNamed<Object?>(effect.routeName, arguments: effect.arguments)
            // Tell the Cubit what the opened page returned (if still open).
            .then((Object? result) {
              if (!cubit.isClosed) cubit.onNavigationReturn(result);
            });
      case NavigationStyle.replace:
        navigator.pushReplacementNamed<Object?, Object?>(
          effect.routeName,
          arguments: effect.arguments,
        );
      case NavigationStyle.clearStack:
        navigator.pushNamedAndRemoveUntil<Object?>(
          effect.routeName,
          // Returning false for every route removes all of them.
          (Route<dynamic> _) => false,
          arguments: effect.arguments,
        );
    }
  }

  /// Shows a confirm/cancel dialog and calls `onConfirmed` on "confirm".
  Future<void> _confirm(
    BuildContext context,
    ShowConfirmationEffect effect,
  ) async {
    // Read before the await: the context may be gone when the dialog closes.
    final C cubit = context.read<C>();
    // true = confirmed, false = cancelled, null = dismissed by tapping outside.
    // The animated card (fade + pop-in) comes from AppDialog.
    final bool? confirmed = await AppDialog.confirm(
      context: context,
      title: effect.title,
      message: effect.message,
      confirmLabel: effect.confirmLabel,
      isDestructive: effect.isDestructive,
    );
    if (confirmed == true && !cubit.isClosed) {
      cubit.onConfirmed(effect.actionId);
    }
  }

  /// Shows a bottom sheet with the title and label/value rows of [effect].
  void _showInfoSheet(BuildContext context, ShowInfoSheetEffect effect) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Never wider than a phone sheet, even on desktop/web.
      constraints: const BoxConstraints(maxWidth: 640),
      // Rounded top corners and a smooth slide-up.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      clipBehavior: Clip.antiAlias,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 350),
        reverseDuration: Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (BuildContext sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Sheet title.
              Text(
                effect.title,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              // One label + value block per field.
              for (final MapEntry<String, String> field in effect.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Small, tinted label.
                      Text(
                        field.key,
                        style: Theme.of(sheetContext).textTheme.labelMedium
                            ?.apply(
                              color: Theme.of(sheetContext).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      // The value itself.
                      Text(field.value),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
