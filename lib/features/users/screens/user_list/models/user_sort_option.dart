import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// The ways the user list can be sorted (the choices in the sort menu).
enum UserSortOption {
  /// Name from A to Z (the default).
  nameAscending('Name (A-Z)'),

  /// Name from Z to A.
  nameDescending('Name (Z-A)'),

  /// Email address from A to Z.
  email('Email'),

  /// City name from A to Z.
  city('City');

  /// Creates an option with the [label] shown in the sort menu.
  const UserSortOption(this.label);

  /// Text shown for this option in the sort menu.
  final String label;

  /// Compares two users for this sort order.
  ///
  /// Passed to `List.sort`, so it returns a negative number when [a] comes
  /// first, a positive number when [b] comes first and 0 when they are equal.
  /// Names and emails are compared case-insensitively.
  int compare(UserModel a, UserModel b) {
    switch (this) {
      case UserSortOption.nameAscending:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case UserSortOption.nameDescending:
        // Arguments swapped on purpose: this reverses the order.
        return b.name.toLowerCase().compareTo(a.name.toLowerCase());
      case UserSortOption.email:
        return a.email.toLowerCase().compareTo(b.email.toLowerCase());
      case UserSortOption.city:
        return a.address.city.compareTo(b.address.city);
    }
  }
}
