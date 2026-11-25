import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/cubit/album_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/repositories/photo_repository.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/cubit/album_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/album_repository.dart';

import '../../helpers/fake_backend.dart';
import '../../helpers/sample_data.dart';

/// Unit tests for the two album cubits: [AlbumListCubit] (list, search,
/// navigation) and [AlbumDetailsCubit] (the photos of one album).
void main() {
  /// Fake JSONPlaceholder server; also counts the requests it receives.
  late FakeBackend backend;

  setUp(() {
    // Album 1 has four photos; every other album has none.
    backend = FakeBackend(<String, RouteHandler>{
      'GET /albums': (RequestOptions _) => albumsJson,
      'GET /photos': (RequestOptions options) =>
          options.queryParameters['albumId'] == 1
          ? <Map<String, Object>>[
              for (int i = 1; i <= 4; i++)
                <String, Object>{
                  'id': i,
                  'albumId': 1,
                  'title': 'photo $i',
                  'url': 'https://img.test/600/92c952',
                  'thumbnailUrl': 'https://img.test/150/92c952',
                },
            ]
          : <Map<String, dynamic>>[],
    });
  });

  // The album list screen's cubit.
  group('AlbumListCubit', () {
    late AlbumListCubit cubit;
    setUp(() {
      cubit = AlbumListCubit(
        albumRepository: AlbumRepository(backend.createClient()),
      );
    });
    tearDown(() => cubit.close());

    test('loads, searches by title and navigates with the album', () async {
      await cubit.load();
      expect(cubit.state.build.albums, hasLength(3));

      cubit.onSearchChanged('album 2');
      expect(cubit.state.build.albums.single.title, 'Album 2');
      cubit.onSearchChanged('zzz');
      expect(cubit.state.build.status, ViewStatus.empty);

      // Clear the search, then open the first album.
      cubit.onSearchChanged('');
      cubit.onAlbumTapped(albums.first);
      final NavigateEffect navigate = cubit.state.effect as NavigateEffect;
      expect(navigate.routeName, RouteNames.albumDetails);
      expect(navigate.arguments, albums.first);
    });

    test('a failing request shows an error state', () async {
      // A backend with no routes at all, so every request fails.
      final AlbumListCubit failing = AlbumListCubit(
        albumRepository: AlbumRepository(
          FakeBackend(<String, RouteHandler>{}).createClient(),
        ),
      );
      await failing.load();
      expect(failing.state.build.status, ViewStatus.error);
      await failing.close();
    });
  });

  // The album details screen's cubit (photos of a single album).
  group('AlbumDetailsCubit', () {
    /// Creates a cubit for the sample album at [albumIndex] in `albums`.
    AlbumDetailsCubit buildCubit(int albumIndex) => AlbumDetailsCubit(
      album: albums[albumIndex],
      photoRepository: PhotoRepository(backend.createClient()),
    );

    test('loads the photos of the album', () async {
      final AlbumDetailsCubit cubit = buildCubit(0);
      await cubit.load();
      expect(cubit.state.build.status, ViewStatus.loaded);
      expect(cubit.state.build.photos, hasLength(4));
      cubit.onPhotoTapped(cubit.state.build.photos.first);
      expect(cubit.state.effect, isA<ShowInfoSheetEffect>());
      await cubit.close();
    });

    test('an album without photos is an empty state', () async {
      final AlbumDetailsCubit cubit = buildCubit(1);
      await cubit.load();
      expect(cubit.state.build.status, ViewStatus.empty);
      await cubit.close();
    });
  });
}
