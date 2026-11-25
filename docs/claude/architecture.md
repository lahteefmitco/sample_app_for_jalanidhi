# Architecture guide

How a screen works end to end. Reference implementation:
`lib/features/albums/screens/album_list/` (simple list) and
`lib/features/posts/screens/post_form/` (form with a write request).

## 1. Layers and data flow

```
Widget ──calls──▶ Screen Cubit ──calls──▶ Repository ──calls──▶ ApiClient ──▶ Dio ──▶ API
  ▲                    │
  │  BuildState        │  emitBuild / emitEffect
  └──── BlocBuilder ◀──┘
        ScreenEffectListener (BlocListener) ◀── effects (navigation, snackbar, dialog, progress)
```

- **Widgets** render the BuildState and forward user actions to the Cubit.
- **Screen Cubit** (`ScreenCubit<B>`) owns business logic, controllers and
  the working data; emits BuildStates and one-time effects.
- **Repository** fetches/sends data through `ApiClient`, caches when useful,
  converts JSON to models. No Flutter UI imports.
- **ApiClient** (`core/network/api_client.dart`) is the only Dio user. It
  throws `ApiException` (network, timeout, badResponse, invalidResponse,
  cancelled, unknown) with a user-safe message.

## 2. ScreenState = BuildState + effect

```dart
typedef AlbumListState = ScreenState<AlbumListBuildState>;
```

| | BuildState (`state.build`) | Effect (`state.effect`) |
|---|---|---|
| Purpose | What the screen draws | Something that happens once |
| Examples | status, items, query, selected filter, field errors | navigate, pop, snackbar, confirm dialog, bottom sheet, progress |
| Emitted with | `emitBuild(...)` (inside `_render()`) | `navigateTo`, `showErrorMessage`, `showSuccessMessage`, `showProgress`, `hideProgress`, `emitEffect(...)` |
| Consumed by | `BlocBuilder(buildWhen: buildStateChanged)` / `BlocSelector` | `ScreenEffectListener` |

`effectId` increases for every effect, so an old effect is never replayed when
only the BuildState changes, and an effect never rebuilds widgets.

Screen-specific effects: subclass `UiEffect` in the screen's state file and
handle it with `ScreenEffectListener(onEffect: ...)` (return `true` when
handled).

## 3. Writing a Cubit (no copyWith)

```dart
class AlbumListCubit extends ScreenCubit<AlbumListBuildState> {
  AlbumListCubit({required this._albumRepository})
    : super(const AlbumListBuildState(), name: 'AlbumListCubit');

  final AlbumRepository _albumRepository;
  final TextEditingController searchController = TextEditingController();

  // Working data (private). The state is rebuilt from it.
  List<AlbumModel> _all = const <AlbumModel>[];
  ViewStatus _status = ViewStatus.initial;
  String? _errorMessage;

  void _render() {
    emitBuild(AlbumListBuildState(status: _status, /* ... */ errorMessage: _errorMessage));
  }

  @override
  Future<void> close() {
    searchController.dispose(); // dispose owned resources first
    return super.close();       // then cancel requests + close
  }
}
```

Rules:
- Every public method says (in its doc) which widget/action triggers it and
  what it emits.
- Status flow for data screens: `initial → loading → loaded | empty | error`
  (`ViewStatus`).
- On error: set `_status = ViewStatus.error`, `_errorMessage =
  ErrorHandler.messageFor(error)`, `_render()`, then
  `showErrorMessage(_errorMessage!)`.

### Grouped build states (complex screens)

When parts of a screen change independently, split the BuildState into
groups and keep unchanged group instances when emitting:

```dart
void _emitContent() => emitBuild(UserListBuildState(header: build.header, content: _content()));
void _emitAll()     => emitBuild(UserListBuildState(header: _header(), content: _content()));
```

Widgets select their group: `BlocSelector<UserListCubit, UserListState, UserListContentState>(selector: (UserListState s) => s.build.content, ...)`.
Selection works by identity, so never rebuild a group that did not change.

## 4. Loading data (read + cancellation + busy)

```dart
Future<void> load({bool forceRefresh = false}) async {
  // Cancels an earlier 'load' still running and marks the screen busy.
  final RequestToken token = startBlockingRequest('load');
  _status = ViewStatus.loading;
  _errorMessage = null;
  _render();
  try {
    _all = await _albumRepository.getAlbums(forceRefresh: forceRefresh, requestToken: token);
    _applyFilter(); // sets status loaded/empty and renders
  } on Object catch (error) {
    if (isCancellation(error)) {
      return; // screen closed or a newer load started: stay silent
    }
    _status = ViewStatus.error;
    _errorMessage = ErrorHandler.messageFor(error);
    _render();
    showErrorMessage(_errorMessage!);
  } finally {
    endBlockingRequest(token); // ignored automatically if the token was cancelled
  }
}
```

