/// A photo album from `/albums`.
class AlbumModel {
  /// Creates an album; every field is required.
  const AlbumModel({
    required this.id,
    required this.userId,
    required this.title,
  });

  /// Builds a [AlbumModel] from the API's JSON object.
  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
    );
  }

  /// Unique album id (used to load its photos).
  final int id;

  /// Id of the user who owns the album.
  final int userId;

  /// Album title shown in lists.
  final String title;

  /// Converts the model back to JSON (e.g. to send it to the API).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'title': title,
  };

  /// Readable description, handy in logs.
  @override
  String toString() => 'AlbumModel(id: $id, userId: $userId, title: $title)';
}
