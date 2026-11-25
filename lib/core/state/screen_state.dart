import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';

/// Composite state of a screen: `buildState + listenerState + effectId`.
///
/// * [build] drives widget rebuilding (BlocBuilder / BlocSelector).
/// * [effect] is a one-time UI effect handled by a BlocListener.
/// * [effectId] is unique per emitted effect, so an old effect can never run
///   again when only the build state changes.
@immutable
class ScreenState<B> {
  /// Creates a state; by default it carries no effect and `effectId` 0.
  const ScreenState({required this.build, this.effect, this.effectId = 0});

  /// What the screen draws (the screen's own BuildState class).
  final B build;

  /// The last one-time effect, or null when there is none.
  final UiEffect? effect;

  /// Increases by one for every new effect, so the listener can tell a new
  /// effect from an old one that is still stored in [effect].
  final int effectId;

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'ScreenState(build: $build, effect: $effect, effectId: $effectId)';
}

/// `buildWhen` predicate: rebuild only when the BuildState instance changed
/// (effects reuse the same instance, so they never trigger a rebuild).
bool buildStateChanged<B>(ScreenState<B> previous, ScreenState<B> current) =>
    !identical(previous.build, current.build);
