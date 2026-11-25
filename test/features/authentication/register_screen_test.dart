import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/register_screen.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

import '../../helpers/in_memory_storage.dart';
import '../../helpers/pump_app.dart';

/// A mocktail mock of [AuthRepository]; each test decides what it returns.
class MockAuthRepository extends Mock implements AuthRepository {}

/// Widget tests for [RegisterScreen]: the four fields, required-field errors
/// and the "passwords do not match" error.
void main() {
  /// Mocked [AuthRepository]; each test decides what it returns.
  late MockAuthRepository auth;

  /// Shows [RegisterScreen] with a fresh mock [auth] repository.
  Future<void> pumpRegister(WidgetTester tester) {
    auth = MockAuthRepository();
    return pumpApp(
      tester,
      // Provides the RegisterCubit that RegisterScreen reads from the
      // context, using the mock repository and in-memory preferences.
      BlocProvider<RegisterCubit>(
        create: (BuildContext _) => RegisterCubit(
          authRepository: auth,
          preferences: InMemoryLocalStorage(),
        ),
        child: const RegisterScreen(),
      ),
      size: const Size(400, 900),
    );
  }

  testWidgets('shows the four fields and the register button', (
    WidgetTester tester,
  ) async {
    await pumpRegister(tester);
    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.text(AppStrings.createAccount), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, AppStrings.register),
      findsOneWidget,
    );
  });

  testWidgets('submitting an empty form shows an error under every field', (
    WidgetTester tester,
  ) async {
    await pumpRegister(tester);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.register));
    await tester.pump();
    expect(find.text(AppStrings.requiredField), findsNWidgets(4));
    verifyNever(
      () => auth.register(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('mismatching passwords are reported', (
    WidgetTester tester,
  ) async {
    await pumpRegister(tester);
    // Fields in order: name, email, password, confirm password.
    await tester.enterText(find.byType(TextField).at(0), 'Jane');
    await tester.enterText(find.byType(TextField).at(1), 'jane@mail.test');
    await tester.enterText(find.byType(TextField).at(2), 'secret1');
    await tester.enterText(find.byType(TextField).at(3), 'secret2');
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.register));
    await tester.pump();
    expect(find.text(AppStrings.passwordsDoNotMatch), findsOneWidget);
  });
}
