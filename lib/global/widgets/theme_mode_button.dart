import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_state.dart';

/// App-bar button that opens a menu to choose System, Day or Night.
///
/// It lives in `global/widgets` (not `core/widgets`) because it depends on
/// the global [ThemeCubit]. Screens simply drop it into their app bar; they
/// do not know anything about theming.
class ThemeModeButton extends StatelessWidget {
  /// Creates the button; it reads [ThemeCubit] from the widget tree.
  const ThemeModeButton({super.key});

  /// Icon that shows the *current* mode.
  static IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
    }
  }

  /// Menu text for [mode] (System default, Day or Night).
  static String _labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return AppStrings.themeSystem;
      case ThemeMode.light:
        return AppStrings.themeLight;
      case ThemeMode.dark:
        return AppStrings.themeDark;
    }
  }

  /// Builds the icon button and its popup menu.
  @override
  Widget build(BuildContext context) {
    // Rebuilds the button only when the theme mode changes, so the icon and
    // the checked menu item always match the current mode.
    return BlocBuilder<ThemeCubit, ThemeState>(
      buildWhen: (ThemeState previous, ThemeState current) =>
          previous.mode != current.mode,
      builder: (BuildContext context, ThemeState state) {
        return PopupMenuButton<ThemeMode>(
          tooltip: AppStrings.theme,
          icon: Icon(_iconFor(state.mode)),
          initialValue: state.mode,
          // Picking a menu item saves and applies the new mode.
          onSelected: context.read<ThemeCubit>().setThemeMode,
          // One checkable item per mode; the current one is checked.
          itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
            for (final ThemeMode mode in ThemeMode.values)
              CheckedPopupMenuItem<ThemeMode>(
                value: mode,
                checked: mode == state.mode,
                child: Text(_labelFor(mode)),
              ),
          ],
        );
      },
    );
  }
}
