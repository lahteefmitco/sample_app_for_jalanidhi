import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/progress_dialog.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/square_loader.dart';

import '../helpers/pump_app.dart';

/// Minimal Cubit used to drive the listener from the test.
class _TestCubit extends ScreenCubit<int> {
  /// Starts with build state 0.
  _TestCubit() : super(0, name: 'TestCubit');

  /// Action ids the user confirmed in a confirmation dialog.
  final List<String> confirmed = <String>[];

  /// Results handed back when a pushed route was popped.
  final List<Object?> returned = <Object?>[];

  /// Records the confirmed [actionId] instead of doing real work.
  @override
  void onConfirmed(String actionId) => confirmed.add(actionId);

  /// Records the [result] of the route that was closed.
  @override
  void onNavigationReturn(Object? result) => returned.add(result);
}

/// Widget tests for [ScreenEffectListener]: how one-time effects (snackbars,
/// progress dialog, confirmations, info sheets, navigation) are shown, and
/// that effects never rebuild the screen's widgets.
void main() {
  /// The Cubit that drives the listener, recreated before every test.
  late _TestCubit cubit;

  /// How many times the screen body was rebuilt.
  int builds = 0;

  /// Pumps a test screen wrapped in a [ScreenEffectListener]. [onEffect] lets
  /// a test handle effects itself, like a real screen can.
  Future<void> pumpListener(WidgetTester tester, {EffectHandler? onEffect}) {
    builds = 0;
    return pumpApp(
      tester,
      // Provides the test's [cubit] to the listener and the builder below.
      BlocProvider<_TestCubit>.value(
        value: cubit,
        child: ScreenEffectListener<_TestCubit, int>(
          screenName: 'TestScreen',
          onEffect: onEffect,
          child: Scaffold(
            // Rebuilds only when the build state changes (not for effects)
            // and counts every rebuild in [builds].
            body: BlocBuilder<_TestCubit, ScreenState<int>>(
              buildWhen: buildStateChanged,
              builder: (BuildContext context, ScreenState<int> state) {
                builds++;
                return Text('value ${state.build}');
              },
            ),
          ),
        ),
      ),
    );
  }

  // Each test starts with no progress dialog and a fresh Cubit.
  setUp(() {
    ProgressDialog.hide();
    cubit = _TestCubit();
  });

  tearDown(() => cubit.close());

  testWidgets('snackbar effects show their message', (
    WidgetTester tester,
  ) async {
    await pumpListener(tester);
    cubit.showSuccessMessage('Saved!');
    await tester.pump();
    expect(find.text('Saved!'), findsOneWidget);

    cubit.showErrorMessage('Broken');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Broken'), findsOneWidget);
  });

  testWidgets('progress is shown once, hidden on request, never duplicated', (
    WidgetTester tester,
  ) async {
    await pumpListener(tester);
    cubit.showProgress();
    await tester.pump();
    cubit.showProgress(); // a second request must not stack a second dialog
    await tester.pump();
    expect(find.byType(SquareLoader), findsOneWidget);

    cubit.hideProgress();
    await tester.pumpAndSettle();
    expect(find.byType(SquareLoader), findsNothing);
    expect(ProgressDialog.isShowing, isFalse);
  });

  testWidgets('effects do not rebuild the widgets, build changes do', (
    WidgetTester tester,
  ) async {
    await pumpListener(tester);
    final int initialBuilds = builds;
    // An effect alone must not rebuild the body...
    cubit.showSuccessMessage('hi');
    await tester.pump();
    expect(builds, initialBuilds);

    // ...but a new build state must.
    cubit.emitBuild(5);
    await tester.pump();
    expect(builds, initialBuilds + 1);
    expect(find.text('value 5'), findsOneWidget);
  });

  testWidgets('an old effect is not replayed when the build state changes', (
    WidgetTester tester,
  ) async {
    await pumpListener(tester);
    cubit.showSuccessMessage('only once');
    await tester.pump();
    // Dismiss the snackbar, then change the build state twice.
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();

    cubit.emitBuild(1);
    cubit.emitBuild(2);
    await tester.pumpAndSettle();
    expect(find.text('only once'), findsNothing);
  });

  testWidgets('confirmation: Cancel does nothing, Confirm calls the Cubit', (
    WidgetTester tester,
  ) async {
    await pumpListener(tester);
    const ShowConfirmationEffect effect = ShowConfirmationEffect(
      actionId: 'do-it',
      title: 'Sure?',
      message: 'Really?',
      confirmLabel: 'Yes',
    );

    // First time: the user taps Cancel.
    cubit.emitEffect(effect);
    await tester.pumpAndSettle();
    expect(find.text('Sure?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cubit.confirmed, isEmpty);

    // Second time: the user taps the confirm button.
    cubit.emitEffect(effect);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(cubit.confirmed, <String>['do-it']);
  });

  testWidgets('info sheet lists the label/value pairs', (
    WidgetTester tester,
  ) async {
    await pumpListener(tester);
    cubit.emitEffect(
      const ShowInfoSheetEffect(
        title: 'Details',
        fields: <MapEntry<String, String>>[
          MapEntry<String, String>('Name', 'Alice'),
          MapEntry<String, String>('City', 'Paris'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
  });

  testWidgets('screen-specific effects can be handled by the screen', (
    WidgetTester tester,
  ) async {
    // The effect our custom handler received.
    UiEffect? handled;
    await pumpListener(
      tester,
      onEffect: (BuildContext context, UiEffect effect) {
        handled = effect;
        return true; // consumed: the default handling must be skipped
      },
    );
    cubit.showSuccessMessage('custom');
    await tester.pump();
    expect(handled, isA<ShowSnackbarEffect>());
    expect(find.text('custom'), findsNothing);
  });

  testWidgets('NavigateEffect pushes the route and reports the result back', (
    WidgetTester tester,
  ) async {
    // Arguments of every '/next' route that was pushed.
    final List<String> pushed = <String>[];
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // A tiny app with two routes: the home screen (with the listener) and
    // '/next', which pops with the result 'done'.
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/next') pushed.add('${settings.arguments}');
          return MaterialPageRoute<String>(
            settings: settings,
            builder: (BuildContext context) => settings.name == '/next'
                ? Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).pop('done'),
                      child: const Text('close'),
                    ),
                  )
                // Provides the test's [cubit] to the listener on the home
                // route.
                : BlocProvider<_TestCubit>.value(
                    value: cubit,
                    child: const ScreenEffectListener<_TestCubit, int>(
                      screenName: 'Home',
                      child: Scaffold(body: Text('home')),
                    ),
                  ),
          );
        },
      ),
    );

    cubit.navigateTo('/next', arguments: 42);
    await tester.pumpAndSettle();
    expect(pushed, <String>['42']);

    // Closing '/next' must hand 'done' back to the Cubit.
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(cubit.returned, <String>['done']);
  });
}