- Quiet secondary reads (e.g. refresh after returning from another page) use
  `newRequestToken('refresh')` without the busy flag.
- Parallel reads:

```dart
late final UserModel user;
late final List<PostModel> posts;
await Future.wait<void>(<Future<void>>[
  _userRepository.getUser(id, requestToken: token).then((UserModel v) { user = v; }),
  _postRepository.getPostsByUser(id, requestToken: token).then((List<PostModel> v) { posts = v; }),
]);
```

Never use record `.wait` (`(a, b).wait`): it throws `ParallelWaitError` and the
user would see "unexpected error" instead of e.g. "No internet connection".

## 5. Writing data (busy + progress, not cancellable)

```dart
Future<void> submit() async {
  if (isBusy) {
    return; // a request is already running: ignore double taps / Enter
  }
  // 1. validate into private error fields, _render(), return if invalid
  showProgress();                 // square loader + busy flag
  try {
    await _repository.create(...);
    hideProgress();
    emitEffect(const PopEffect('saved')); // or showSuccessMessage / navigateTo
  } on Object catch (error) {
    hideProgress();               // ALWAYS hide on failure too
    showError(error);
  }
}
```

Destructive actions ask first:

```dart
void onDeletePressed() => emitEffect(const ShowConfirmationEffect(
  actionId: 'delete', title: AppStrings.confirmDeletePostTitle,
  message: AppStrings.confirmDeletePostMessage, confirmLabel: AppStrings.delete,
  isDestructive: true,
));

@override
void onConfirmed(String actionId) { if (actionId == 'delete') _delete(); }
```

## 6. Navigation results

`navigateTo(RouteNames.x, arguments: ...)` pushes a page; when it closes,
`ScreenEffectListener` calls `cubit.onNavigationReturn(result)`. Use it to
refresh data (`'saved'`, `'deleted'` results) and to show the success snackbar
on the screen that is visible.

Modes: `NavigationStyle.push` (default), `.replace`, `.clearStack` (after
login/logout).

## 7. Repositories

```dart
class AlbumRepository {
  AlbumRepository(this._api);
  final ApiClient _api;
  List<AlbumModel>? _cache;

  Future<List<AlbumModel>> getAlbums({bool forceRefresh = false, RequestToken? requestToken}) async {
    final List<AlbumModel>? cached = _cache;
    if (!forceRefresh && cached != null) {
      return cached;
    }
    final ApiResponse<List<AlbumModel>> response = await _api.get<List<AlbumModel>>(
      ApiEndpoints.albums,
      parser: (Object? json) => parseList<AlbumModel>(json, AlbumModel.fromJson),
      requestToken: requestToken,
    );
    _cache = response.data;
    return response.data;
  }
}
```

- Shared by several screens → `global/repositories/` (lazy singleton).
- Used by one screen → `features/<f>/screens/<s>/repositories/`.
- Log with `repositoryLog(..., funtionName: 'AlbumRepository.getAlbums')`.
- When the backend does not persist writes (JSONPlaceholder), keep an
  in-memory overlay like `PostRepository`; with a real backend, drop it.

## 8. Dependency injection and routes

```dart
// dependency_injection.dart
void _registerAlbums() {
  getIt
    ..registerFactory<AlbumListCubit>(
      () => AlbumListCubit(albumRepository: getIt<AlbumRepository>()),
    )
    ..registerFactoryParam<AlbumDetailsCubit, AlbumModel, void>(
      (AlbumModel album, void _) => AlbumDetailsCubit(album: album, photoRepository: getIt<PhotoRepository>()),
    );
}

// app_routes.dart
case RouteNames.albumList:
  // Provides an AlbumListCubit and starts loading albums at once.
  page = BlocProvider<AlbumListCubit>(
    create: (BuildContext _) => getIt<AlbumListCubit>()..load(),
    child: const AlbumListScreen(),
  );
```

`BlocProvider` closes the Cubit when the route is removed, which cancels its
requests and disposes its controllers. Arguments: document the expected type
next to the route name in `RouteNames`.

## 9. Global state

- `ThemeCubit` (`global/cubits/theme/`) is the only global Cubit; its value is
  persisted in `LocalStorageService` and read by `App`.
- Shared *data* belongs in shared repositories, not global Cubits. Screen
  Cubits read repositories and copy what they need into their own state.

## 10. Platform-specific code

- Use `PlatformCapabilities` (`kIsWeb` / `defaultTargetPlatform`, no
  `dart:io`) to decide what is available.
- Wrap platform features behind an abstract interface + implementations (see
  `FirebaseService` / `NoopFirebaseService`); never crash on an unsupported
  platform.
