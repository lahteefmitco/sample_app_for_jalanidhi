import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_exception.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/album_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/todo_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';
import 'package:dio/dio.dart';

import '../helpers/fake_backend.dart';
import '../helpers/in_memory_storage.dart';
import '../helpers/sample_data.dart';

/// Minimal screen Cubit used to test the token bookkeeping of ScreenCubit.
class _TokenCubit extends ScreenCubit<int> {
  /// Starts with build state 0.
  _TokenCubit() : super(0, name: 'TokenCubit');
}

/// Delay of the fake server, long enough to cancel a request in between.
const Duration _slow = Duration(milliseconds: 300);

/// Tests for request cancellation: [RequestToken], cancelling an
/// [ApiClient] request, the token bookkeeping of [ScreenCubit], and real
/// screen Cubits that are closed or reloaded while a request is running.
void main() {
  // The token object itself.
  group('RequestToken', () {
    test('starts active, cancels once, and a second cancel is harmless', () {
      final RequestToken token = RequestToken();
      expect(token.isCancelled, isFalse);
      token.cancel();
      token.cancel();
      expect(token.isCancelled, isTrue);
    });
  });

  // Cancelling a request that is still waiting for the (slow) server.
  group('ApiClient', () {
    test('a cancelled request fails with ApiErrorType.cancelled', () async {
      final FakeBackend backend = FakeBackend(<String, RouteHandler>{
        'GET /users': (RequestOptions _) => usersJson,
      }, latency: _slow);
      final ApiClient client = backend.createClient();
      final RequestToken token = RequestToken();

      final Future<Object?> request = client
          .get<Object?>(
            '/users',
            parser: (Object? json) => json,
            requestToken: token,
          )
          .then((Object? _) => null);
      // Act: cancel while the fake server is still "thinking".
      token.cancel();

      await expectLater(
        request,
        throwsA(
          isA<ApiException>().having(
            (ApiException e) => e.type,
            'type',
            ApiErrorType.cancelled,
          ),
        ),
      );
    });
  });

  // How ScreenCubit creates, replaces and cancels tokens per purpose.
  group('ScreenCubit tokens', () {
    test('a new token for the same purpose cancels the previous one', () {
      final _TokenCubit cubit = _TokenCubit();
      final RequestToken first = cubit.newRequestToken('load');
      final RequestToken second = cubit.newRequestToken('load');
      expect(first.isCancelled, isTrue);
      expect(second.isCancelled, isFalse);
      cubit.close();
    });

    test('tokens with different purposes are independent', () {
      final _TokenCubit cubit = _TokenCubit();
      final RequestToken load = cubit.newRequestToken('load');
      final RequestToken refresh = cubit.newRequestToken('refresh');
      expect(load.isCancelled, isFalse);
      expect(refresh.isCancelled, isFalse);
      cubit.close();
    });

    test('closing the Cubit cancels every running request', () async {
      final _TokenCubit cubit = _TokenCubit();
      final RequestToken load = cubit.newRequestToken('load');
      final RequestToken refresh = cubit.newRequestToken('refresh');
      await cubit.close();
      expect(load.isCancelled, isTrue);
      expect(refresh.isCancelled, isTrue);
    });

    test('isCancellation recognises only cancellations', () {
      final _TokenCubit cubit = _TokenCubit();
      expect(
        cubit.isCancellation(
          const ApiException(type: ApiErrorType.cancelled, message: 'x'),
        ),
        isTrue,
      );
      expect(
        cubit.isCancellation(
          const ApiException(type: ApiErrorType.network, message: 'x'),
        ),
        isFalse,
      );
      expect(cubit.isCancellation(Exception('x')), isFalse);
      cubit.close();
    });
  });

  // Real Cubits: what the user sees when requests are cancelled or fail.
  group('screen Cubits', () {
    test(
      'leaving the screen during a load cancels it without an error',
      () async {
        final FakeBackend backend = FakeBackend(<String, RouteHandler>{
          'GET /users': (RequestOptions _) => usersJson,
        }, latency: _slow);
        final UserListCubit cubit = UserListCubit(
          userRepository: UserRepository(backend.createClient()),
        );
        // Record every state the Cubit emits.
        final List<ScreenState<Object?>> states = <ScreenState<Object?>>[];
        cubit.stream.listen(states.add);

        final Future<void> load = cubit.load();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await cubit.close(); // the user pressed "back"
        await load;

        expect(backend.count('GET /users'), 1);
        // Only the "loading" state was emitted: no error, no snackbar.
        expect(
          states.where((ScreenState<Object?> s) => s.effect != null),
          isEmpty,
        );
      },
    );

    test(
      'a second load cancels the first one; only the last result shows',
      () async {
        final FakeBackend backend = FakeBackend(<String, RouteHandler>{
          'GET /users': (RequestOptions _) => usersJson,
        }, latency: _slow);
        final UserListCubit cubit = UserListCubit(
          userRepository: UserRepository(backend.createClient()),
        );
        // Record every one-time effect (snackbar, dialog...) the Cubit emits.
        final List<UiEffect> effects = <UiEffect>[];
        cubit.stream.listen((ScreenState<Object?> state) {
          if (state.effect != null) {
            effects.add(state.effect!);
          }
        });

        // Act: start a second load while the first is still running.
        final Future<void> first = cubit.load(forceRefresh: true);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final Future<void> second = cubit.load(forceRefresh: true);
        await Future.wait(<Future<void>>[first, second]);

        expect(backend.count('GET /users'), 2);
        expect(cubit.state.build.content.status, ViewStatus.loaded);
        expect(cubit.state.build.content.users, hasLength(3));
        expect(effects, isEmpty); // the cancelled load reported nothing
        await cubit.close();
      },
    );

    test(
      'dashboard shows the real network message when one request fails',
      () async {
        // Regression test: parallel loads used to surface a generic
        // "unexpected error" instead of the network message.
        final FakeBackend backend = FakeBackend(<String, RouteHandler>{
          'GET /users': (RequestOptions _) => usersJson,
          'GET /posts': (RequestOptions options) => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
          'GET /comments': (RequestOptions _) => commentsJson,
          'GET /todos': (RequestOptions _) => todosJson,
          'GET /albums': (RequestOptions _) => albumsJson,
        });
        final ApiClient api = backend.createClient();
        final HomeCubit cubit = HomeCubit(
          authRepository: AuthRepository(
            secureStorage: InMemorySecureStorage(),
            simulatedLatency: Duration.zero,
          ),
          userRepository: UserRepository(api),
          postRepository: PostRepository(api),
          commentRepository: CommentRepository(api),
          todoRepository: TodoRepository(api),
          albumRepository: AlbumRepository(api),
        );

        await cubit.load();

        expect(cubit.state.build.status, ViewStatus.error);
        expect(cubit.state.build.errorMessage, AppStrings.networkError);
        await cubit.close();
      },
    );
  });
}
