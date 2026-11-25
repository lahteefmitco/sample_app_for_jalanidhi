import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/app.dart';
import 'package:sample_app_for_jalanidhi/app/app_config.dart';
import 'package:sample_app_for_jalanidhi/app/dependency_injection.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/register_screen.dart';

import '../helpers/fake_backend.dart';
import '../helpers/in_memory_storage.dart';

/// The slide animation inside the real app (real router and theme).
void main() {
  setUp(() async {
    await resetDependencies();
    await configureDependencies(
      const AppConfig(),
      localStorage: InMemoryLocalStorage(),
      secureStorage: InMemorySecureStorage(),
      dio: FakeBackend(<String, RouteHandler>{}).createDio(),
    );
  });

  tearDown(resetDependencies);

  testWidgets('login -> register slides in from the right, back slides out '
      'to the right', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const App(initialRoute: RouteNames.login));
    await tester.pumpAndSettle();

    /// Left edge of the register page, in logical pixels.
    double registerX() => tester.getTopLeft(find.byType(RegisterScreen)).dx;

    // Forward: the register page starts at the right edge and moves left.
    await tester.tap(find.text(AppStrings.noAccountYet));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final double forwardEarly = registerX();
    await tester.pump(const Duration(milliseconds: 100));
    expect(forwardEarly, greaterThan(0));
    expect(registerX(), lessThan(forwardEarly));
    await tester.pumpAndSettle();
    expect(registerX(), 0);

    // Backward: the register page leaves towards the right.
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final double backEarly = registerX();
    await tester.pump(const Duration(milliseconds: 100));
    expect(backEarly, greaterThan(0));
    expect(registerX(), greaterThan(backEarly));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
  });
}
