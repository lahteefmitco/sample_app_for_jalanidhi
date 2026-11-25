import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sample_app_for_jalanidhi/app/app_config.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/services/firebase_service.dart';
import 'package:sample_app_for_jalanidhi/core/storage/local_storage_service.dart';
import 'package:sample_app_for_jalanidhi/core/storage/preferences_service.dart';
import 'package:sample_app_for_jalanidhi/core/storage/secure_storage_service.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/cubit/album_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/repositories/photo_repository.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/cubit/album_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/album_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/todo_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

/// The app's service locator: every class asks it for its dependencies,
/// e.g. `getIt<AuthRepository>()`.
final GetIt getIt = GetIt.instance;

/// Registers everything once at start-up.
///
/// | Component            | Registration        |
/// |----------------------|---------------------|
/// | Dio, storage, config | singleton           |
/// | ApiClient            | lazy singleton      |
/// | Shared repositories  | lazy singleton      |
/// | Screen Cubits        | factory (per screen)|
///
/// The only global Cubit is `ThemeCubit` (the theme is needed above every
/// screen). Other shared data lives in the shared repositories, and every
/// screen Cubit reads what it needs into its own BuildState.
///
/// The optional parameters exist so tests can inject fakes.
Future<void> configureDependencies(
  AppConfig config, {
  LocalStorageService? localStorage,
  SecureStorageService? secureStorage,
  Dio? dio,
}) async {
  // Core services first: everything registered below depends on them.
  await _registerCore(
    config,
    localStorage: localStorage,
    secureStorage: secureStorage,
    dio: dio,
  );
  _registerSharedRepositories();
  _registerGlobalCubits();
  // One block per feature, in the same order as the `features/` folders.
  _registerAuthentication();
  _registerHome();
  _registerUsers();
  _registerPosts();
  _registerComments();
  _registerTodos();
  _registerAlbums();
}

/// Drops every registration (used by tests).
Future<void> resetDependencies() => getIt.reset();

/// Registers config, storage, Firebase, Dio and the [ApiClient].
///
/// Any non-null optional argument (a test fake) replaces the real service.
Future<void> _registerCore(
  AppConfig config, {
  LocalStorageService? localStorage,
  SecureStorageService? secureStorage,
  Dio? dio,
}) async {
  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<LocalStorageService>(
      localStorage ?? await PreferencesService.create(),
    )
    ..registerSingleton<SecureStorageService>(
      secureStorage ?? FlutterSecureStorageService(),
    )
    ..registerSingleton<FirebaseService>(createFirebaseService())
    ..registerSingleton<Dio>(
      dio ?? ApiClient.createDio(baseUrl: config.baseUrl),
    )
    ..registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));
}

/// Registers the repositories shared by several features.
///
/// Lazy singletons: each is created on first use and then reused, so its
/// in-memory cache is shared by every screen.
void _registerSharedRepositories() {
  getIt
    ..registerLazySingleton<UserRepository>(
      () => UserRepository(getIt<ApiClient>()),
    )
    ..registerLazySingleton<PostRepository>(
      () => PostRepository(getIt<ApiClient>()),
    )
    ..registerLazySingleton<CommentRepository>(
      () => CommentRepository(getIt<ApiClient>()),
    )
    ..registerLazySingleton<TodoRepository>(
      () => TodoRepository(getIt<ApiClient>()),
    )
    ..registerLazySingleton<AlbumRepository>(
      () => AlbumRepository(getIt<ApiClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(secureStorage: getIt<SecureStorageService>()),
    );
}

/// The only global Cubit: the theme preference (needed by MaterialApp).
void _registerGlobalCubits() {
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(preferences: getIt<LocalStorageService>()),
  );
}

/// Login and register screen Cubits (a new one per screen).
void _registerAuthentication() {
  getIt
    ..registerFactory<LoginCubit>(
      () => LoginCubit(
        authRepository: getIt<AuthRepository>(),
        preferences: getIt<LocalStorageService>(),
      ),
    )
    ..registerFactory<RegisterCubit>(
      () => RegisterCubit(
        authRepository: getIt<AuthRepository>(),
        preferences: getIt<LocalStorageService>(),
      ),
    );
}

/// Home (dashboard) screen Cubit; it reads from every shared repository.
void _registerHome() {
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(
      authRepository: getIt<AuthRepository>(),
      userRepository: getIt<UserRepository>(),
      postRepository: getIt<PostRepository>(),
      commentRepository: getIt<CommentRepository>(),
      todoRepository: getIt<TodoRepository>(),
      albumRepository: getIt<AlbumRepository>(),
    ),
  );
}

/// User list and user details screen Cubits.
///
/// The details Cubit is a "factory with param": the route passes the user id
/// as `param1`. The second parameter is unused, hence `void`.
void _registerUsers() {
  getIt
    ..registerFactory<UserListCubit>(
      () => UserListCubit(userRepository: getIt<UserRepository>()),
    )
    ..registerFactoryParam<UserDetailsCubit, int, void>(
      (int userId, void _) => UserDetailsCubit(
        userId: userId,
        userRepository: getIt<UserRepository>(),
        postRepository: getIt<PostRepository>(),
      ),
    );
}

/// Post list, details and form screen Cubits.
///
/// Details gets the post id; the form gets a post id to edit, or null to
/// create a new post.
void _registerPosts() {
  getIt
    ..registerFactory<PostListCubit>(
      () => PostListCubit(
        postRepository: getIt<PostRepository>(),
        userRepository: getIt<UserRepository>(),
      ),
    )
    ..registerFactoryParam<PostDetailsCubit, int, void>(
      (int postId, void _) => PostDetailsCubit(
        postId: postId,
        postRepository: getIt<PostRepository>(),
        userRepository: getIt<UserRepository>(),
        commentRepository: getIt<CommentRepository>(),
      ),
    )
    ..registerFactoryParam<PostFormCubit, int?, void>(
      (int? postId, void _) => PostFormCubit(
        postId: postId,
        postRepository: getIt<PostRepository>(),
        userRepository: getIt<UserRepository>(),
      ),
    );
}

/// Comment list screen Cubit.
void _registerComments() {
  getIt.registerFactory<CommentListCubit>(
    () => CommentListCubit(commentRepository: getIt<CommentRepository>()),
  );
}

/// Todo list screen Cubit.
void _registerTodos() {
  getIt.registerFactory<TodoListCubit>(
    () => TodoListCubit(todoRepository: getIt<TodoRepository>()),
  );
}

/// Album feature: its own photo repository plus the list and details Cubits.
///
/// [PhotoRepository] is only used by this feature, so it is registered here
/// rather than with the shared repositories. The details Cubit gets the
/// selected [AlbumModel] as `param1`.
void _registerAlbums() {
  getIt
    ..registerLazySingleton<PhotoRepository>(
      () => PhotoRepository(getIt<ApiClient>()),
    )
    ..registerFactory<AlbumListCubit>(
      () => AlbumListCubit(albumRepository: getIt<AlbumRepository>()),
    )
    ..registerFactoryParam<AlbumDetailsCubit, AlbumModel, void>(
      (AlbumModel album, void _) => AlbumDetailsCubit(
        album: album,
        photoRepository: getIt<PhotoRepository>(),
      ),
    );
}
