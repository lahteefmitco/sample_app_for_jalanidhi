/// Application-wide constants that are not strings, colors or dimensions.
abstract final class AppConstants {
  /// App name shown by the OS (task switcher, browser tab).
  static const String appName = 'Jalanidhi Sample';

  /// Page size used by client-side pagination of long lists.
  static const int pageSize = 20;

  /// How long to wait for the server to accept the connection.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// How long to wait for the server's response data.
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// How long to wait while sending the request body.
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Artificial latency of the local authentication simulation.
  static const Duration authLatency = Duration(milliseconds: 400);

  /// Shortest password the login and register forms accept.
  static const int minPasswordLength = 6;

  /// Display name of the demo account created on first launch, so the app
  /// can be explored at once. JSONPlaceholder has no authentication: login
  /// is simulated locally.
  static const String demoName = 'Demo User';

  /// Email of the demo account.
  static const String demoEmail = 'demo@example.com';

  /// Password of the demo account (demo only, never use real secrets here).
  static const String demoPassword = 'Demo@1234';
}
