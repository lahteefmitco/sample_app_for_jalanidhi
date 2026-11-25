import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';

/// A scrollable list that becomes a grid when there is room:
/// one column on phones, two on tablets, three or more on desktops.
///
/// The column count comes from the *available width* (LayoutBuilder), not the
/// window, so it also behaves inside split panes.
class ResponsiveListGrid extends StatelessWidget {
  /// Creates the list/grid; tiles are at least 360 px wide and 96 px high
  /// unless told otherwise.
  const ResponsiveListGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.minTileWidth = 360,
    this.tileHeight = 96,
    this.footer,
    this.controller,
  });

  /// Number of tiles to show.
  final int itemCount;

  /// Builds the tile at a given index.
  final IndexedWidgetBuilder itemBuilder;

  /// Narrowest a tile may be; decides how many columns fit.
  final double minTileWidth;

  /// Fixed height of every tile.
  final double tileHeight;

  /// Optional widget under the tiles (e.g. a "Load more" button).
  final Widget? footer;

  /// Optional scroll controller (e.g. to load more near the end).
  final ScrollController? controller;

  /// Builds the width-limited, scrollable grid.
  @override
  Widget build(BuildContext context) {
    return MaxWidthContainer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double padding = AppDimensions.pagePadding;
          final double spacing = AppDimensions.gap;
          // Width left for tiles once the side padding is removed.
          final double usable = constraints.maxWidth - padding * 2;
          // As many columns as fit, but always at least one.
          final int columns = math.max(1, (usable / minTileWidth).floor());
          return CustomScrollView(
            controller: controller,
            slivers: <Widget>[
              // The tiles, laid out in [columns] columns.
              SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    mainAxisExtent: tileHeight,
                  ),
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                ),
              ),
              // Optional footer below the last row.
              if (footer != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: padding),
                    child: Center(child: footer),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
