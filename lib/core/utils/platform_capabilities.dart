import 'package:flutter/foundation.dart';

/// What the current platform can do.
///
/// Uses `defaultTargetPlatform`/`kIsWeb` only (no `dart:io`), so it is safe to
/// import from shared code on every platform, including Web.
abstract final class PlatformCapabilities {
  /// True when the app runs in a browser.
  static bool get isWeb => kIsWeb;

  /// True on Android and iOS apps (not mobile browsers).
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// True on Windows, macOS and Linux apps (not desktop browsers).
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Firebase core plugins support Android, iOS, macOS, Web and Windows.
  static bool get supportsFirebase =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  /// Example of a feature limited to specific platforms (e.g. a POS module).
  static bool get supportsPos =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.windows;
}
