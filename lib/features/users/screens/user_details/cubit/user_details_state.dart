import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// What the user details screen renders: status, user and posts.
@immutable
class UserDetailsBuildState {
  /// Creates the build state. By default nothing has been loaded yet.
  const UserDetailsBuildState({
    this.status = ViewStatus.initial,
    this.user,
    this.posts = const <PostModel>[],
    this.errorMessage,
  });

  /// Decides what the screen shows: loader, error view or the details.
  final ViewStatus status;

  /// The user shown on the page; `null` until it has been loaded.
  final UserModel? user;

  /// Posts written by the user, shown below/next to the info card.
  final List<PostModel> posts;

  /// Message shown by the error view when [status] is error.
  final String? errorMessage;

  /// Short text used in logs; prints only the user id and number of posts.
  @override
  String toString() =>
      'UserDetailsBuildState(status: $status, user: ${user?.id}, '
      'posts: ${posts.length}, errorMessage: $errorMessage)';
}

/// Full state of the user details screen: the build state plus the one-time
/// effect (snackbar, navigation …). Short name used by widgets and the Cubit.
typedef UserDetailsState = ScreenState<UserDetailsBuildState>;
