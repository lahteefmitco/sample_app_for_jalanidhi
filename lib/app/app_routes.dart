import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/dependency_injection.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/album_details_screen.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/cubit/album_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/album_list_screen.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/cubit/album_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/cubit/login_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/login/login_screen.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/cubit/register_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/authentication/screens/register/register_screen.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/comment_list_screen.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/home_screen.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/post_details_screen.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/post_form_screen.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/post_list_screen.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/cubit/todo_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/todos/screens/todo_list/todo_list_screen.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/user_details_screen.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/user_list_screen.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';

/// Central route table.
///
/// Every route creates a *new* screen Cubit from GetIt and hands it to a
/// `BlocProvider`, which closes it when the route is removed from the stack
/// (the Cubit lifecycle follows the navigation lifecycle).
abstract final class AppRoutes {
  /// Builds the page for [settings.name]; used by `MaterialApp`.
  ///
  /// [settings.arguments] carries the route's input (an id or a model) and is
  /// passed to the screen Cubit's factory.
  static Route<Object?> onGenerateRoute(RouteSettings settings) {
    screenLog(
      'route requested: ${settings.name}',
      funtionName: 'onGenerateRoute',
    );
    // The screen to show, set exactly once by the switch below.
    final Widget page;
    switch (settings.name) {
      case RouteNames.login:
        // Provides a fresh LoginCubit to the login screen.
        page = BlocProvider<LoginCubit>(
          create: (BuildContext _) => getIt<LoginCubit>(),
          child: const LoginScreen(),
        );
      case RouteNames.register:
        // Provides a fresh RegisterCubit to the register screen.
        page = BlocProvider<RegisterCubit>(
          create: (BuildContext _) => getIt<RegisterCubit>(),
          child: const RegisterScreen(),
        );
      case RouteNames.home:
        // Provides a HomeCubit and starts loading the dashboard at once.
        page = BlocProvider<HomeCubit>(
          create: (BuildContext _) => getIt<HomeCubit>()..load(),
          child: const HomeScreen(),
        );
      case RouteNames.userList:
        // Provides a UserListCubit and starts loading the users at once.
        page = BlocProvider<UserListCubit>(
          create: (BuildContext _) => getIt<UserListCubit>()..load(),
          child: const UserListScreen(),
        );
      case RouteNames.userDetails:
        // The id of the user to show, passed by the caller.
        final int userId = settings.arguments as int;
        // Provides a UserDetailsCubit for that user and loads it at once.
        page = BlocProvider<UserDetailsCubit>(
          create: (BuildContext _) =>
              getIt<UserDetailsCubit>(param1: userId)..load(),
          child: const UserDetailsScreen(),
        );
      case RouteNames.postList:
        // Provides a PostListCubit and starts loading the posts at once.
        page = BlocProvider<PostListCubit>(
          create: (BuildContext _) => getIt<PostListCubit>()..load(),
          child: const PostListScreen(),
        );
      case RouteNames.postDetails:
        // The id of the post to show, passed by the caller.
        final int postId = settings.arguments as int;
        // Provides a PostDetailsCubit for that post and loads it at once.
        page = BlocProvider<PostDetailsCubit>(
          create: (BuildContext _) =>
              getIt<PostDetailsCubit>(param1: postId)..load(),
          child: const PostDetailsScreen(),
        );
      case RouteNames.postForm:
        // The post to edit, or null to create a new post.
        final int? postId = settings.arguments as int?;
        // Provides a PostFormCubit (create or edit mode) and loads it at once.
        page = BlocProvider<PostFormCubit>(
          create: (BuildContext _) =>
              getIt<PostFormCubit>(param1: postId)..load(),
          child: const PostFormScreen(),
        );
      case RouteNames.commentList:
        // Provides a CommentListCubit and starts loading comments at once.
        page = BlocProvider<CommentListCubit>(
          create: (BuildContext _) => getIt<CommentListCubit>()..load(),
          child: const CommentListScreen(),
        );
      case RouteNames.todoList:
        // Provides a TodoListCubit and starts loading the todos at once.
        page = BlocProvider<TodoListCubit>(
          create: (BuildContext _) => getIt<TodoListCubit>()..load(),
          child: const TodoListScreen(),
        );
      case RouteNames.albumList:
        // Provides an AlbumListCubit and starts loading albums at once.
        page = BlocProvider<AlbumListCubit>(
          create: (BuildContext _) => getIt<AlbumListCubit>()..load(),
          child: const AlbumListScreen(),
        );
      case RouteNames.albumDetails:
        // The album whose photos are shown, passed by the caller.
        final AlbumModel album = settings.arguments as AlbumModel;
        // Provides an AlbumDetailsCubit for that album and loads its photos.
        page = BlocProvider<AlbumDetailsCubit>(
          create: (BuildContext _) =>
              getIt<AlbumDetailsCubit>(param1: album)..load(),
          child: const AlbumDetailsScreen(),
        );
      default:
        // Fallback page for a route name nobody registered.
        page = Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('Unknown route: ${settings.name}')),
        );
    }
    return MaterialPageRoute<Object?>(
      builder: (BuildContext _) => page,
      settings: settings,
    );
  }
}
