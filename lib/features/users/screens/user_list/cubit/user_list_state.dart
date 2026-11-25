import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/models/user_sort_option.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// State of the search/sort/filter bar at the top of the user list.
///
/// Kept separate from the list so that typing in the search box only
/// rebuilds the header widgets, not the whole list.
@immutable
class UserListHeaderState {
  /// Creates the header state. The defaults describe the screen before the
  /// first load: empty search, A-Z sort, no city selected, no cities yet.
  const UserListHeaderState({
    this.query = '',
    this.sort = UserSortOption.nameAscending,
    this.selectedCity,
    this.cities = const <String>[],
    this.totalCount = 0,
  });

  /// Text currently typed in the search box (used to show the clear button).
  final String query;

  /// Sort order currently chosen in the sort menu (shown as checked).
  final UserSortOption sort;

  /// City chip that is selected; `null` means the "All cities" chip.
  final String? selectedCity;

  /// Distinct cities of all users, sorted A-Z, used to build the chips.
  final List<String> cities;

  /// Number of users loaded before any filtering.
  final int totalCount;

  /// Short text used in logs; prints only the number of cities.
  @override
  String toString() =>
      'UserListHeaderState(query: $query, sort: $sort, '
      'selectedCity: $selectedCity, cities: ${cities.length}, '
      'totalCount: $totalCount)';
}

/// State of the list area (loader / error / empty view / list of users).
@immutable
class UserListContentState {
  /// Creates the content state. By default nothing has been loaded yet.
  const UserListContentState({
    this.status = ViewStatus.initial,
    this.users = const <UserModel>[],
    this.errorMessage,
  });

  /// Decides which view the list area shows (loader, error, empty or list).
  final ViewStatus status;

  /// Users that pass the search and city filter, already sorted.
  final List<UserModel> users;

  /// Message shown by the error view when [status] is error.
  final String? errorMessage;

  /// Short text used in logs; prints only the number of users.
  @override
  String toString() =>
      'UserListContentState(status: $status, users: ${users.length}, '
      'errorMessage: $errorMessage)';
}

/// Widget-level groups: the header and the content rebuild independently
/// (each widget selects only its own group with a BlocSelector).
@immutable
class UserListBuildState {
  /// Creates the build state from its two groups.
  const UserListBuildState({
    this.header = const UserListHeaderState(),
    this.content = const UserListContentState(),
  });

  /// Search text, sort order and city filter (the bar at the top).
  final UserListHeaderState header;

  /// Loading status and the visible users (the list below the bar).
  final UserListContentState content;

  /// Text used in logs.
  @override
  String toString() => 'UserListBuildState(header: $header, content: $content)';
}

/// Full state of the user list screen: the build state plus the one-time
/// effect (snackbar, navigation …). Short name used by widgets and the Cubit.
typedef UserListState = ScreenState<UserListBuildState>;
