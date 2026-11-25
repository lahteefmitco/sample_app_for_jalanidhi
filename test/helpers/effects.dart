import 'dart:async';

import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';

/// Runs [action] and returns every one-time effect [cubit] emitted meanwhile.
///
/// Use it to check which snackbars, dialogs or navigations a Cubit asked for,
/// e.g. `await collectEffects(cubit, () => cubit.submit())`.
Future<List<UiEffect>> collectEffects(
  ScreenCubit<dynamic> cubit,
  FutureOr<void> Function() action,
) async {
  // Record every effect that appears in a new state while [action] runs.
  final List<UiEffect> effects = <UiEffect>[];
  final StreamSubscription<ScreenState<dynamic>> subscription = cubit.stream
      .listen((ScreenState<dynamic> state) {
        if (state.effect != null) effects.add(state.effect!);
      });
  await action();
  // Fire-and-forget Cubit methods (e.g. onConfirmed) keep running after
  // [action] returns, so wait until no new state arrived for a while.
  int seen = -1;
  int quietRounds = 0;
  int rounds = 0;
  while (quietRounds < 5 && rounds++ < 400) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final int total = effects.length + cubit.state.effectId;
    quietRounds = total == seen ? quietRounds + 1 : 0;
    seen = total;
  }
  await subscription.cancel();
  return effects;
}
