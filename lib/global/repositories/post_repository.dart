import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_endpoints.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_exception.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_response.dart';
import 'package:sample_app_for_jalanidhi/core/network/json_parsers.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';

/// Reads and writes posts.
///
/// Shared by the home, users and posts features.
///
/// JSONPlaceholder *simulates* writes: it answers 2xx but stores nothing.
/// So that create / edit / delete are visible in the UI during a session,
/// this repository keeps a local overlay (created, edited and deleted posts)
/// on top of the data fetched from the API. The overlay lives in memory only.
///
/// Read methods accept a [RequestToken] so a screen can cancel them.
/// Write methods do not: once sent, a write should be allowed to finish.
class PostRepository {
  /// Creates the repository on top of the shared [ApiClient].
  PostRepository(this._api);

  /// HTTP client used for every request.
  final ApiClient _api;

  /// Posts loaded by [getPosts]; `null` until the first successful load.
  List<PostModel>? _remote;

  /// Single posts loaded by [getPost], keyed by id.
  final Map<int, PostModel> _remoteById = <int, PostModel>{};

  /// Server posts the user edited during this session, keyed by id.
  final Map<int, PostModel> _edits = <int, PostModel>{};

  /// Ids of server posts the user deleted during this session.
  final Set<int> _deleted = <int>{};

  /// Posts the user created during this session (newest first).
  final List<PostModel> _created = <PostModel>[];

  /// Next id for a locally created post (the server always answers 101).
  int _nextLocalId = 1000;

  /// Returns every post with the session overlay applied.
  ///
  /// The first call hits `GET /posts`; later calls use memory unless
  /// [forceRefresh] is `true`.
  Future<List<PostModel>> getPosts({
    bool forceRefresh = false,
    RequestToken? requestToken,
  }) async {
    List<PostModel>? remote = _remote;
    if (forceRefresh || remote == null) {
      repositoryLog(
        'getPosts: fetching',
        funtionName: 'PostRepository.getPosts',
      );
      final ApiResponse<List<PostModel>> response = await _api
          .get<List<PostModel>>(
            ApiEndpoints.posts,
            parser: (Object? json) =>
                parseList<PostModel>(json, PostModel.fromJson),
            requestToken: requestToken,
          );
      remote = response.data;
      _remote = remote;
    }
    return _merge(remote);
  }

  /// Returns the posts written by the user [userId]
  /// (`GET /users/{id}/posts` plus the session overlay).
  Future<List<PostModel>> getPostsByUser(
    int userId, {
    RequestToken? requestToken,
  }) async {
    repositoryLog(
      'getPostsByUser($userId): fetching',
      funtionName: 'PostRepository.getPostsByUser',
    );
    final ApiResponse<List<PostModel>> response = await _api
        .get<List<PostModel>>(
          ApiEndpoints.userPosts(userId),
          parser: (Object? json) =>
              parseList<PostModel>(json, PostModel.fromJson),
          requestToken: requestToken,
        );
    final List<PostModel> merged = _merge(response.data);
    return merged.where((PostModel post) => post.userId == userId).toList();
  }

  /// Returns one post by [id].
  ///
  /// Order of lookup: created locally → deleted (404) → edited locally →
  /// already loaded → `GET /posts/{id}`.
  Future<PostModel> getPost(int id, {RequestToken? requestToken}) async {
    for (final PostModel post in _created) {
      if (post.id == id) {
        return post;
      }
    }
    if (_deleted.contains(id)) {
      throw const ApiException(
        type: ApiErrorType.badResponse,
        statusCode: 404,
        message: 'The requested item was not found.',
      );
    }
    final PostModel? edited = _edits[id];
    if (edited != null) {
      return edited;
    }
    final PostModel? known = _remoteById[id] ?? _findLoaded(id);
    if (known != null) {
      return known;
    }

    repositoryLog(
      'getPost($id): fetching',
      funtionName: 'PostRepository.getPost',
    );
    final ApiResponse<PostModel> response = await _api.get<PostModel>(
      ApiEndpoints.post(id),
      parser: (Object? json) =>
          parseObject<PostModel>(json, PostModel.fromJson),
      requestToken: requestToken,
    );
    _remoteById[id] = response.data;
    return response.data;
  }

  /// Creates a post (`POST /posts`, simulated by the server) and keeps it
  /// locally so it appears in the lists.
  Future<PostModel> createPost({
    required int userId,
    required String title,
    required String body,
  }) async {
    await _api.post<Object?>(
      ApiEndpoints.posts,
      data: <String, Object>{'userId': userId, 'title': title, 'body': body},
      parser: (Object? json) => json,
    );
    // The server always answers id 101; use a unique local id instead.
    final PostModel created = PostModel(
      id: _nextLocalId++,
      userId: userId,
      title: title,
      body: body,
    );
    _created.insert(0, created);
    repositoryLog(
      'createPost: $created (local only)',
      funtionName: 'PostRepository.createPost',
    );
    return created;
  }

  /// Saves [post]. Server posts are sent with `PUT /posts/{id}`; posts that
  /// only exist locally are updated in memory.
  Future<PostModel> updatePost(PostModel post) async {
    final int index = _created.indexWhere(
      (PostModel created) => created.id == post.id,
    );
    if (index >= 0) {
      _created[index] = post; // local posts do not exist on the server
    } else {
      await _api.put<Object?>(
        ApiEndpoints.post(post.id),
        data: post.toJson(),
        parser: (Object? json) => json,
      );
      _edits[post.id] = post;
    }
    repositoryLog(
      'updatePost: $post (local only)',
      funtionName: 'PostRepository.updatePost',
    );
    return post;
  }

  /// Deletes the post [id] (`DELETE /posts/{id}` for server posts).
  Future<void> deletePost(int id) async {
    final int index = _created.indexWhere((PostModel post) => post.id == id);
    if (index >= 0) {
      _created.removeAt(index);
    } else {
      await _api.delete<Object?>(
        ApiEndpoints.post(id),
        parser: (Object? json) => json,
      );
      _deleted.add(id);
      _edits.remove(id);
    }
    repositoryLog(
      'deletePost($id) (local only)',
      funtionName: 'PostRepository.deletePost',
    );
  }

  /// Looks for [id] in the list loaded by [getPosts].
  PostModel? _findLoaded(int id) {
    final List<PostModel>? remote = _remote;
    if (remote == null) {
      return null;
    }
    for (final PostModel post in remote) {
      if (post.id == id) {
        return post;
      }
    }
    return null;
  }

  /// Applies the session overlay to [remote]: created posts first, deleted
  /// posts removed, edited posts replaced.
  List<PostModel> _merge(List<PostModel> remote) {
    final List<PostModel> merged = <PostModel>[..._created];
    for (final PostModel post in remote) {
      if (_deleted.contains(post.id)) {
        continue;
      }
      merged.add(_edits[post.id] ?? post);
    }
    return List<PostModel>.unmodifiable(merged);
  }
}
