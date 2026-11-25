import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_endpoints.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_response.dart';
import 'package:sample_app_for_jalanidhi/core/network/json_parsers.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// Reads users from the API.
///
/// Shared by the home, users and posts features, so it is registered once
/// (lazy singleton) and keeps the user list in memory after the first load.
class UserRepository {
  /// Creates the repository on top of the shared [ApiClient].
  UserRepository(this._api);

  /// HTTP client used for every request.
  final ApiClient _api;

  /// Users loaded by [getUsers]; `null` until the first successful load.
  List<UserModel>? _cache;

  /// Returns every user.
  ///
  /// The first call hits `GET /users`; later calls are served from memory
  /// unless [forceRefresh] is `true` (pull-to-refresh / retry).
  /// [requestToken] lets the caller cancel the HTTP request.
  Future<List<UserModel>> getUsers({
    bool forceRefresh = false,
    RequestToken? requestToken,
  }) async {
    final List<UserModel>? cached = _cache;
    if (!forceRefresh && cached != null) {
      repositoryLog(
        'getUsers: ${cached.length} from cache',
        funtionName: 'UserRepository.getUsers',
      );
      return cached;
    }
    repositoryLog('getUsers: fetching', funtionName: 'UserRepository.getUsers');
    final ApiResponse<List<UserModel>> response = await _api
        .get<List<UserModel>>(
          ApiEndpoints.users,
          parser: (Object? json) =>
              parseList<UserModel>(json, UserModel.fromJson),
          requestToken: requestToken,
        );
    _cache = response.data;
    return response.data;
  }

  /// Returns the user with [id] (from memory when possible, otherwise
  /// `GET /users/{id}`).
  Future<UserModel> getUser(int id, {RequestToken? requestToken}) async {
    final List<UserModel>? cached = _cache;
    if (cached != null) {
      for (final UserModel user in cached) {
        if (user.id == id) {
          return user;
        }
      }
    }
    repositoryLog(
      'getUser($id): fetching',
      funtionName: 'UserRepository.getUser',
    );
    final ApiResponse<UserModel> response = await _api.get<UserModel>(
      ApiEndpoints.user(id),
      parser: (Object? json) =>
          parseObject<UserModel>(json, UserModel.fromJson),
      requestToken: requestToken,
    );
    return response.data;
  }
}
