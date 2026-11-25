import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/models/home_summary.dart';

/// What the dashboard renders: status, user name and the summary numbers.
///
/// It is immutable: `HomeCubit` creates a new instance for every change.
/// Snackbars, dialogs and navigation are one-time effects, not part of it.
@immutable
class HomeBuildState {
  /// Creates the state; the defaults describe a dashboard that has not
  /// started loading yet.
  const HomeBuildState({
    this.status = ViewStatus.initial,
    this.userName = '',
    this.summary,
    this.errorMessage,
  });

  /// Which part of the summary area to show: loader, error or the cards.
  final ViewStatus status;

  /// Name used in the greeting; empty when unknown.
  final String userName;

  /// Totals for the summary cards; `null` until the first successful load.
  final HomeSummary? summary;

  /// Error text shown in the summary area when [status] is `error`.
  final String? errorMessage;

  /// Readable description used in logs and while debugging.
  @override
  String toString() =>
      'HomeBuildState(status: $status, userName: $userName, '
      'summary: $summary, errorMessage: $errorMessage)';
}

/// Full state of the home screen: the [HomeBuildState] plus the one-time
/// effect. Short name for `BlocBuilder<HomeCubit, HomeState>`.
typedef HomeState = ScreenState<HomeBuildState>;
