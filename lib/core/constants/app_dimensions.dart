import 'package:sizer/sizer.dart';

/// Screen-width breakpoints (logical pixels).
abstract final class Breakpoints {
  /// Widest window still treated as a phone.
  static const double mobileMax = 599;

  /// Widest window still treated as a tablet; anything wider is desktop.
  static const double tabletMax = 1024;

  /// Content never grows wider than this on large screens.
  static const double maxContentWidth = 1100;
}

/// Sizer based dimensions.
///
/// Sizer's percentage units are relative to the whole window, so on a 1920 px
/// desktop `4.w` would be ~77 px. Every value is therefore clamped to a sane
/// range, which keeps phones, tablets, desktops and browsers consistent.
abstract final class AppDimensions {
  /// Keeps [value] between [min] and [max] (always as a `double`).
  static double _clamp(double value, double min, double max) =>
      value.clamp(min, max).toDouble();

  /// Responsive width (percent of window width) limited to [min]..[max].
  static double width(double percent, {double min = 0, double max = 400}) =>
      _clamp(percent.w, min, max);

  /// Responsive font size around [base], never below 90 % or above 120 %.
  static double font(double base) => _clamp(base.sp, base * 0.9, base * 1.2);

  /// Padding between the screen edge and its content.
  static double get pagePadding => _clamp(4.w, 12, 24);

  /// Standard space between two widgets.
  static double get gap => _clamp(2.w, 8, 16);

  /// Half of [gap], for tightly related widgets.
  static double get gapSmall => gap / 2;

  /// Twice [gap], to separate sections.
  static double get gapLarge => gap * 2;

  /// Corner radius of cards, buttons and fields.
  static double get radius => _clamp(2.w, 8, 14);

  /// Standard icon size.
  static double get iconSize => _clamp(6.w, 20, 28);

  /// Font size for captions and secondary text.
  static double get fontSmall => font(12);

  /// Font size for normal body text.
  static double get fontBody => font(14);

  /// Font size for titles (e.g. list item titles).
  static double get fontTitle => font(18);

  /// Font size for large headings.
  static double get fontHeadline => font(24);
}
