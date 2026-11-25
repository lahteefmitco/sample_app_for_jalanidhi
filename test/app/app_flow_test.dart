import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/app.dart';
import 'package:sample_app_for_jalanidhi/app/app_config.dart';
import 'package:sample_app_for_jalanidhi/app/dependency_injection.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/storage/secure_storage_service.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/progress_dialog.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/widgets/home_menu_grid.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

import '../helpers/fake_backend.dart';
import '../helpers/in_memory_storage.dart';
import '../helpers/sample_data.dart';

/// Whole-app workflow with the real router, DI container, Cubits and
/// repositories; only the network and the storage are faked.
void main() {
  /// Fake JSONPlaceholder server, recreated before every test.
  late FakeBackend backend;

  // Before each test: fresh fake server and a fresh DI container that uses
  // it, plus in-memory storage instead of the device storage.
  setUp(() async {
    backend = FakeBackend(<String, RouteHandler>{
      'GET /users': (RequestOptions _) => usersJson,
      'GET /users/1/posts': (RequestOptions _) => postsJson
          .where((Map<String, dynamic> p) => p['userId'] == 1)
          .toList(),
      'GET /posts': (RequestOptions _) => postsJson,
      'GET /posts/1': (RequestOptions _) => postsJson.first,
      'GET /comments': (RequestOptions _) => commentsJson,
      'GET /todos': (RequestOptions _) => todosJson,
      'GET /albums': (RequestOptions _) => albumsJson,
      'POST /posts': (RequestOptions _) => <String, int>{'id': 101},
      'DELETE /posts/1': (RequestOptions _) => <String, dynamic>{},
    });
    await resetDependencies();
    await configureDependencies(
      const AppConfig(),
      localStorage: InMemoryLocalStorage(),
      secureStorage: InMemorySecureStorage(),
      dio: backend.createDio(),
    );
    ProgressDialog.hide();
  });

  // After each test: empty the DI container again.
  tearDown(resetDependencies);

  /// Starts the whole [App] on [route] with a fixed phone-sized screen.
  Future<void> pumpAppAt(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(App(initialRoute: route));
    await tester.pumpAndSettle();
  }

  /// Taps a navigation-menu tile (the summary cards share the same labels).
  Future<void> tapMenu(WidgetTester tester, String label) async {
    final Finder tile = find.descendant(
      of: find.byType(HomeMenuGrid),
      matching: find.text(label),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  testWidgets('login -> dashboard -> users -> user details -> back -> logout', (
    WidgetTester tester,
  ) async {
    // Real auth repository without the 400 ms simulated latency.
    getIt.unregister<AuthRepository>();
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepository(
        secureStorage: getIt<SecureStorageService>(),
        simulatedLatency: Duration.zero,
      ),
    );
    // Create the demo account so the correct password below works.
    await getIt<AuthRepository>().ensureDemoAccount();

    await pumpAppAt(tester, RouteNames.login);

    // Wrong password -> error snackbar, still on login.
    await tester.enterText(
      find.byType(TextField).at(0),
      AppConstants.demoEmail,
    );
    await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.login));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.invalidCredentials), findsOneWidget);
    expect(find.text(AppStrings.welcomeBack), findsOneWidget);

    // Correct password -> dashboard with the summary.
    await tester.enterText(
      find.byType(TextField).at(1),
      AppConstants.demoPassword,
    );
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.login));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, ${AppConstants.demoName}'), findsOneWidget);
    expect(find.text('45'), findsOneWidget); // posts
    expect(find.text('Charlie Brown'), findsNothing);

    // Users list -> details.
    await tapMenu(tester, AppStrings.users);
    await tester.pumpAndSettle();
    expect(find.text('Charlie Brown'), findsOneWidget);
    await tester.tap(find.text('Charlie Brown'));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.userDetails), findsOneWidget);
    expect(find.textContaining(AppStrings.userPosts), findsOneWidget);

    // Back twice -> dashboard; logout -> login (stack cleared).
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.logout));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.welcomeBack), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('posts: create, then delete from the details screen', (
    WidgetTester tester,
  ) async {
    await pumpAppAt(tester, RouteNames.postList);
    expect(find.text('Post title 1'), findsOneWidget);

    // Create.
    await tester.tap(find.text(AppStrings.newPost));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Brand new post');
    await tester.enterText(find.byType(TextField).at(1), 'With a body');
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
    await tester.pumpAndSettle();
    expect(find.text('Brand new post'), findsOneWidget);
    expect(find.text(AppStrings.postSaved), findsOneWidget);

    // Delete post 1 from its details screen (confirmation first).
    await tester.tap(find.text('Post title 1'));
    await tester.pumpAndSettle();
    expect(find.text('Comment 1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.confirmDeletePostTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();

    expect(backend.count('DELETE /posts/1'), 1);
    expect(find.text('Post title 1'), findsNothing);
    expect(find.text(AppStrings.postDeleted), findsOneWidget);
  });

  testWidgets('every other screen renders from the dashboard', (
    WidgetTester tester,
  ) async {
    await pumpAppAt(tester, RouteNames.home);
    // Menu label -> a text the opened screen must show.
    for (final MapEntry<String, String> entry in <String, String>{
      AppStrings.comments: 'Comment 1',
      AppStrings.todos: 'Todo 1',
      AppStrings.albums: 'Album 1',
    }.entries) {
      await tapMenu(tester, entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
