import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_state.dart';
import 'package:sample_app_for_jalanidhi/global/widgets/theme_mode_button.dart';

import '../helpers/in_memory_storage.dart';

/// Widget tests for [ThemeModeButton]: its icon, its menu with three
/// choices, and that picking a choice changes the app theme.
void main() {
  /// Fake local storage where the theme choice is saved.
  late InMemoryLocalStorage preferences;

  /// The real [ThemeCubit] the button talks to.
  late ThemeCubit cubit;

  /// Pumps a tiny app with the [ThemeModeButton] in the middle.
  Future<void> pumpButton(WidgetTester tester) async {
    await tester.pumpWidget(
      // Provides the test's [cubit] so ThemeModeButton can find it with
      // `context.read<ThemeCubit>()`.
      BlocProvider<ThemeCubit>.value(
        value: cubit,
        // Rebuilds MaterialApp with the new theme mode whenever the Cubit
        // emits, like the real app does.
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (BuildContext context, ThemeState state) => MaterialApp(
            themeMode: state.mode,
            theme: ThemeData(brightness: Brightness.light),
            darkTheme: ThemeData(brightness: Brightness.dark),
            home: const Scaffold(
              appBar: null,
              body: Center(child: ThemeModeButton()),
            ),
          ),
        ),
      ),
    );
  }

  // Fresh preferences and Cubit for each test; the Cubit is closed after.
  setUp(() {
    preferences = InMemoryLocalStorage();
    cubit = ThemeCubit(preferences: preferences);
  });

  tearDown(() => cubit.close());

  testWidgets('shows the system icon first and offers three choices', (
    WidgetTester tester,
  ) async {
    await pumpButton(tester);
    expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.themeSystem), findsOneWidget);
    expect(find.text(AppStrings.themeLight), findsOneWidget);
    expect(find.text(AppStrings.themeDark), findsOneWidget);
  });

  testWidgets('choosing Night switches to dark and persists the choice', (
    WidgetTester tester,
  ) async {
    await pumpButton(tester);
    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.themeDark));
    await tester.pumpAndSettle();

    expect(cubit.state.mode, ThemeMode.dark);
    expect(preferences.getString(StorageKeys.themeMode), 'dark');
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    final Brightness brightness = Theme.of(
      tester.element(find.byType(ThemeModeButton)),
    ).brightness;
    expect(brightness, Brightness.dark);
  });

  testWidgets('choosing Day switches to light even on a dark device', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpButton(tester);
    // System mode follows the (dark) device.
    expect(
      Theme.of(tester.element(find.byType(ThemeModeButton))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byType(ThemeModeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.themeLight));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(ThemeModeButton))).brightness,
      Brightness.light,
    );
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });
}
