import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_state.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/models/home_summary.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/widgets/home_summary_card.dart';

/// Summary cards; the only part of the dashboard that depends on loading.
///
/// Shows a loader, an error with a retry button, or the cards, depending on
/// the current `ViewStatus`.
class HomeSummaryGrid extends StatelessWidget {
  /// Creates the summary area. Needs a `HomeCubit` above it in the tree.
  const HomeSummaryGrid({super.key});

  /// Picks what to show for the current load status.
  @override
  Widget build(BuildContext context) {
    // Rebuilds the summary area when HomeCubit emits a new HomeBuildState.
    // buildWhen = buildStateChanged: effects (snackbar, dialog) reuse the
    // same build state, so they do not cause a useless rebuild.
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: buildStateChanged<HomeBuildState>,
      builder: (BuildContext context, HomeState state) {
        // Only the build part matters here; effects are handled elsewhere.
        final HomeBuildState build = state.build;
        switch (build.status) {
          // Not loaded yet: spinner with a fixed height so the page does not
          // jump when the cards appear.
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const SizedBox(height: 160, child: CommonLoader());
          // Load failed: message and a retry button that reloads fresh data.
          case ViewStatus.error:
            return SizedBox(
              height: 200,
              child: CommonErrorWidget(
                message: build.errorMessage ?? '',
                onRetry: () =>
                    context.read<HomeCubit>().load(forceRefresh: true),
              ),
            );
          // Loaded: the cards (a summary always exists once loaded, so `!`
          // is safe here).
          case ViewStatus.empty:
          case ViewStatus.loaded:
            return _SummaryCards(summary: build.summary!);
        }
      },
    );
  }
}

/// Lays the summary tiles out as 2, 3 or 6 columns depending on the available width.
///
/// Private because only [HomeSummaryGrid] uses it; it is purely visual.
class _SummaryCards extends StatelessWidget {
  /// Creates the tiles for [summary].
  const _SummaryCards({required this.summary});

  /// The numbers to display.
  final HomeSummary summary;

  /// Builds the six tiles and arranges them in rows.
  @override
  Widget build(BuildContext context) {
    // Completion rate as a whole percentage, e.g. 0.456 -> 46.
    final int percent = (summary.todoCompletionRate * 100).round();
    // The six statistic tiles, in display order.
    final List<HomeSummaryCard> cards = <HomeSummaryCard>[
      HomeSummaryCard(
        icon: Icons.people_outline,
        label: AppStrings.users,
        value: '${summary.userCount}',
      ),
      HomeSummaryCard(
        icon: Icons.article_outlined,
        label: AppStrings.posts,
        value: '${summary.postCount}',
      ),
      HomeSummaryCard(
        icon: Icons.comment_outlined,
        label: AppStrings.comments,
        value: '${summary.commentCount}',
      ),
      HomeSummaryCard(
        icon: Icons.photo_album_outlined,
        label: AppStrings.albums,
        value: '${summary.albumCount}',
      ),
      HomeSummaryCard(
        icon: Icons.pending_actions_outlined,
        label: '${AppStrings.todos} · ${AppStrings.pending}',
        value: '${summary.pendingTodoCount}',
      ),
      HomeSummaryCard(
        icon: Icons.task_alt_outlined,
        label: '${AppStrings.todos} · ${AppStrings.completed}',
        value: '${summary.completedTodoCount} ($percent%)',
      ),
    ];
    // LayoutBuilder gives the real available width, used to pick the
    // number of columns.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Space between tiles, both horizontally and vertically.
        final double gap = AppDimensions.gap;
        // Wide: 6 columns (one row), medium: 3, narrow: 2.
        final int columns = constraints.maxWidth >= 900
            ? 6
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        // Width that makes `columns` tiles plus their gaps fill one row.
        final double tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            // Each card gets the same width; its height follows its content.
            for (final HomeSummaryCard card in cards)
              SizedBox(width: tileWidth, child: card),
          ],
        );
      },
    );
  }
}
