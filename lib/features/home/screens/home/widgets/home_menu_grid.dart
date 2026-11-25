import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/models/home_menu_item.dart';

/// Navigation menu: static items, so no BlocBuilder is needed.
///
/// Shows one tappable tile per [HomeCubit.menuItems] entry, in 2, 3 or 5
/// columns depending on the available width.
class HomeMenuGrid extends StatelessWidget {
  /// Creates the menu. Needs a `HomeCubit` above it in the tree.
  const HomeMenuGrid({super.key});

  /// Builds the tiles, sized to fill the available width evenly.
  @override
  Widget build(BuildContext context) {
    // Only used to forward taps; we never listen to the state here.
    final HomeCubit cubit = context.read<HomeCubit>();
    // LayoutBuilder gives us the real available width (not the screen
    // width), so the column count also fits inside MaxWidthContainer.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Space between tiles, both horizontally and vertically.
        final double gap = AppDimensions.gap;
        // Wide: 5 columns (all items in one row), medium: 3, narrow: 2.
        final int columns = constraints.maxWidth >= 900
            ? 5
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
            // One fixed-size tile per menu item.
            for (final HomeMenuItem item in HomeCubit.menuItems)
              SizedBox(
                width: tileWidth,
                height: 96,
                // Card + InkWell: the ripple is clipped to the card corners.
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => cubit.onMenuItemSelected(item),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Item icon in the primary color.
                        Icon(
                          item.icon,
                          size: AppDimensions.iconSize * 1.2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: AppDimensions.gapSmall),
                        // Item label.
                        Text(
                          item.label,
                          style: TextStyle(fontSize: AppDimensions.fontBody),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
