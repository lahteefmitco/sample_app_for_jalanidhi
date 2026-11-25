/// A blog post from `/posts`.
class PostModel {
  /// Creates a post; every field is required.
  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  /// Builds a [PostModel] from the API's JSON object.
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  /// Unique post id.
  final int id;

  /// Id of the user who wrote the post (its author).
  final int userId;

  /// Post title.
  final String title;

  /// Post text.
  final String body;

  /// Converts the model back to JSON (e.g. to send it to the API).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'userId': userId,
    'title': title,
    'body': body,
  };

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'PostModel(id: $id, userId: $userId, title: $title, body: $body)';
}
