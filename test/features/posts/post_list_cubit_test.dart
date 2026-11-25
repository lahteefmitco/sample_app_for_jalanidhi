import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../../helpers/sample_data.dart';

/// A mocktail mock of [PostRepository]; each test decides what it returns.
class MockPostRepository extends Mock implements PostRepository {}

/// A mocktail mock of [UserRepository]; each test decides what it returns.
class MockUserRepository extends Mock implements UserRepository {}

/// Unit tests for [PostListCubit]: paging, search / author filters, deleting
/// with a confirmation, and refreshing after the post form closes.
void main() {
  // mocktail needs a sample value for `any()` of a custom type.
  setUpAll(() => registerFallbackValue(RequestToken()));

  /// Mocked [PostRepository]; each test decides what it returns.
  late MockPostRepository postRepository;

  /// Mocked [UserRepository]; each test decides what it returns.
  late MockUserRepository userRepository;

  /// The [PostListCubit] under test.
  late PostListCubit cubit;

  setUp(() {
    // Both mocks return the sample posts / users for any arguments.
    postRepository = MockPostRepository();
    userRepository = MockUserRepository();
    when(
      () => postRepository.getPosts(
        forceRefresh: any(named: 'forceRefresh'),
        requestToken: any(named: 'requestToken'),
      ),
    ).thenAnswer((Invocation _) async => posts);
    when(
      () => userRepository.getUsers(
        forceRefresh: any(named: 'forceRefresh'),
        requestToken: any(named: 'requestToken'),
      ),
    ).thenAnswer((Invocation _) async => users);
    cubit = PostListCubit(
      postRepository: postRepository,
      userRepository: userRepository,
    );
  });

  tearDown(() => cubit.close());

  test('loads the first page and exposes pagination data', () async {
    await cubit.load();
    final PostListContentState content = cubit.state.build.content;
    expect(content.status, ViewStatus.loaded);
    expect(content.posts, hasLength(AppConstants.pageSize));
    expect(content.totalMatches, 45);
    expect(content.hasMore, isTrue);
    expect(content.authors[1], 'Charlie Brown');
  });

  test('loadMore reveals further pages until everything is shown', () async {
    await cubit.load();
    cubit.loadMore();
    expect(cubit.state.build.content.posts, hasLength(40));
    cubit.loadMore();
    expect(cubit.state.build.content.posts, hasLength(45));
    expect(cubit.state.build.content.hasMore, isFalse);
    final ScreenState<PostListBuildState> before = cubit.state;
    cubit.loadMore(); // nothing left: no new state
    expect(identical(before, cubit.state), isTrue);
  });

  test('search and author filter reset paging', () async {
    await cubit.load();
    cubit.loadMore();
    cubit.onSearchChanged('title 4');
    // "Post title 4" and 40..45
    expect(cubit.state.build.content.totalMatches, 7);
    cubit.onSearchChanged('');
    cubit.onAuthorChanged(2);
    final PostListContentState content = cubit.state.build.content;
    expect(content.totalMatches, 15);
    expect(content.posts.every((PostModel p) => p.userId == 2), isTrue);
  });

  test('delete asks for confirmation, then deletes with progress', () async {
    // Arrange: deleting always succeeds.
    when(() => postRepository.deletePost(any()))
        .thenAnswer((Invocation _) async {});
    await cubit.load();

    // Act 1: pressing delete only asks for confirmation.
    cubit.onDeletePressed(posts.first);
    final ShowConfirmationEffect confirm =
        cubit.state.effect as ShowConfirmationEffect;
    expect(confirm.actionId, 'delete:${posts.first.id}');
    verifyNever(() => postRepository.deletePost(any()));

    // Act 2: confirm, while recording every effect the cubit emits.
    final List<UiEffect> effects = <UiEffect>[];
    final StreamSubscription<ScreenState<PostListBuildState>> sub = cubit.stream
        .listen((ScreenState<PostListBuildState> s) {
          if (s.effect != null) effects.add(s.effect!);
        });
    cubit.onConfirmed(confirm.actionId);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    // Assert: deleted once, with progress shown, hidden, then a snackbar.
    verify(() => postRepository.deletePost(posts.first.id)).called(1);
    expect(effects[0], isA<ShowProgressEffect>());
    expect(effects[1], isA<HideProgressEffect>());
    expect((effects[2] as ShowSnackbarEffect).type, SnackbarType.success);
  });

  test('returning from the form refreshes and reports success', () async {
    await cubit.load();
    // The form screen pops with the result 'saved'.
    cubit.onNavigationReturn('saved');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.effect, isA<ShowSnackbarEffect>());
  });
}
