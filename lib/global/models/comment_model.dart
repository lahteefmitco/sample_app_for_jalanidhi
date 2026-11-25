/// A comment on a post, from `/comments`.
class CommentModel {
  /// Creates a comment; every field is required.
  const CommentModel({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
  });

  /// Builds a [CommentModel] from the API's JSON object.
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      postId: json['postId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      body: json['body'] as String,
    );
  }

  /// Unique comment id.
  final int id;

  /// Id of the post this comment belongs to.
  final int postId;

  /// Comment title (JSONPlaceholder calls it `name`).
  final String name;

  /// Email of the person who wrote the comment.
  final String email;

  /// The comment text.
  final String body;

  /// Converts the model back to JSON (e.g. to send it to the API).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'postId': postId,
    'name': name,
    'email': email,
    'body': body,
  };

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'CommentModel(id: $id, postId: $postId, name: $name, email: $email, '
      'body: $body)';
}
