/// Small helpers added to every [String].
extension StringExtensions on String {
  /// Upper-cases the first letter of the string.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Case-insensitive "contains", used by search boxes.
  bool containsIgnoreCase(String query) =>
      toLowerCase().contains(query.toLowerCase());
}
