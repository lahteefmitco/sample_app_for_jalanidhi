import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/progress_dialog.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/square_loader.dart';

import '../helpers/pump_app.dart';

/// Minimal Cubit used to drive the busy flag from the tests.
class _BusyCubit extends ScreenCubit<int> {
  /// Creates the Cubit with the build state `0`.
  _BusyCubit() : super(0, name: 'BusyCubit');
}

/// Tests for the busy flag, the guard that uses it, and the square loader.
void main() {
  // ---------------------------------------------------------------------------
  // The busy flag of ScreenCubit
  // ---------------------------------------------------------------------------
  group('ScreenCubit busy flag', () {
    test('showProgress / hideProgress turn the flag on and off', () {
      final _BusyCubit cubit = _BusyCubit();
      expect(cubit.isBusy, isFalse);
      cubit.showProgress();
      expect(cubit.isBusy, isTrue);
      cubit.hideProgress();
      expect(cubit.isBusy, isFalse);
      cubit.close();
    });

    test('a blocking request keeps the screen busy until it ends', () {
      final _BusyCubit cubit = _BusyCubit();
      final RequestToken token = cubit.startBlockingRequest('load');
      expect(cubit.isBusy, isTrue);
      cubit.endBlockingRequest(token);
      expect(cubit.isBusy, isFalse);
      cubit.close();
    });

    test('a replaced request must not clear the busy flag of the new one', () {
      final _BusyCubit cubit = _BusyCubit();
      final RequestToken first = cubit.startBlockingRequest('load');
      final RequestToken second = cubit.startBlockingRequest('load');
      // The first request finishes (it was cancelled): still busy.
      cubit.endBlockingRequest(first);
      expect(cubit.isBusy, isTrue);
      cubit.endBlockingRequest(second);
      expect(cubit.isBusy, isFalse);
      cubit.close();
    });

    test('changing the flag does not emit a new state', () {
      final _BusyCubit cubit = _BusyCubit();
      int emitted = 0;
      cubit.stream.listen((_) => emitted++);
      cubit.setBusy(true);
      cubit.setBusy(false);
      expect(emitted, 0);
      cubit.close();
    });

    test('setBusy after close is ignored instead of crashing', () async {
      final _BusyCubit cubit = _BusyCubit();
      await cubit.close();
      expect(() => cubit.setBusy(true), returnsNormally);
    });
  });

  // ---------------------------------------------------------------------------
  // BusyGuard
  // ---------------------------------------------------------------------------
  group('BusyGuard', () {
    late _BusyCubit cubit;
    int taps = 0;

    /// Shows a button inside a [BusyGuard] driven by [cubit].
    Future<void> pumpGuard(WidgetTester tester) async {
      taps = 0;
      await pumpApp(
        tester,
        BlocProvider<_BusyCubit>.value(
          // Provides the Cubit that BusyGuard reads the busy flag from.
          value: cubit,
          child: Scaffold(
            body: BusyGuard<_BusyCubit, int>(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Save'),
              ),
            ),
          ),
        ),
      );
    }

    setUp(() => cubit = _BusyCubit());
    tearDown(() => cubit.close());

    testWidgets('lets taps through while idle', (WidgetTester tester) async {
      await pumpGuard(tester);
      await tester.tap(find.text('Save'));
      expect(taps, 1);
    });

    testWidgets('blocks taps while busy and works again afterwards', (
      WidgetTester tester,
    ) async {
      await pumpGuard(tester);

      cubit.setBusy(true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'), warnIfMissed: false);
      expect(taps, 0);

      cubit.setBusy(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      expect(taps, 1);
    });

    testWidgets('dims the content while busy', (WidgetTester tester) async {
      await pumpGuard(tester);
      double opacity() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
      expect(opacity(), 1);
      cubit.setBusy(true);
      await tester.pump();
      expect(opacity(), lessThan(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Square loader
  // ---------------------------------------------------------------------------
  group('SquareLoader', () {
    /// Name of the Lottie asset that the loader currently shows.
    String shownAsset(WidgetTester tester) {
      // `Lottie.asset(...)` creates a LottieBuilder that knows its provider.
      final LottieBuilder builder = tester.widget<LottieBuilder>(
        find.byType(LottieBuilder),
      );
      return (builder.lottie as AssetLottie).assetName;
    }

    Future<void> pumpLoader(WidgetTester tester, Brightness brightness) {
      return tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(body: SquareLoader()),
        ),
      );
    }

    testWidgets('uses white squares in dark mode', (WidgetTester tester) async {
      await pumpLoader(tester, Brightness.dark);
      expect(shownAsset(tester), SquareLoader.darkAsset);
    });

    testWidgets('uses dark squares in light mode', (WidgetTester tester) async {
      await pumpLoader(tester, Brightness.light);
      expect(shownAsset(tester), SquareLoader.lightAsset);
    });

    testWidgets('CommonLoader is the square loader, not a spinner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CommonLoader())),
      );
      expect(find.byType(SquareLoader), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the progress dialog shows the square loader and no spinner', (
      WidgetTester tester,
    ) async {
      ProgressDialog.hide();
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => ProgressDialog.show(context),
                child: const Text('show'),
              ),
            );
          },
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SquareLoader), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      ProgressDialog.hide();
      await tester.pumpAndSettle();
    });

    testWidgets('the screen under the progress dialog cannot be tapped', (
      WidgetTester tester,
    ) async {
      ProgressDialog.hide();
      int taps = 0;
      late BuildContext screenContext;
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) {
            screenContext = context;
            return Scaffold(
              body: TextButton(
                onPressed: () => taps++,
                child: const Text('under'),
              ),
            );
          },
        ),
      );
      ProgressDialog.show(screenContext);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('under'), warnIfMissed: false);
      expect(taps, 0);
      ProgressDialog.hide();
      await tester.pumpAndSettle();
    });
  });
}
