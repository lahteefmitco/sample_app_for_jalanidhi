import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_state.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';

import '../../helpers/fake_backend.dart';

/// Unit tests for [CommentListCubit]: loading, pagination ("load more"),
/// searching and opening a comment's details sheet.
void main() {
  /// The [CommentListCubit] under test.
  late CommentListCubit cubit;

  // 45 comments, so pagination (page size 20) has three pages.
  final List<Map<String, Object>> manyComments = <Map<String, Object>>[
    for (int i = 1; i <= 45; i++)
      <String, Object>{
        'id': i,
        'postId': 1,
        'name': 'Name $i',
        'email': 'user$i@mail.test',
        'body': i == 7 ? 'special needle text' : 'plain body $i',
      },
  ];

  setUp(() {
    // A fake backend that always answers with the 45 comments above.
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      'GET /comments': (RequestOptions _) => manyComments,
    });
    cubit = CommentListCubit(
      commentRepository: CommentRepository(backend.createClient()),
    );
  });

  tearDown(() => cubit.close());

  test('loads the first page only', () async {
    await cubit.load();
    final CommentListBuildState build = cubit.state.build;
    expect(build.status, ViewStatus.loaded);
    expect(build.comments, hasLength(AppConstants.pageSize));
    expect(build.totalMatches, 45);
    expect(build.hasMore, isTrue);
  });

  test('loadMore pages through the list and then stops', () async {
    await cubit.load();
    cubit.loadMore();
    expect(cubit.state.build.comments, hasLength(40));
    cubit.loadMore();
    expect(cubit.state.build.comments, hasLength(45));
    expect(cubit.state.build.hasMore, isFalse);
    // Nothing is left, so another loadMore must not emit a new state.
    final ScreenState<CommentListBuildState> before = cubit.state;
    cubit.loadMore();
    expect(identical(before, cubit.state), isTrue);
  });

  test('search matches name, email and body, case-insensitively', () async {
    await cubit.load();
    cubit.onSearchChanged('NEEDLE');
    expect(cubit.state.build.comments.single.id, 7);
    cubit.onSearchChanged('user12@');
    expect(cubit.state.build.comments.single.id, 12);
    cubit.onSearchChanged('missing-text');
    expect(cubit.state.build.status, ViewStatus.empty);
    cubit.clearSearch();
    expect(cubit.searchController.text, isEmpty);
    expect(cubit.state.build.status, ViewStatus.loaded);
  });

  test('searching resets pagination to the first page', () async {
    await cubit.load();
    cubit.loadMore();
    cubit.onSearchChanged('Name');
    expect(cubit.state.build.comments, hasLength(AppConstants.pageSize));
  });

  test('tapping a comment opens a sheet with its body', () async {
    await cubit.load();
    cubit.onCommentTapped(cubit.state.build.comments.first);
    final ShowInfoSheetEffect sheet = cubit.state.effect as ShowInfoSheetEffect;
    expect(sheet.title, 'Comment #1');
    expect(sheet.fields.last.value, 'plain body 1');
  });
}
