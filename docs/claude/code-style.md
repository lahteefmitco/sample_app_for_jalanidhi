# Code style

The code must be readable by junior developers. `analysis_options.yaml`
enforces part of this (`always_specify_types`, `always_declare_return_types`,
`public_member_api_docs`, strict casts/inference/raw types); the rest is by
convention.

## Types

```dart
// Good
final List<UserModel> users = <UserModel>[];
final Map<int, String> authors = <int, String>{};
final String query = _query.trim();
users.where((UserModel user) => user.name.containsIgnoreCase(query));
onSubmitted: (String _) => cubit.submit(),
BlocBuilder<UserDetailsCubit, UserDetailsState>(
  builder: (BuildContext context, UserDetailsState state) { ... },
)

// Bad
final users = [];
var query = _query.trim();
users.where((user) => ...);
onSubmitted: (_) => cubit.submit(),
BlocBuilder(builder: (context, state) { ... })
```

- Every function, method, getter and local function declares a return type.
- Generic constructors and literals always get type arguments:
  `BlocProvider<LoginCubit>(`, `MapEntry<String, String>(`,
  `PopupMenuItem<int?>(`, `Future<void>.delayed(`, `const <Widget>[]`.
- Dependency fields are private and injected with private named parameters:
  `PostListCubit({required this._postRepository, required this._userRepository})`.
- No `copyWith`, no Equatable. Create new instances with constructors.

## Documentation

- `///` on every class, constructor, field, getter, method, enum value,
  typedef and top-level function — public **and private**.
- Explain *why* or *what for*, not the name again:
  - ✅ `/// Users that pass the search and city filter, in the chosen order.`
  - ❌ `/// The visible users.`
- Cubit methods: which user action triggers them, what they emit.
- Inside `build`: a `//` line above each section and on every
  `BlocProvider` / `BlocBuilder` / `BlocSelector` / `BlocListener` /
  `ScreenEffectListener` / `BusyGuard`, saying what it rebuilds or listens to
  and why its `buildWhen` / `selector` is what it is.
- Non-obvious locals get a short `//` comment.
- Keep comments short (1–3 lines). Update them when the code changes.

## Naming

| Thing | Convention | Example |
|---|---|---|
| Screen | `<Name>Screen` | `UserListScreen` |
| Cubit / state | `<Name>Cubit`, `<Name>BuildState`, `typedef <Name>State` | `UserListCubit` |
| Model | `<Name>Model` | `PostModel` |
| Repository | `<Name>Repository` | `PostRepository` |
| Files | `snake_case.dart`, folder per screen | `user_list/cubit/user_list_cubit.dart` |
| Request purposes | short strings / constants | `'load'`, `_refreshRequest` |
| Confirmation ids | constant strings | `'delete'`, `'delete:12'` |

## Imports

- `package:material_ui/material_ui.dart` for widgets (not
  `package:flutter/material.dart`); `package:flutter/foundation.dart` for
  `@immutable`, `kDebugMode`, `ValueNotifier`.
- Always absolute `package:<app>/...` imports in `lib/`.
- Only `core/network/*` and `app/dependency_injection.dart` import Dio.
- Do not import a package that is not a direct dependency.

## Logging

```dart
screenLog('UserListScreen initialised', funtionName: 'initState');
cubitLog('filtered 3/10 users', funtionName: '_applyFilters');
repositoryLog('getUsers: fetching', funtionName: 'UserRepository.getUsers');
errorLog('$error', funtionName: 'ErrorHandler.messageFor');
generalLog('initialised', funtionName: 'AppInitializer.initialize');
```

- Use the function that matches the layer; keep the `funtionName` name (it is
  part of the logging contract).
- Logs only print in debug mode. Never log passwords, tokens, auth headers or
  personal data. Cubit state changes are logged by `AppBlocObserver`, so
  BuildState `toString()` must stay short (counts, not whole lists).

## Errors

- Throw `AppException` subclasses (`AuthException`, `StorageException`,
  `ApiException`) with user-safe messages.
- Convert anything else with `ErrorHandler.messageFor(error)`.
- Catch with `on Object catch (error)`; the first line handles cancellation in
  read requests.
