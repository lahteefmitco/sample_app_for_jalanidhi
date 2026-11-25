# UI guidelines

## Screen skeleton

```dart
class AlbumListScreen extends StatelessWidget {
  const AlbumListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // `read`: only callbacks/controllers; the content rebuilds in its own widget.
    final AlbumListCubit cubit = context.read<AlbumListCubit>();
    // Runs the Cubit's one-time effects (navigation, snackbars, dialogs, loader).
    return ScreenEffectListener<AlbumListCubit, AlbumListBuildState>(
      screenName: 'AlbumListScreen',
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.albums)), // back button never guarded
        body: BusyGuard<AlbumListCubit, AlbumListBuildState>(
          // Disabled while a request is running.
          child: Column(children: <Widget>[ /* header */, const Expanded(child: AlbumListView()) ]),
        ),
      ),
    );
  }
}
```

- The screen file only assembles widgets; each part lives in `widgets/`.
- The content widget switches on `ViewStatus`:
  `initial/loading → CommonLoader()`, `error → CommonErrorWidget(onRetry: ...)`,
  `empty → CommonEmptyView(...)`, `loaded → RefreshIndicator + ResponsiveListGrid`.
- Retry and pull-to-refresh call `load(forceRefresh: true)`.

## Core widgets to reuse (do not re-implement)

| Need | Widget / API |
|---|---|
| Content loading | `CommonLoader` (square loader) |
| Modal progress during a write | `showProgress()` / `hideProgress()` in the Cubit → `ProgressDialog` |
| Lock screen while busy | `BusyGuard<C, B>` |
| Effects (navigate, snackbar, dialog, sheet) | `ScreenEffectListener<C, B>` |
| Confirmation | `ShowConfirmationEffect` (→ `AppDialog.confirm`, `AppConfirmDialog`) |
| Item details sheet | `ShowInfoSheetEffect` |
| Any other dialog | `AppDialog.show<T>(context: ..., dialog: ...)` (called from a screen-specific effect handler) |
| Snackbars | `AppSnackbar` (via snackbar effects) |
| Error / empty state | `CommonErrorWidget`, `CommonEmptyView` |
| Buttons / fields | `CommonButton`, `CommonTextField` (controller + errorText from the Cubit) |
| Width cap | `MaxWidthContainer` (1100 px) |
| List ↔ grid | `ResponsiveListGrid(itemCount, itemBuilder, tileHeight, minTileWidth, footer)` |
| Theme switch | `ThemeModeButton` (app bar) |

Never use `CircularProgressIndicator`, `showDialog`, `AlertDialog` or custom
page routes in feature code.

## Forms

- Controllers live in the Cubit; fields get `errorText` from the BuildState.
- Validation uses `Validators` (`required`, `email`, `password`,
  `confirmPassword`) inside the Cubit's `submit()`.
- `onSubmitted` of the last field calls `cubit.submit()`; the busy guard makes
  repeated presses harmless.
- Use `DropdownButtonFormField(initialValue: ...)` for selections set once,
  with `onChanged` forwarding to the Cubit.

## Responsive layout

- Sizes come from `AppDimensions` (`pagePadding`, `gap`, `gapSmall`,
  `gapLarge`, `radius`, `iconSize`, `fontSmall/Body/Title/Headline`,
  `width(percent, min, max)`, `font(base)`). They wrap Sizer and clamp the
  result so desktops do not get huge paddings/fonts.
- Breakpoints: `Breakpoints.mobileMax` (599), `tabletMax` (1024),
  `maxContentWidth` (1100).
- Use `LayoutBuilder` when the layout depends on the available width (two
  columns at ≥ 800 px in detail screens, column count in grids).
- Long text: `maxLines` + `TextOverflow.ellipsis`. Check 320 px width and a
  wide desktop window in widget tests when a screen has a custom layout.

## Animations

- Page transitions: global (`SlideRightToLeftTransitionsBuilder` in
  `AppTheme`): forward right→left, back left→right. Nothing to do per screen.
- Dialogs: fade + pop-in scale (`AppDialog.transition`), dimmed background.
- Bottom sheets: rounded top, drag handle, eased slide-up.

## Theme

- Light/dark themes come from `AppTheme` (seed color `AppColors.seed`).
- Default theme mode = system; the user can force day/night with
  `ThemeModeButton` (persisted by `ThemeCubit`).
- Use `Theme.of(context).colorScheme` colors so both modes work; only status
  colors come from `AppColors`.

## Strings

All user-facing text lives in `AppStrings` (one place, ready for
localisation). Error texts for the network layer are there too.
