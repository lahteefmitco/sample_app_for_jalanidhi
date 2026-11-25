import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/app.dart';
import 'package:sample_app_for_jalanidhi/app/app_config.dart';
import 'package:sample_app_for_jalanidhi/app/dependency_injection.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/global/widgets/theme_mode_button.dart';

import '../helpers/fake_backend.dart';
import '../helpers/in_memory_storage.dart';
import '../helpers/sample_data.dart';

/// The theme switch wired into the real app (App + GetIt + ThemeCubit).
///
/// Checks the default "system" theme, forcing Night / Day, saving the
/// choice, and restoring it at start-up.
void main() {
  /// Fake local storage where the theme choice is saved.
  late InMemoryLocalStorage preferences;

  /// Sets up DI with a fake server and [preferences], then starts the whole
  /// [App] on the home screen.
  Future<void> pumpApp(WidgetTester tester) async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      'GET /users': (RequestOptions _) => usersJson,
      'GET /posts': (RequestOptions _) => postsJson,
      'GET /comments': (RequestOptions _) => commentsJson,
      'GET /todos': (RequestOptions _) => todosJson,
      'GET /albums': (RequestOptions _) => albumsJson,
    });
    await resetDependencies();
    await configureDependencies(
      const AppConfig(),
      localStorage: preferences,
      secureStorage: InMemorySecureStorage(),
      dio: backend.createDio(),
    );
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const App(initialRoute: RouteNames.home));
    await tester.pumpAndSettle();
  }

  /// The brightness (light / dark) of the theme currently on screen.
  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(ThemeModeButton))).brightness;

  /// Opens the theme menu and picks the entry called [label].
  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  // Each test starts with empty preferences and ends with an empty DI
  // container.
  setUp(() => preferences = InMemoryLocalStorage());
  tearDown(resetDependencies);

  testWidgets('default is the system theme: follows the device brightness', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    expect(brightness(tester), Brightness.dark);

    // Act: the device switches to light mode while the app is open.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(tester), Brightness.light);
  });

  testWidgets('the user can force Night and Day from the home app bar', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    expect(brightness(tester), Brightness.light);

    await choose(tester, AppStrings.themeDark);
    expect(brightness(tester), Brightness.dark);
    expect(preferences.getString(StorageKeys.themeMode), 'dark');

    await choose(tester, AppStrings.themeLight);
    expect(brightness(tester), Brightness.light);

    await choose(tester, AppStrings.themeSystem);
    expect(preferences.getString(StorageKeys.themeMode), 'system');
  });

  testWidgets('a saved choice is applied at start-up', (
    WidgetTester tester,
  ) async {
    // Arrange: pretend the user chose "dark" in an earlier session.
    preferences.values[StorageKeys.themeMode] = 'dark';
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    expect(brightness(tester), Brightness.dark);
  });

  testWidgets('the switch is also available on the login screen', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{});
    await resetDependencies();
    await configureDependencies(
      const AppConfig(),
      localStorage: preferences,
      secureStorage: InMemorySecureStorage(),
      dio: backend.createDio(),
    );
    await tester.pumpWidget(const App(initialRoute: RouteNames.login));
    await tester.pumpAndSettle();
    expect(find.byType(ThemeModeButton), findsOneWidget);
  });

  testWidgets('the first page has no back arrow (single initial route)', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{});
    await resetDependencies();
    await configureDependencies(
      const AppConfig(),
      localStorage: preferences,
      secureStorage: InMemorySecureStorage(),
      dio: backend.createDio(),
    );
    await tester.pumpWidget(const App(initialRoute: RouteNames.login));
    await tester.pumpAndSettle();
    // No page below the login page, so nothing to go back to.
    expect(find.byType(BackButton), findsNothing);
    expect(find.textContaining('Unknown route'), findsNothing);
  });
}
