import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/models/photo_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

import '../helpers/sample_data.dart';

/// Tests for the data models: JSON round-trips (`fromJson` -> `toJson`),
/// readable `toString()` output, and rejection of invalid JSON.
void main() {
  test('UserModel round-trips JSON and has a meaningful toString', () {
    final UserModel user = UserModel.fromJson(usersJson.first);
    expect(UserModel.fromJson(user.toJson()).toJson(), user.toJson());
    expect(user.toString(), contains('UserModel(id: 1'));
    expect(user.toString(), contains('AddressModel('));
    expect(user.toString(), contains('CompanyModel('));
  });

  test('PostModel round-trips JSON and has a meaningful toString', () {
    final PostModel post = PostModel.fromJson(postsJson.first);
    expect(PostModel.fromJson(post.toJson()).toJson(), post.toJson());
    expect(post.toString(), startsWith('PostModel(id: 1'));
    expect(post.toString(), contains('title: Post title 1'));
  });

  test('TodoModel round-trips JSON and has a meaningful toString', () {
    final TodoModel todo = TodoModel.fromJson(todosJson[1]);
    expect(todo.completed, isTrue);
    expect(TodoModel.fromJson(todo.toJson()).toJson(), todo.toJson());
    expect(todo.toString(), contains('completed: true'));
  });

  test('Comment and Album models round-trip JSON', () {
    final CommentModel comment = CommentModel.fromJson(commentsJson.first);
    expect(comment.toJson(), commentsJson.first);
    expect(comment.toString(), startsWith('CommentModel(id: 1'));
    final AlbumModel album = AlbumModel.fromJson(albumsJson.first);
    expect(album.toJson(), albumsJson.first);
    expect(album.toString(), startsWith('AlbumModel(id: 1'));
  });

  test('PhotoModel exposes the placeholder color from the URL', () {
    const PhotoModel photo = PhotoModel(
      id: 1,
      albumId: 1,
      title: 't',
      url: 'https://via.placeholder.com/600/92c952',
      thumbnailUrl: 'https://via.placeholder.com/150/92c952',
    );
    expect(photo.placeholderColor, 0xFF92C952);
    expect(photo.toString(), contains('PhotoModel(id: 1'));
  });

  test('invalid JSON throws instead of producing a half-built model', () {
    expect(
      () => PostModel.fromJson(<String, dynamic>{'id': 'x'}),
      throwsA(isA<TypeError>()),
    );
  });
}
