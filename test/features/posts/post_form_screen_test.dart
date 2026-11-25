import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/post_form_screen.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sample_data.dart';

/// Widget tests for [PostFormScreen]: the empty create form, validation
/// errors, and the pre-filled edit form that saves with a PUT request.
void main() {
  /// Shows [PostFormScreen] (edit mode when [postId] is given) and returns
  /// the fake backend so a test can count the requests it received.
  Future<FakeBackend> pumpForm(WidgetTester tester, {int? postId}) async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      'GET /users': (RequestOptions _) => usersJson,
      'GET /posts/2': (RequestOptions _) => postsJson[1],
      'PUT /posts/2': (RequestOptions _) => postsJson[1],
      'POST /posts': (RequestOptions _) => <String, int>{'id': 101},
    });
    final ApiClient api = backend.createClient();
    await pumpApp(
      tester,
      // Provides the PostFormCubit that PostFormScreen reads from the
      // context; `..load()` starts loading the authors (and the post).
      BlocProvider<PostFormCubit>(
        create: (BuildContext _) => PostFormCubit(
          postId: postId,
          postRepository: PostRepository(api),
          userRepository: UserRepository(api),
        )..load(),
        child: const PostFormScreen(),
      ),
      size: const Size(500, 900),
    );
    await tester.pumpAndSettle();
    return backend;
  }

  testWidgets('create mode: empty form, title says "New post"', (
    WidgetTester tester,
  ) async {
    await pumpForm(tester);
    expect(find.text(AppStrings.newPost), findsOneWidget);
    expect(find.text('Charlie Brown'), findsOneWidget); // default author
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('saving an empty form shows validation errors only', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = await pumpForm(tester);
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
    await tester.pump();
    expect(find.text(AppStrings.requiredField), findsNWidgets(2));
    expect(backend.count('POST /posts'), 0);
  });

  testWidgets('edit mode: fields are pre-filled and saving sends a PUT', (
    WidgetTester tester,
  ) async {
    final FakeBackend backend = await pumpForm(tester, postId: 2);
    expect(find.text(AppStrings.editPost), findsOneWidget);
    expect(find.text('Post title 2'), findsOneWidget);
    expect(find.text('Post body 2'), findsOneWidget);

    // Change the title (first text field) and save.
    await tester.enterText(find.byType(TextField).at(0), 'Changed title');
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
    await tester.pumpAndSettle();
    expect(backend.count('PUT /posts/2'), 1);
  });
}
