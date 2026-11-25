import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// What the post details screen renders: status, post, author and comments.
@immutable
class PostDetailsBuildState {
  /// Creates the build state. By default nothing has been loaded yet.
  const PostDetailsBuildState({
    this.status = ViewStatus.initial,
    this.post,
    this.author,
    this.comments = const <CommentModel>[],
    this.errorMessage,
  });

  /// Decides what the screen shows: loader, error view or the details.
  final ViewStatus status;

  /// The post shown on the page; `null` until it has been loaded.
  final PostModel? post;

  /// Who wrote the post; `null` until it has been loaded.
  final UserModel? author;

  /// Comments of the post, shown below/next to the post card.
  final List<CommentModel> comments;

  /// Message shown by the error view when [status] is error.
  final String? errorMessage;

  /// Short text used in logs; prints only ids and the number of comments.
  @override
  String toString() =>
      'PostDetailsBuildState(status: $status, post: ${post?.id}, '
      'author: ${author?.id}, comments: ${comments.length}, '
      'errorMessage: $errorMessage)';
}

/// Full state of the post details screen: the build state plus the one-time
/// effect (snackbar, dialog, bottom sheet …). Short name used by widgets and
/// the Cubit.
typedef PostDetailsState = ScreenState<PostDetailsBuildState>;
