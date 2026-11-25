import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/progress_dialog.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/square_loader.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/login_screen.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/models/auth_user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

import '../../helpers/in_memory_storage.dart';
import '../../helpers/pump_app.dart';

/// A mocktail mock of [AuthRepository]; each test decides what it returns.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Widget tests for [LoginScreen]: the form, validation errors, the progress
/// dialog and error snackbar on bad credentials, the password toggle and the
/// layout on a wide window.
void main() {
  /// Mocked [AuthRepository]; each test decides what it returns.
  late MockAuthRepository auth;

  /// Shows [LoginScreen] in a window of [size] (a phone size by default).
  Future<void> pumpLogin(WidgetTester tester, {Size? size}) {
    final InMemoryLocalStorage preferences = InMemoryLocalStorage();
    return pumpApp(
      tester,
      // Provides the two cubits LoginScreen needs above it in the tree.
      // The app bar contains the theme switch, which needs ThemeCubit.
      BlocProvider<ThemeCubit>(
        create: (BuildContext _) => ThemeCubit(preferences: preferences),
        // The cubit that drives the login form itself.
        child: BlocProvider<LoginCubit>(
          create: (BuildContext _) =>
              LoginCubit(authRepository: auth, preferences: preferences),
          child: const LoginScreen(),
        ),
      ),
      size: size ?? const Size(400, 800),
    );
  }

  setUp(() {
    auth = MockAuthRepository();
    // The progress dialog is global; make sure no earlier test left it open.
    ProgressDialog.hide();
  });

  testWidgets('renders the form', (WidgetTester tester) async {
    await pumpLogin(tester);
    expect(find.text(AppStrings.welcomeBack), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, AppStrings.login), findsOneWidget);
  });

  testWidgets('empty submit shows field errors and never calls the API', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.login));
    await tester.pump();
    expect(find.text(AppStrings.requiredField), findsNWidgets(2));
    verifyNever(
      () => auth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('invalid credentials: progress is shown, hidden and an error '
      'snackbar appears', (WidgetTester tester) async {
    // Arrange: login waits on a Completer, so the test decides when (and
    // how) the request finishes.
    final Completer<AuthUserModel> completer = Completer<AuthUserModel>();
    when(
      () => auth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((Invocation _) => completer.future);

    // Act: fill the form and submit.
    await pumpLogin(tester);
    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.login));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // While the request is running, the progress dialog is visible.
    expect(find.byType(SquareLoader), findsOneWidget);
    expect(ProgressDialog.isShowing, isTrue);

    // Now let the request fail.
    completer.completeError(const AuthException(AppStrings.invalidCredentials));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert: the dialog is gone and the error snackbar is shown.
    expect(ProgressDialog.isShowing, isFalse);
    expect(find.byType(SquareLoader), findsNothing);
    expect(find.text(AppStrings.invalidCredentials), findsOneWidget);
  });

  testWidgets('password visibility toggle rebuilds only through the cubit', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    /// The password field (the second text field on the screen).
    TextField password() =>
        tester.widget<TextField>(find.byType(TextField).at(1));
    expect(password().obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(password().obscureText, isFalse);
  });

  testWidgets('layout stays within bounds on a wide desktop window', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester, size: const Size(1600, 900));
    expect(tester.takeException(), isNull);
    // The form keeps a maximum width instead of stretching across the window.
    final double width = tester.getSize(find.byType(TextField).first).width;
    expect(width, lessThanOrEqualTo(440));
  });
}
