import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';

/// Smallest possible [ScreenCubit]: its build state is just an int.
class _Counter extends ScreenCubit<int> {
  /// Starts at 0.
  _Counter() : super(0, name: 'Counter');
}

/// Tests for the shared [ScreenCubit] base class: build state vs one-time
/// effects, effect ids, and behaviour after the Cubit is closed.
void main() {
  blocTest<_Counter, dynamic>(
    'emitBuild changes the build state and clears the effect',
    build: _Counter.new,
    act: (_Counter cubit) {
      cubit.showSuccessMessage('hi');
      cubit.emitBuild(5);
    },
    verify: (_Counter cubit) {
      expect(cubit.state.build, 5);
      expect(cubit.state.effect, isNull);
      expect(cubit.state.effectId, 1); // id is kept, effect is gone
    },
  );

  test('every effect gets a new id and reuses the build state instance', () {
    final _Counter cubit = _Counter();
    final int initial = cubit.state.build;
    cubit.showProgress();
    // Act: emit two effects in a row and keep each resulting state.
    final ScreenState<int> first = cubit.state;
    cubit.hideProgress();
    final ScreenState<int> second = cubit.state;
    expect(first.effect, isA<ShowProgressEffect>());
    expect(second.effect, isA<HideProgressEffect>());
    expect(second.effectId, first.effectId + 1);
    expect(identical(first.build, initial), isTrue);
    cubit.close();
  });

  test('closed cubits ignore late emissions', () async {
    final _Counter cubit = _Counter();
    await cubit.close();
    expect(() => cubit.emitBuild(1), returnsNormally);
    expect(() => cubit.showProgress(), returnsNormally);
  });
}
