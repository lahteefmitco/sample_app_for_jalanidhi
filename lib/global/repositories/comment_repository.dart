import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_endpoints.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_response.dart';
import 'package:sample_app_for_jalanidhi/core/network/json_parsers.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';

/// Reads comments. Shared by the home, post details and comment list screens.
class CommentRepository {
  /// Creates the repository on top of the shared [ApiClient].
  CommentRepository(this._api);

  /// HTTP client used for every request.
  final ApiClient _api;

  /// All comments loaded by [getComments]; `null` until the first load.
  List<CommentModel>? _cache;

  /// Returns every comment (`GET /comments`), cached after the first load
  /// unless [forceRefresh] is `true`.
  Future<List<CommentModel>> getComments({
    bool forceRefresh = false,
    RequestToken? requestToken,
  }) async {
    final List<CommentModel>? cached = _cache;
    if (!forceRefresh && cached != null) {
      return cached;
    }
    repositoryLog(
      'getComments: fetching',
      funtionName: 'CommentRepository.getComments',
    );
    final ApiResponse<List<CommentModel>> response = await _api
        .get<List<CommentModel>>(
          ApiEndpoints.comments,
          parser: (Object? json) =>
              parseList<CommentModel>(json, CommentModel.fromJson),
          requestToken: requestToken,
        );
    _cache = response.data;
    return response.data;
  }

  /// Returns the comments of the post [postId].
  ///
  /// Uses the cached list when every comment is already loaded, otherwise
  /// `GET /comments?postId={postId}`.
  Future<List<CommentModel>> getCommentsByPost(
    int postId, {
    RequestToken? requestToken,
  }) async {
    final List<CommentModel>? cached = _cache;
    if (cached != null) {
      return cached
          .where((CommentModel comment) => comment.postId == postId)
          .toList(growable: false);
    }
    repositoryLog(
      'getCommentsByPost($postId): fetching',
      funtionName: 'CommentRepository.getCommentsByPost',
    );
    final ApiResponse<List<CommentModel>> response = await _api
        .get<List<CommentModel>>(
          ApiEndpoints.comments,
          queryParameters: <String, dynamic>{'postId': postId},
          parser: (Object? json) =>
              parseList<CommentModel>(json, CommentModel.fromJson),
          requestToken: requestToken,
        );
    return response.data;
  }
}
