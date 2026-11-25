import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_exception.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';

/// Base class of every screen Cubit.
///
/// It gives each screen Cubit three things:
///
/// 1. **Two output channels**
///    * [emitBuild] - a new BuildState: widgets rebuild, the old effect is
///      cleared.
///    * [emitEffect] - a one-time UiEffect (snackbar, navigation, dialog …)
///      with a new `effectId`; the build state instance is reused, so
///      builders do not rebuild.
///    Cubits never navigate or show UI themselves; they only emit effects.
///
/// 2. **Request cancellation** - [newRequestToken] hands out tokens that are
///    cancelled automatically when a newer request with the same purpose
///    starts, and all of them are cancelled when the Cubit is closed (the
///    screen left the navigation stack).
///
/// 3. **A "busy" flag** - [busyListenable] / [isBusy] is `true` while a
///    request is in progress. `BusyGuard` disables the screen body while it
///    is true, and write actions (POST / PUT / PATCH / DELETE) refuse to start
///    when [isBusy] is already true, so a request can never be sent twice.
///
/// 4. **Small helpers** for progress, snackbars and navigation.
///
/// `B` is the BuildState type of the screen, e.g. `UserListBuildState`.
abstract class ScreenCubit<B> extends Cubit<ScreenState<B>> {
  /// Starts the Cubit with [initialBuild] and no effect.
  ///
  /// [name] is only used in logs (e.g. `UserListCubit`).
  ScreenCubit(B initialBuild, {required this.name})
    : super(ScreenState<B>(build: initialBuild)) {
    cubitLog('$name created', funtionName: 'init');
  }

  /// Name used in logs, e.g. `UserListCubit`.
  final String name;

  /// Requests that may still be running, keyed by their purpose
  /// (for example `'load'`).
  final Map<String, RequestToken> _requestTokens = <String, RequestToken>{};

  /// Holds the busy flag. It is a separate notifier (not part of the build
  /// state) so that toggling it never rebuilds or re-emits the screen state.
  final ValueNotifier<bool> _busy = ValueNotifier<bool>(false);

  /// Lets `BusyGuard` rebuild when the busy flag changes.
  ValueListenable<bool> get busyListenable => _busy;

  /// `true` while a request is in progress (see [setBusy]).
  ///
  /// Write actions start with `if (isBusy) return;` so they cannot run twice.
  bool get isBusy => _busy.value;

  /// Marks the screen busy or idle. Ignored after the Cubit was closed.
  void setBusy(bool value) {
    if (isClosed) {
      return;
    }
    _busy.value = value;
  }

  /// The current BuildState (shortcut for `state.build`).
  B get build => state.build;

  /// Emits a new BuildState. Widgets that render it will rebuild.
  ///
  /// Does nothing after the Cubit was closed (e.g. a request finished after
  /// the user left the screen).
  void emitBuild(B build) {
    if (isClosed) {
      return;
    }
    emit(ScreenState<B>(build: build, effectId: state.effectId));
  }

  /// Emits a one-time [effect] (handled by `ScreenEffectListener`).
  ///
  /// The effect gets a new id so the listener runs it exactly once.
  void emitEffect(UiEffect effect) {
    if (isClosed) {
      return;
    }
    emit(
      ScreenState<B>(
        build: state.build,
        effect: effect,
        effectId: state.effectId + 1,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Request cancellation
  // ---------------------------------------------------------------------------

  /// Returns a fresh [RequestToken] for [purpose] and cancels the previous
  /// request that had the same purpose.
  ///
  /// Example: pull-to-refresh calls `load()` while an earlier `load()` is still
  /// running; the earlier request is cancelled so its (older) result can
  /// never overwrite the newer one.
  ///
  /// Use it for requests that only READ data. Writes (create, update, delete)
  /// are deliberately not cancelled: the server may already have applied
  /// them, and the user expects them to finish.
  RequestToken newRequestToken(String purpose) {
    final RequestToken? previous = _requestTokens[purpose];
    previous?.cancel('$name: replaced by a newer "$purpose" request');
    final RequestToken token = RequestToken();
    _requestTokens[purpose] = token;
    return token;
  }

  /// Like [newRequestToken], and also marks the screen busy.
  ///
  /// Use it for the main READ request of a screen (the initial load or a
  /// refresh): while it runs the screen body is disabled by `BusyGuard`.
  /// Always finish it with [endBlockingRequest] in a `finally` block.
  RequestToken startBlockingRequest(String purpose) {
    final RequestToken token = newRequestToken(purpose);
    setBusy(true);
    return token;
  }

  /// Marks the screen idle again after [startBlockingRequest].
  ///
  /// A [token] that was cancelled is ignored: either the Cubit was closed, or
  /// a newer request replaced it and that newer request is now responsible
  /// for clearing the busy flag.
  void endBlockingRequest(RequestToken token) {
    if (!token.isCancelled) {
      setBusy(false);
    }
  }

  /// Cancels every request this Cubit started with [newRequestToken].
  void cancelAllRequests([String reason = 'requests cancelled']) {
    for (final RequestToken token in _requestTokens.values) {
      token.cancel('$name: $reason');
    }
    _requestTokens.clear();
  }

  /// `true` when [error] only means "the request was cancelled on purpose".
  ///
  /// Cancellation is not a failure: Cubits must not show an error for it.
  bool isCancellation(Object error) {
    return error is ApiException && error.type == ApiErrorType.cancelled;
  }

  // ---------------------------------------------------------------------------
  // Effect helpers
  // ---------------------------------------------------------------------------

  /// Shows the modal square loader and marks the screen busy.
  ///
  /// Call it right before a write request (POST / PUT / PATCH / DELETE).
  void showProgress() {
    setBusy(true);
    emitEffect(const ShowProgressEffect());
  }

  /// Hides the modal square loader and marks the screen idle again.
  ///
  /// Call it when the write request finished, whether it succeeded or failed.
  void hideProgress() {
    setBusy(false);
    emitEffect(const HideProgressEffect());
  }

  /// Shows a red snackbar with a user-friendly message for [error].
  void showError(Object error) {
    emitEffect(
      ShowSnackbarEffect(
        ErrorHandler.messageFor(error),
        type: SnackbarType.error,
      ),
    );
  }

  /// Shows a red snackbar with [message].
  void showErrorMessage(String message) {
    emitEffect(ShowSnackbarEffect(message, type: SnackbarType.error));
  }

  /// Shows a green snackbar with [message].
  void showSuccessMessage(String message) {
    emitEffect(ShowSnackbarEffect(message, type: SnackbarType.success));
  }

  /// Asks the screen to open [routeName] (see `RouteNames`).
  void navigateTo(
    String routeName, {
    Object? arguments,
    NavigationStyle mode = NavigationStyle.push,
  }) {
    emitEffect(NavigateEffect(routeName, arguments: arguments, mode: mode));
  }

  // ---------------------------------------------------------------------------
  // Hooks called by ScreenEffectListener
  // ---------------------------------------------------------------------------

  /// Called after the user confirms a [ShowConfirmationEffect].
  /// Override it to run the confirmed action (e.g. delete).
  void onConfirmed(String actionId) {}

  /// Called when a page opened by a [NavigateEffect] is closed again.
  /// [result] is the value that page returned (e.g. `'saved'`).
  void onNavigationReturn(Object? result) {}

  /// Cancels the screen's running requests, then closes the Cubit.
  ///
  /// `BlocProvider` calls this automatically when the route is removed.
  @override
  Future<void> close() {
    cancelAllRequests('screen closed');
    _busy.dispose();
    cubitLog('$name closed', funtionName: 'close');
    return super.close();
  }
}
