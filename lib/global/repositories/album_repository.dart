import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_endpoints.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_response.dart';
import 'package:sample_app_for_jalanidhi/core/network/json_parsers.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';

/// Reads albums. Shared by the home dashboard and the album list.
class AlbumRepository {
  /// Creates the repository on top of the shared [ApiClient].
  AlbumRepository(this._api);

  /// HTTP client used for every request.
  final ApiClient _api;

  /// Albums loaded by [getAlbums]; `null` until the first successful load.
  List<AlbumModel>? _cache;

  /// Returns every album (`GET /albums`), cached after the first load unless
  /// [forceRefresh] is `true`.
  Future<List<AlbumModel>> getAlbums({
    bool forceRefresh = false,
    RequestToken? requestToken,
  }) async {
    final List<AlbumModel>? cached = _cache;
    if (!forceRefresh && cached != null) {
      return cached;
    }
    repositoryLog(
      'getAlbums: fetching',
      funtionName: 'AlbumRepository.getAlbums',
    );
    final ApiResponse<List<AlbumModel>> response = await _api
        .get<List<AlbumModel>>(
          ApiEndpoints.albums,
          parser: (Object? json) =>
              parseList<AlbumModel>(json, AlbumModel.fromJson),
          requestToken: requestToken,
        );
    _cache = response.data;
    return response.data;
  }
}
