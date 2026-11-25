import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/models/user_sort_option.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../../helpers/sample_data.dart';

/// A mocktail mock of [UserRepository]; each test decides what it returns.
class MockUserRepository extends Mock implements UserRepository {}

/// Unit tests for [UserListCubit]: loading, search, city filter, sorting,
/// errors, navigation and disposing the search controller.
void main() {
  // mocktail needs a sample value for `any()` of a custom type.
  setUpAll(() => registerFallbackValue(RequestToken()));

  /// Mocked [UserRepository]; each test decides what it returns.
  late MockUserRepository repository;

  /// The [UserListCubit] under test.
  late UserListCubit cubit;

  setUp(() {
    // By default the mock returns the three sample users.
    repository = MockUserRepository();
    when(
      () => repository.getUsers(
        forceRefresh: any(named: 'forceRefresh'),
        requestToken: any(named: 'requestToken'),
      ),
    ).thenAnswer((Invocation _) async => users);
    cubit = UserListCubit(userRepository: repository);
  });

  tearDown(() => cubit.close());

  /// The names of the users currently shown, in display order.
  List<String> names() =>
      cubit.state.build.content.users.map((UserModel u) => u.name).toList();

  test('starts in the initial state', () {
    expect(cubit.state.build.content.status, ViewStatus.initial);
    expect(cubit.state.effect, isNull);
  });

  test('load emits loading then loaded, sorted by name', () async {
    // Arrange: record the status of every state the cubit emits.
    final List<ViewStatus> statuses = <ViewStatus>[];
    final StreamSubscription<ScreenState<UserListBuildState>> sub = cubit.stream
        .listen(
          (ScreenState<UserListBuildState> s) =>
              statuses.add(s.build.content.status),
        );

    // Act
    await cubit.load();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    // Assert
    expect(statuses, <ViewStatus>[ViewStatus.loading, ViewStatus.loaded]);
    expect(names(), <String>['Alice Smith', 'Bob Jones', 'Charlie Brown']);
    expect(cubit.state.build.header.cities, <String>['Gotham', 'Metropolis']);
    expect(cubit.state.build.header.totalCount, 3);
  });

  test(
    'search is case-insensitive and matches name, username and email',
    () async {
      await cubit.load();
      cubit.onSearchChanged('BOB');
      expect(names(), <String>['Bob Jones']);
      cubit.onSearchChanged('alice@mail');
      expect(names(), <String>['Alice Smith']);
      cubit.onSearchChanged('zzz');
      expect(cubit.state.build.content.status, ViewStatus.empty);
      cubit.onSearchChanged('');
      expect(names(), hasLength(3));
    },
  );

  test('city filter and sorting combine', () async {
    await cubit.load();
    cubit.onCityChanged('Gotham');
    expect(names(), <String>['Bob Jones', 'Charlie Brown']);
    cubit.onSortChanged(UserSortOption.nameDescending);
    expect(names(), <String>['Charlie Brown', 'Bob Jones']);
    // `null` means "all cities".
    cubit.onCityChanged(null);
    expect(names(), hasLength(3));
  });

  test('header and content groups change independently', () async {
    await cubit.load();
    final UserListContentState content = cubit.state.build.content;
    cubit.onSortChanged(UserSortOption.email);
    // Sorting changes the visible order, so content is new...
    expect(identical(content, cubit.state.build.content), isFalse);
    final UserListHeaderState header = cubit.state.build.header;
    cubit.emitEffect(const ShowProgressEffect());
    // ...but an effect never replaces either group.
    expect(identical(header, cubit.state.build.header), isTrue);
  });

  test('failure shows an error state and an error snackbar', () async {
    // Arrange: this time the repository throws.
    when(
      () => repository.getUsers(
        forceRefresh: any(named: 'forceRefresh'),
        requestToken: any(named: 'requestToken'),
      ),
    ).thenThrow(const AppException('boom'));
    await cubit.load();
    expect(cubit.state.build.content.status, ViewStatus.error);
    expect(cubit.state.build.content.errorMessage, 'boom');
    final ShowSnackbarEffect effect = cubit.state.effect as ShowSnackbarEffect;
    expect(effect.type, SnackbarType.error);
  });

  test('tapping a user navigates to its details', () async {
    await cubit.load();
    cubit.onUserTapped(users.first);
    final NavigateEffect effect = cubit.state.effect as NavigateEffect;
    expect(effect.arguments, users.first.id);
  });

  test('close disposes the search controller', () async {
    final UserListCubit other = UserListCubit(userRepository: repository);
    final TextEditingController controller = other.searchController;
    await other.close();
    // A disposed controller throws when it is used again.
    expect(() => controller.addListener(() {}), throwsStateError);
  });
}
