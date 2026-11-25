import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/core/utils/platform_capabilities.dart';

/// Optional Firebase integration, kept independent from feature logic.
///
/// The sample ships without any Firebase dependency. To enable Firebase:
///  1. add `firebase_core` (and the products you need) to pubspec.yaml,
///  2. run `flutterfire configure`,
///  3. implement this interface and return it from [createFirebaseService]
///     when [PlatformCapabilities.supportsFirebase] is true.
/// Screens and widgets must never call Firebase directly.
abstract interface class FirebaseService {
  /// Whether Firebase is set up and usable on this device.
  bool get isAvailable;

  /// Initialises Firebase once, centrally, from `AppInitializer`.
  Future<void> initialize();

  /// Records an analytics event called [name] with optional [parameters].
  Future<void> logEvent(String name, {Map<String, Object?>? parameters});
}

/// Used while Firebase is not configured or the platform does not support it.
///
/// Every method does nothing, so callers never need to check
/// [isAvailable] before calling.
class NoopFirebaseService implements FirebaseService {
  /// Always false: this implementation has no Firebase behind it.
  @override
  bool get isAvailable => false;

  /// Only logs that Firebase is disabled.
  @override
  Future<void> initialize() async {
    generalLog(
      'Firebase disabled (supportedPlatform: '
      '${PlatformCapabilities.supportsFirebase}).',
      funtionName: 'FirebaseService.initialize',
    );
  }

  /// Ignores the event.
  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}
}

/// Returns the [FirebaseService] the app should use (registered in GetIt).
///
/// Today always the no-op version; change this when Firebase is added.
FirebaseService createFirebaseService() => NoopFirebaseService();
