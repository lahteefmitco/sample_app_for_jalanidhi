import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_endpoints.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_response.dart';
import 'package:sample_app_for_jalanidhi/core/network/json_parsers.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/models/photo_model.dart';

/// Reads photos.
///
/// Only the album details screen needs photos, so this repository is
/// screen-specific rather than global.
class PhotoRepository {
  /// Creates the repository on top of the shared [ApiClient].
  PhotoRepository(this._api);

  /// HTTP client used for every request.
  final ApiClient _api;

  /// Returns the photos of the album [albumId]
  /// (`GET /photos?albumId={albumId}`). Not cached: each album is opened
  /// on its own.
  Future<List<PhotoModel>> getPhotosByAlbum(
    int albumId, {
    RequestToken? requestToken,
  }) async {
    repositoryLog(
      'getPhotosByAlbum($albumId): fetching',
      funtionName: 'PhotoRepository.getPhotosByAlbum',
    );
    final ApiResponse<List<PhotoModel>> response = await _api
        .get<List<PhotoModel>>(
          ApiEndpoints.photos,
          queryParameters: <String, dynamic>{'albumId': albumId},
          parser: (Object? json) =>
              parseList<PhotoModel>(json, PhotoModel.fromJson),
          requestToken: requestToken,
        );
    return response.data;
  }
}
