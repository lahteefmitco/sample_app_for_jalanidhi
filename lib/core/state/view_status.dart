/// Content status shared by the BuildStates of data-driven screens.
///
/// The screen picks what to show from it: a loader, the data, an empty
/// view or an error view.
enum ViewStatus {
  /// Nothing has been requested yet.
  initial,

  /// Data is being fetched; show a loader.
  loading,

  /// Data arrived and there is something to show.
  loaded,

  /// Data arrived but the list is empty (or nothing matches the filter).
  empty,

  /// Loading failed; show an error with a retry button.
  error,
}
