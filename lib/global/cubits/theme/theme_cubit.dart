import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/storage_keys.dart';
import 'package:sample_app_for_jalanidhi/core/storage/local_storage_service.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_state.dart';

/// App-wide theme preference (System / Day / Night).
///
/// This is one of the few legitimately *global* Cubits: the theme is needed
/// by `MaterialApp` itself, above every screen. It only exposes the chosen
/// [ThemeMode]; it never drives an individual screen's UI. The choice is
/// stored in shared preferences so it survives restarts.
class ThemeCubit extends Cubit<ThemeState> {
  /// Starts with the mode saved in [preferences] (or "system" if none).
  ThemeCubit({required this._preferences})
    : super(ThemeState(mode: _read(_preferences))) {
    cubitLog(
      'ThemeCubit created, mode: ${state.mode.name}',
      funtionName: 'init',
    );
  }

  /// Where the chosen mode is saved between app launches.
  final LocalStorageService _preferences;

  /// Reads the saved mode; anything missing or unknown means "follow system".
  static ThemeMode _read(LocalStorageService preferences) {
    // The saved enum name (`system`, `light` or `dark`), or null.
    final String? saved = preferences.getString(StorageKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (ThemeMode mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  /// Applies and persists [mode]. Re-selecting the current mode does nothing.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state.mode) return;
    cubitLog('theme -> ${mode.name}', funtionName: 'setThemeMode');
    emit(ThemeState(mode: mode));
    await _preferences.setString(StorageKeys.themeMode, mode.name);
  }
}
