import 'package:sample_app_for_jalanidhi/core/network/api_endpoints.dart';

/// The environment the app is built for.
enum AppEnvironment {
  /// Local development and debugging.
  development,

  /// The build that real users run.
  production,
}

/// Static configuration of the running app.
///
/// Passed to `AppInitializer.initialize` and registered in GetIt, so any
/// class can read it.
class AppConfig {
  /// Creates a configuration; every value has a sensible default.
  const AppConfig({
    this.environment = AppEnvironment.development,
    this.baseUrl = ApiEndpoints.baseUrl,
    this.enableFirebase = false,
  });

  /// Which environment this build targets.
  final AppEnvironment environment;

  /// Root URL of the REST API every request is sent to.
  final String baseUrl;

  /// Firebase is optional; see `core/services/firebase_service.dart`.
  final bool enableFirebase;

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'AppConfig(environment: $environment, baseUrl: $baseUrl, '
      'enableFirebase: $enableFirebase)';
}
