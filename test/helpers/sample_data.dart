import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// Builds the JSON of one user, like JSONPlaceholder returns it.
/// Username, email etc. are derived from [id] and [name].
Map<String, dynamic> userJson(int id, String name, String city) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'username': name.split(' ').first.toLowerCase(),
      'email': '${name.split(' ').first.toLowerCase()}@mail.test',
      'phone': '555-000$id',
      'website': 'site$id.test',
      'address': <String, String>{
        'street': 'Main $id',
        'suite': 'Apt $id',
        'city': city,
        'zipcode': '0000$id',
      },
      'company': <String, String>{
        'name': 'Company $id',
        'catchPhrase': 'Phrase $id',
      },
    };

/// Raw JSON of 3 users. Names are not in alphabetical order on purpose,
/// so tests can check sorting.
final List<Map<String, dynamic>> usersJson = <Map<String, dynamic>>[
  userJson(1, 'Charlie Brown', 'Gotham'),
  userJson(2, 'Alice Smith', 'Metropolis'),
  userJson(3, 'Bob Jones', 'Gotham'),
];

/// [usersJson] parsed into [UserModel]s.
final List<UserModel> users = usersJson.map(UserModel.fromJson).toList();

/// Raw JSON of 45 posts: ids 1..45, user ids cycle 1,2,3.
final List<Map<String, dynamic>> postsJson = <Map<String, dynamic>>[
  for (int i = 1; i <= 45; i++)
    <String, dynamic>{
      'id': i,
      'userId': (i - 1) % 3 + 1,
      'title': 'Post title $i',
      'body': 'Post body $i',
    },
];

/// [postsJson] parsed into [PostModel]s.
final List<PostModel> posts = postsJson.map(PostModel.fromJson).toList();

/// Raw JSON of 6 comments: post ids alternate 1,2.
final List<Map<String, dynamic>> commentsJson = <Map<String, dynamic>>[
  for (int i = 1; i <= 6; i++)
    <String, dynamic>{
      'id': i,
      'postId': (i - 1) % 2 + 1,
      'name': 'Comment $i',
      'email': 'c$i@mail.test',
      'body': 'Comment body $i',
    },
];

/// [commentsJson] parsed into [CommentModel]s.
final List<CommentModel> comments = commentsJson
    .map(CommentModel.fromJson)
    .toList();

/// Raw JSON of 5 todos of user 1; even ids are completed.
final List<Map<String, dynamic>> todosJson = <Map<String, dynamic>>[
  for (int i = 1; i <= 5; i++)
    <String, dynamic>{
      'id': i,
      'userId': 1,
      'title': 'Todo $i',
      'completed': i.isEven,
    },
];

/// [todosJson] parsed into [TodoModel]s.
final List<TodoModel> todos = todosJson.map(TodoModel.fromJson).toList();

/// Raw JSON of 3 albums of user 1.
final List<Map<String, dynamic>> albumsJson = <Map<String, dynamic>>[
  for (int i = 1; i <= 3; i++)
    <String, dynamic>{'id': i, 'userId': 1, 'title': 'Album $i'},
];

/// [albumsJson] parsed into [AlbumModel]s.
final List<AlbumModel> albums = albumsJson.map(AlbumModel.fromJson).toList();
