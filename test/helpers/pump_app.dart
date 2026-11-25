import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sizer/sizer.dart';

/// Pumps [home] inside Sizer + MaterialApp (Sizer must wrap every screen
/// that uses `.w/.h/.sp`).
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(400, 800),
}) async {
  // Give the test screen a fixed size and reset it after the test.
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    Sizer(
      builder: (
        BuildContext context,
        Orientation orientation,
        ScreenType screenType,
      ) => MaterialApp(home: home),
    ),
  );
}
