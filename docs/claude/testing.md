# Testing guide

Run `flutter test` after every change; all tests must pass. Tests never hit
the real API.

## Helpers (`test/helpers/`)

| Helper | Use |
|---|---|
| `fake_backend.dart` | `FakeBackend(<String, RouteHandler>{'GET /users': (RequestOptions _) => usersJson}, latency: ...)` — offline Dio adapter. `createClient()` → `ApiClient`, `createDio()` for DI, `count('POST /posts')`, `requests`. Missing route → HTTP 404. Throw `DioException(type: DioExceptionType.connectionError)` in a handler to simulate no network. `latency` lets tests cancel / double-tap while a request runs. |
| `sample_data.dart` | `usersJson`, `postsJson`, `commentsJson`, `todosJson`, `albumsJson` + parsed lists. |
| `in_memory_storage.dart` | `InMemoryLocalStorage`, `InMemorySecureStorage`. |
| `pump_app.dart` | `pumpApp(tester, widget, size: ...)` — wraps in `Sizer` + `MaterialApp` with a fixed window size. Always use it (Sizer must be initialised). |
| `effects.dart` | `collectEffects(cubit, action)` — runs the action and returns every `UiEffect` emitted, waiting for fire-and-forget work. |

## Cubit tests

```dart
late FakeBackend backend;
late AlbumListCubit cubit;

setUp(() {
  backend = FakeBackend(<String, RouteHandler>{'GET /albums': (RequestOptions _) => albumsJson});
  cubit = AlbumListCubit(albumRepository: AlbumRepository(backend.createClient()));
});
tearDown(() => cubit.close());

test('loads albums', () async {
  await cubit.load();
  expect(cubit.state.build.status, ViewStatus.loaded);
  expect(cubit.state.build.albums, hasLength(3));
});
```

Cover for each Cubit: initial state, loading → loaded/empty/error, the error
snackbar effect, every user action (search, filter, sort, pagination,
navigation effects with arguments), validation, write success/failure
(progress shown then hidden, `PopEffect` / snackbar), double-submit ignored
while busy, cancellation stays silent, controllers disposed on `close()`.

Mocking repositories with mocktail:

```dart
class MockUserRepository extends Mock implements UserRepository {}
setUpAll(() => registerFallbackValue(RequestToken()));
when(() => repo.getUsers(
  forceRefresh: any(named: 'forceRefresh'),
  requestToken: any(named: 'requestToken'),
)).thenAnswer((_) async => users);
```

## Widget tests

```dart
await pumpApp(
  tester,
  // Provides the screen's Cubit, like the route does.
  BlocProvider<AlbumListCubit>(
    create: (BuildContext _) => AlbumListCubit(albumRepository: AlbumRepository(backend.createClient()))..load(),
    child: const AlbumListScreen(),
  ),
  size: const Size(400, 800),
);
await tester.pumpAndSettle();
```

- Screens with an app-bar `ThemeModeButton` also need a
  `BlocProvider<ThemeCubit>` (nest providers; do not add packages for
  `MultiBlocProvider` list types).
- The square loader is an endless Lottie animation: while it is on screen use
  `tester.pump(duration)`, not `pumpAndSettle()`.
- Find loaders with `find.byType(SquareLoader)`.
- Taps that should be blocked (busy screen, modal barrier) use
  `warnIfMissed: false`.
- Check responsive behaviour with `size:` (phone 400×800, desktop 1400×900)
  and `expect(tester.takeException(), isNull)` for overflows.
- Animations: sample positions with `tester.pump(Duration)` and compare
  (`tester.getTopLeft(...)`), optionally with
  `variant: TargetPlatformVariant.all()`.

## App-level tests

`test/app/` pumps the real `App` with the real router and DI:

```dart
await resetDependencies();
await configureDependencies(
  const AppConfig(),
  localStorage: InMemoryLocalStorage(),
  secureStorage: InMemorySecureStorage(),
  dio: backend.createDio(),
);
await tester.pumpWidget(const App(initialRoute: RouteNames.login));
```

Call `resetDependencies` in `tearDown`.

## Architecture rules test

`test/architecture_rules_test.dart` fails when the code uses `copyWith`,
Equatable, `setState`, `ChangeNotifier`, Dio outside `core/network`, a model
without `toString`, or a screen without a class doc comment. Extend it when you
add a checkable rule.
