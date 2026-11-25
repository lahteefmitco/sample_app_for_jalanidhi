import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/app_theme.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/app_dialog.dart';

/// Tests the animated dialogs: the pop-in animation, the result values, the
/// destructive styling and the closing animation.
void main() {
  /// Result of the last dialog (`false` before any dialog was answered).
  bool? result;

  /// Opens a confirm dialog from a button, so a real route is pushed.
  Future<void> pumpDialogApp(
    WidgetTester tester, {
    bool isDestructive = false,
  }) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await AppDialog.confirm(
                      context: context,
                      title: 'Delete post?',
                      message: 'This cannot be undone.',
                      confirmLabel: 'Delete',
                      isDestructive: isDestructive,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The scale animation that wraps the dialog card.
  ScaleTransition cardScale(WidgetTester tester) {
    return tester.widget<ScaleTransition>(
      find
          .ancestor(
            of: find.byType(AppConfirmDialog),
            matching: find.byType(ScaleTransition),
          )
          .first,
    );
  }

  /// The confirm button's background color.
  Color? confirmColor(WidgetTester tester) {
    final FilledButton button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete'),
    );
    return button.style?.backgroundColor?.resolve(<WidgetState>{});
  }

  testWidgets('the card fades and pops in instead of appearing at once', (
    WidgetTester tester,
  ) async {
    await pumpDialogApp(tester);
    await tester.tap(find.text('open'));
    await tester.pump();

    // First frame: smaller than its final size.
    expect(cardScale(tester).scale.value, lessThan(1));

    // Sample the animation: it should overshoot 100 % a little ("pop")
    // and finish at exactly 100 %.
    final List<double> scales = <double>[];
    for (int i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      scales.add(cardScale(tester).scale.value);
    }
    expect(scales.any((double scale) => scale > 1), isTrue);
    await tester.pumpAndSettle();
    expect(cardScale(tester).scale.value, 1);
    expect(find.text('Delete post?'), findsOneWidget);
  });

  testWidgets('Confirm returns true and Cancel returns false', (
    WidgetTester tester,
  ) async {
    await pumpDialogApp(tester);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('tapping the dimmed background dismisses it with null', (
    WidgetTester tester,
  ) async {
    await pumpDialogApp(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 5)); // far from the card
    await tester.pumpAndSettle();

    expect(find.byType(AppConfirmDialog), findsNothing);
    expect(result, isNull);
  });

  testWidgets('closing plays an animation instead of vanishing at once', (
    WidgetTester tester,
  ) async {
    await pumpDialogApp(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Still on screen, shrinking and fading.
    expect(find.byType(AppConfirmDialog), findsOneWidget);
    expect(cardScale(tester).scale.value, lessThan(1));

    await tester.pumpAndSettle();
    expect(find.byType(AppConfirmDialog), findsNothing);
  });

  testWidgets(
    'a destructive dialog is red, a normal one uses the brand color',
    (WidgetTester tester) async {
      final ColorScheme colors = AppTheme.light().colorScheme;

      await pumpDialogApp(tester, isDestructive: true);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(confirmColor(tester), colors.error);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      await pumpDialogApp(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(confirmColor(tester), colors.primary);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    },
  );

  testWidgets('the card stays inside a narrow phone screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpDialogApp(tester);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(AppConfirmDialog)).width,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });

  test('ShowConfirmationEffect is not destructive unless asked', () {
    const ShowConfirmationEffect plain = ShowConfirmationEffect(
      actionId: 'a',
      title: 't',
      message: 'm',
    );
    const ShowConfirmationEffect danger = ShowConfirmationEffect(
      actionId: 'a',
      title: 't',
      message: 'm',
      isDestructive: true,
    );
    expect(plain.isDestructive, isFalse);
    expect(danger.isDestructive, isTrue);
    expect(danger.toString(), contains('isDestructive: true'));
  });
}
