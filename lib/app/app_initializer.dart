import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/app_bloc_observer.dart';
import 'package:sample_app_for_jalanidhi/app/app_config.dart';
import 'package:sample_app_for_jalanidhi/app/dependency_injection.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/services/firebase_service.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';

/// Everything that must run before the first frame.
///
/// `main` awaits [initialize] and then shows the app on the returned route.
abstract final class AppInitializer {
  /// Sets up logging, dependencies and Firebase, then returns the route the
  /// app should open first (home if a session exists, otherwise login).
  static Future<String> initialize({
    AppConfig config = const AppConfig(),
  }) async {
    // Plugins (storage, etc.) need the binding before runApp is called.
    WidgetsFlutterBinding.ensureInitialized();
    Bloc.observer = AppBlocObserver();

    // Send Flutter framework errors to our logger as well as the console.
    FlutterError.onError = (FlutterErrorDetails details) {
      errorLog(details.exceptionAsString(), funtionName: 'FlutterError');
      FlutterError.presentError(details);
    };

    await configureDependencies(config);
    await getIt<FirebaseService>().initialize();

    // Start on login; switch to home below only if a session is stored.
    String initialRoute = RouteNames.login;
    try {
      final AuthRepository auth = getIt<AuthRepository>();
      await auth.ensureDemoAccount();
      if (await auth.isLoggedIn()) initialRoute = RouteNames.home;
    } on Object catch (error) {
      // Secure storage can be unavailable (e.g. missing keychain entitlement).
      // The app still starts on the login screen.
      errorLog(
        'auth bootstrap failed: ${error.runtimeType}',
        funtionName: 'AppInitializer.initialize',
      );
    }
    generalLog(
      'initialised (${kDebugMode ? 'debug' : 'release'}), '
      'initial route: $initialRoute',
      funtionName: 'AppInitializer.initialize',
    );
    return initialRoute;
  }
}
