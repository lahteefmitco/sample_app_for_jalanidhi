import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/app_theme.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/page_transitions.dart';

/// Tests the screen-change animation: forward = right to left, back = left to
/// right, on every platform.
void main() {
  /// Pumps an app whose first page can open a second page.
  Future<void> pumpTwoPages(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              // Text sits at the page's left edge, so its x position equals
              // the x offset of the whole page.
              body: Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (BuildContext context) => Scaffold(
                          appBar: AppBar(),
                          body: const Align(
                            alignment: Alignment.topLeft,
                            child: Text('Second'),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('First'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Left edge of the text [label], in logical pixels.
  double leftOf(WidgetTester tester, String label) {
    return tester.getTopLeft(find.text(label)).dx;
  }

  testWidgets(
    'forward: the new page slides in from the right towards the left',
    (WidgetTester tester) async {
      await pumpTwoPages(tester);
      final double firstRestingX = leftOf(tester, 'First');

      await tester.tap(find.text('First'));
      await tester.pump(); // animation starts
      await tester.pump(const Duration(milliseconds: 60));
      final double early = leftOf(tester, 'Second');
      await tester.pump(const Duration(milliseconds: 100));
      final double later = leftOf(tester, 'Second');

      // It starts at the right edge, then keeps moving left ...
      expect(early, greaterThan(0));
      expect(later, lessThan(early));
      expect(later, greaterThan(0));

      // ... while the page below is pushed a little to the left.
      expect(leftOf(tester, 'First'), lessThan(firstRestingX));

      // Finally the new page rests at x = 0.
      await tester.pumpAndSettle();
      expect(leftOf(tester, 'Second'), 0);
    },
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('backward: the page slides out from the left towards the right', (
    WidgetTester tester,
  ) async {
    await pumpTwoPages(tester);
    // Where the first page's text rests (the button has some padding).
    final double firstRestingX = leftOf(tester, 'First');
    await tester.tap(find.text('First'));
    await tester.pumpAndSettle();
    expect(leftOf(tester, 'Second'), 0);

    await tester.pageBack();
    await tester.pump(); // animation starts
    await tester.pump(const Duration(milliseconds: 60));
    final double early = leftOf(tester, 'Second');
    await tester.pump(const Duration(milliseconds: 100));
    final double later = leftOf(tester, 'Second');

    // It moves away to the RIGHT: x grows.
    expect(early, greaterThan(0));
    expect(later, greaterThan(early));

    // The page below slides back into place from the left.
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
    expect(leftOf(tester, 'First'), firstRestingX);
  }, variant: TargetPlatformVariant.all());

  test('the theme uses the slide builder on every platform', () {
    final PageTransitionsTheme transitions =
        AppTheme.light().pageTransitionsTheme;
    for (final TargetPlatform platform in TargetPlatform.values) {
      expect(
        transitions.builders[platform],
        isA<SlideRightToLeftTransitionsBuilder>(),
        reason: '$platform',
      );
    }
  });

  test('going back is a little faster than going forward', () {
    const SlideRightToLeftTransitionsBuilder builder =
        SlideRightToLeftTransitionsBuilder();
    expect(
      builder.reverseTransitionDuration,
      lessThan(builder.transitionDuration),
    );
  });
}
