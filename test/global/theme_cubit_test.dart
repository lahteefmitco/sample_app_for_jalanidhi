import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_state.dart';

import '../helpers/in_memory_storage.dart';

/// Tests for [ThemeCubit]: the default theme, restoring and saving the
/// user's choice, and ignoring a choice that does not change anything.
void main() {
  /// Fake local storage where the theme choice is saved.
  late InMemoryLocalStorage preferences;

  // Every test starts with empty preferences.
  setUp(() => preferences = InMemoryLocalStorage());

  test('defaults to the system theme', () {
    final ThemeCubit cubit = ThemeCubit(preferences: preferences);
    expect(cubit.state.mode, ThemeMode.system);
    cubit.close();
  });

  test('restores the saved choice', () {
    preferences.values[StorageKeys.themeMode] = 'dark';
    final ThemeCubit cubit = ThemeCubit(preferences: preferences);
    expect(cubit.state.mode, ThemeMode.dark);
    cubit.close();
  });

  test('an unknown saved value falls back to system', () {
    preferences.values[StorageKeys.themeMode] = 'sepia';
    final ThemeCubit cubit = ThemeCubit(preferences: preferences);
    expect(cubit.state.mode, ThemeMode.system);
    cubit.close();
  });

  blocTest<ThemeCubit, ThemeState>(
    'setThemeMode emits the new mode and persists it',
    build: () => ThemeCubit(preferences: preferences),
    act: (ThemeCubit cubit) async {
      await cubit.setThemeMode(ThemeMode.dark);
      await cubit.setThemeMode(ThemeMode.light);
    },
    verify: (ThemeCubit cubit) {
      expect(cubit.state.mode, ThemeMode.light);
      expect(preferences.getString(StorageKeys.themeMode), 'light');
    },
    expect: () => <TypeMatcher<ThemeState>>[
      isA<ThemeState>().having(
        (ThemeState s) => s.mode,
        'mode',
        ThemeMode.dark,
      ),
      isA<ThemeState>().having(
        (ThemeState s) => s.mode,
        'mode',
        ThemeMode.light,
      ),
    ],
  );

  blocTest<ThemeCubit, ThemeState>(
    'choosing the current mode again emits nothing',
    build: () => ThemeCubit(preferences: preferences),
    act: (ThemeCubit cubit) => cubit.setThemeMode(ThemeMode.system),
    expect: () => <ThemeState>[],
    verify: (ThemeCubit _) => expect(preferences.values, isEmpty),
  );

  test('state has a meaningful toString', () {
    expect(const ThemeState(mode: ThemeMode.dark).toString(), contains('dark'));
  });
}
