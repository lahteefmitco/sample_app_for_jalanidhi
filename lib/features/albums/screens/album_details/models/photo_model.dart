/// One photo of an album, as returned by `GET /photos`.
class PhotoModel {
  /// Creates a photo from already known values.
  const PhotoModel({
    required this.id,
    required this.albumId,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });

  /// Builds a photo from one JSON object of the API response.
  ///
  /// The `as` casts make a wrong API shape fail loudly here instead of
  /// somewhere deep in the UI.
  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as int,
      albumId: json['albumId'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }

  /// Unique id of the photo.
  final int id;

  /// Id of the album this photo belongs to.
  final int albumId;

  /// Photo caption, also used as the accessibility label of its tile.
  final String title;

  /// Full-size image URL (shown in the details sheet).
  final String url;

  /// Small image URL used by the grid tile.
  final String thumbnailUrl;

  /// JSONPlaceholder encodes a color in the last URL segment
  /// (`.../600/92c952`). Used for the placeholder tile when the image host
  /// is unreachable. Returns `null` when the URL carries no valid color.
  int? get placeholderColor {
    // Last path segment of the thumbnail URL, e.g. `92c952`.
    final String? segment = Uri.tryParse(thumbnailUrl)?.pathSegments.lastOrNull;
    // A color must be exactly six hex digits (RRGGBB).
    if (segment == null || segment.length != 6) return null;
    final int? rgb = int.tryParse(segment, radix: 16);
    // Add a fully opaque alpha channel (0xFF) in front of RRGGBB.
    return rgb == null ? null : 0xFF000000 | rgb;
  }

  /// Converts the photo back to JSON (same keys as the API).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'albumId': albumId,
    'title': title,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
  };

  /// Readable description for logs and debugging.
  @override
  String toString() =>
      'PhotoModel(id: $id, albumId: $albumId, title: $title, url: $url, '
      'thumbnailUrl: $thumbnailUrl)';
}
