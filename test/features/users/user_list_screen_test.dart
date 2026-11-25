import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/responsive_list_grid.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/square_loader.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/user_list_screen.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sample_data.dart';

/// Widget tests for [UserListScreen]: loading, search, city filter, sorting,
/// error + retry, and the responsive layout on phone and desktop sizes.
void main() {
  /// Shows [UserListScreen] at [size] and waits until it has loaded.
  ///
  /// [usersHandler] replaces the default `GET /users` answer (for errors).
  Future<FakeBackend> pumpUsers(
    WidgetTester tester, {
    Size size = const Size(400, 800),
    RouteHandler? usersHandler,
  }) async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      'GET /users': usersHandler ?? (RequestOptions _) => usersJson,
    });
    await pumpApp(
      tester,
      // Provides the UserListCubit that UserListScreen reads from the
      // context; `..load()` starts fetching the users right away.
      BlocProvider<UserListCubit>(
        create: (BuildContext _) => UserListCubit(
          userRepository: UserRepository(backend.createClient()),
        )..load(),
        child: const UserListScreen(),
      ),
      size: size,
    );
    await tester.pumpAndSettle();
    return backend;
  }

  testWidgets('shows a loader first, then the users', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      'GET /users': (RequestOptions _) => usersJson,
    });
    // Same setup as pumpUsers, but without waiting, so the loader is visible.
    await pumpApp(
      tester,
      // Provides the UserListCubit that UserListScreen reads.
      BlocProvider<UserListCubit>(
        create: (BuildContext _) => UserListCubit(
          userRepository: UserRepository(backend.createClient()),
        )..load(),
        child: const UserListScreen(),
      ),
    );
    expect(find.byType(SquareLoader), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Bob Jones'), findsOneWidget);
    expect(find.text('Charlie Brown'), findsOneWidget);
  });

  testWidgets('typing in the search field filters the list', (
    WidgetTester tester,
  ) async {
    await pumpUsers(tester);
    await tester.enterText(find.byType(TextField), 'alice');
    await tester.pump();
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Bob Jones'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump();
    expect(find.text(AppStrings.noUsers), findsOneWidget);

    // The clear (x) button empties the search and shows everyone again.
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(find.text('Bob Jones'), findsOneWidget);
  });

  testWidgets('city chips filter the list', (WidgetTester tester) async {
    await pumpUsers(tester);
    final Finder chip = find.widgetWithText(ChoiceChip, 'Metropolis');
    await tester.ensureVisible(chip); // the chip row scrolls horizontally
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pump();
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Bob Jones'), findsNothing);
  });

  testWidgets('sort menu changes the order', (WidgetTester tester) async {
    await pumpUsers(tester);

    /// The vertical position of the user called [name] on the screen.
    double top(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(top('Alice Smith'), lessThan(top('Charlie Brown')));

    // Open the sort menu and pick "Name (Z-A)".
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name (Z-A)').last);
    await tester.pumpAndSettle();
    expect(top('Charlie Brown'), lessThan(top('Alice Smith')));
  });

  testWidgets('API failure shows the error view and a snackbar; retry works', (
    WidgetTester tester,
  ) async {
    // Arrange: the users request fails while `fail` is true.
    bool fail = true;
    await pumpUsers(
      tester,
      usersHandler: (RequestOptions options) {
        if (fail) {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }
        return usersJson;
      },
    );
    expect(find.text(AppStrings.networkError), findsWidgets);
    expect(find.byType(SnackBar), findsOneWidget);

    // Act: the network "comes back", then the user taps retry.
    fail = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text('Alice Smith'), findsOneWidget);
  });

  testWidgets('responsive: one column on phones, several on desktop', (
    WidgetTester tester,
  ) async {
    // Phone size: users are stacked, so they share the same x position.
    await pumpUsers(tester);
    expect(
      tester.getTopLeft(find.text('Alice Smith')).dx,
      tester.getTopLeft(find.text('Bob Jones')).dx,
    );

    // Desktop size: a grid puts users side by side on the same row.
    await pumpUsers(tester, size: const Size(1400, 900));
    expect(find.byType(ResponsiveListGrid), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Alice Smith')).dy,
      tester.getTopLeft(find.text('Bob Jones')).dy,
    ); // same row
    expect(tester.takeException(), isNull);
  });
}
