import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/core/utils/extensions.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/models/user_sort_option.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

/// Business logic of the user list screen.
///
/// Loads the users and applies the search text, the city filter and the sort
/// order. All of that work happens here; the widgets only display the result.
///
/// The state is split in two groups (see `UserListBuildState`):
///  * header  - search text, sort order, cities, selected city,
///  * content - loading status and the visible users.
class UserListCubit extends ScreenCubit<UserListBuildState> {
  /// Creates the Cubit. [userRepository] is injected by GetIt.
  UserListCubit({required this._userRepository})
    : super(const UserListBuildState(), name: 'UserListCubit');

  /// Request purpose used with [newRequestToken].
  static const String _loadRequest = 'load';

  /// Source of the users.
  final UserRepository _userRepository;

  /// Controller of the search box. Owned by the Cubit, disposed in [close].
  final TextEditingController searchController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Working data. The immutable state is rebuilt from these fields.
  // ---------------------------------------------------------------------------

  /// Every user returned by the repository.
  List<UserModel> _allUsers = const <UserModel>[];

  /// Users that pass the search and city filter, in the chosen order.
  List<UserModel> _visibleUsers = const <UserModel>[];

  /// Distinct cities of all users, sorted A-Z (for the filter chips).
  List<String> _cities = const <String>[];

  /// Current search text.
  String _query = '';

  /// Current sort order.
  UserSortOption _sort = UserSortOption.nameAscending;

  /// Selected city chip; `null` means "all cities".
  String? _selectedCity;

  /// Loading status of the list.
  ViewStatus _status = ViewStatus.initial;

  /// Message shown by the error view, when [_status] is error.
  String? _errorMessage;

  /// Builds the header group from the working data.
  UserListHeaderState _header() {
    return UserListHeaderState(
      query: _query,
      sort: _sort,
      selectedCity: _selectedCity,
      cities: _cities,
      totalCount: _allUsers.length,
    );
  }

  /// Builds the content group from the working data.
  UserListContentState _content() {
    return UserListContentState(
      status: _status,
      users: List<UserModel>.unmodifiable(_visibleUsers),
      errorMessage: _errorMessage,
    );
  }

  /// Emits a new content group and keeps the same header instance, so the
  /// search bar does not rebuild while the list is loading.
  void _emitContent() {
    emitBuild(UserListBuildState(header: build.header, content: _content()));
  }

  /// Emits new header and content groups.
  void _emitAll() {
    emitBuild(UserListBuildState(header: _header(), content: _content()));
  }

  /// Loads the users (from the repository cache unless [forceRefresh]).
  ///
  /// Triggered when the screen opens (by the route), by the retry button of
  /// the error view and by pull-to-refresh (both with `forceRefresh: true`).
  /// Emits the content group as loading, then header + content with the
  /// result, or an error content plus an error snackbar.
  ///
  /// A load that is still running is cancelled first, so an older response
  /// can never replace a newer one.
  Future<void> load({bool forceRefresh = false}) async {
    final RequestToken token = startBlockingRequest(_loadRequest);
    _status = ViewStatus.loading;
    _errorMessage = null;
    _emitContent();
    try {
      _allUsers = await _userRepository.getUsers(
        forceRefresh: forceRefresh,
        requestToken: token,
      );
      // A Set drops duplicate city names; it is sorted A-Z below.
      final Set<String> uniqueCities = <String>{
        for (final UserModel user in _allUsers) user.address.city,
      };
      _cities = uniqueCities.toList()..sort();
      _applyFilters();
    } on Object catch (error) {
      if (isCancellation(error)) {
        return; // the screen was closed or a newer load started
      }
      _status = ViewStatus.error;
      _errorMessage = ErrorHandler.messageFor(error);
      _emitContent();
      showErrorMessage(_errorMessage!);
    } finally {
      // Un-block the screen (ignored if a newer load took over).
      endBlockingRequest(token);
    }
  }

  /// Called by `UserSearchField` on every keystroke in the search box.
  /// Re-filters the list and emits header + content.
  void onSearchChanged(String query) {
    _query = query;
    _applyFilters();
  }

  /// Called by the clear (x) button of `UserSearchField`.
  /// Clears the search box and shows every user again (emits header + content).
  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  /// Called by `UserSortMenu` when the user picks another sort order.
  /// Re-sorts the list and emits header + content.
  void onSortChanged(UserSortOption sort) {
    _sort = sort;
    _applyFilters();
  }

  /// Called by `UserCityFilter` when a city chip is selected; `null` means
  /// "all cities". Re-filters the list and emits header + content.
  void onCityChanged(String? city) {
    _selectedCity = city;
    _applyFilters();
  }

  /// Called when a `UserListItem` is tapped.
  /// Emits a navigation effect that opens the details page of [user].
  void onUserTapped(UserModel user) {
    navigateTo(RouteNames.userDetails, arguments: user.id);
  }

  /// Applies search + city filter + sort to the loaded users and emits.
  ///
  /// Called after every load and every search/sort/city change, so the
  /// visible list is always computed in one place.
  void _applyFilters() {
    // Leading/trailing spaces should not affect the search.
    final String query = _query.trim();
    _visibleUsers = _allUsers.where((UserModel user) {
      final bool matchesCity =
          _selectedCity == null || user.address.city == _selectedCity;
      final bool matchesQuery =
          query.isEmpty ||
          user.name.containsIgnoreCase(query) ||
          user.username.containsIgnoreCase(query) ||
          user.email.containsIgnoreCase(query);
      return matchesCity && matchesQuery;
    }).toList()..sort(_sort.compare);

    cubitLog(
      'filtered ${_visibleUsers.length}/${_allUsers.length} users '
      '(query: "$query", city: $_selectedCity, sort: $_sort)',
      funtionName: '_applyFilters',
    );
    _status = _visibleUsers.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    _errorMessage = null;
    _emitAll();
  }

  /// Disposes the search controller, cancels requests and closes the Cubit.
  ///
  /// Called automatically by `BlocProvider` when the screen is removed.
  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
