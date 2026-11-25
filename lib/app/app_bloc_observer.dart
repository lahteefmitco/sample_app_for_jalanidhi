import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';

/// Logs the lifecycle and every state change of every Cubit (debug only).
///
/// Registered once in `AppInitializer` through `Bloc.observer`, so no Cubit
/// has to log its own state changes.
class AppBlocObserver extends BlocObserver {
  /// Logs that a Cubit was created (e.g. when a screen opens).
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    cubitLog('${bloc.runtimeType} created', funtionName: 'onCreate');
  }

  /// Logs every new state a Cubit emits, to follow the app's data flow.
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    cubitLog(
      '${bloc.runtimeType}: ${change.nextState}',
      funtionName: 'onChange',
    );
  }

  /// Logs errors reported by a Cubit (through `addError`).
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errorLog('${bloc.runtimeType}: $error', funtionName: 'onError');
    super.onError(bloc, error, stackTrace);
  }

  /// Logs that a Cubit was closed (e.g. when its screen is popped).
  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    cubitLog('${bloc.runtimeType} closed', funtionName: 'onClose');
  }
}
