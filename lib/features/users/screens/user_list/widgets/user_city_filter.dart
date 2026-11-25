import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_list/cubit/user_list_state.dart';

/// Horizontally scrollable city chips used to filter the user list.
///
/// The first chip, "All cities", removes the filter.
class UserCityFilter extends StatelessWidget {
  /// Creates the row of city chips.
  const UserCityFilter({super.key});

  /// Builds the chips, or nothing while no cities are known yet.
  @override
  Widget build(BuildContext context) {
    // Read once (no rebuilds): only used to report the chosen city.
    final UserListCubit cubit = context.read<UserListCubit>();
    // Rebuilds when the header group changes: it needs both the list of
    // cities and the selected city. The list (content group) is ignored.
    return BlocSelector<UserListCubit, UserListState, UserListHeaderState>(
      selector: (UserListState state) => state.build.header,
      builder: (BuildContext context, UserListHeaderState header) {
        // Before the first load there are no cities: show nothing.
        if (header.cities.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 44,
          // Scrolls sideways when the chips do not fit the width.
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              // "All cities" chip: selected when no city is chosen.
              Padding(
                padding: EdgeInsets.only(right: AppDimensions.gapSmall),
                child: ChoiceChip(
                  label: const Text(AppStrings.allCities),
                  selected: header.selectedCity == null,
                  onSelected: (bool _) => cubit.onCityChanged(null),
                ),
              ),
              // One chip per city.
              for (final String city in header.cities)
                Padding(
                  padding: EdgeInsets.only(right: AppDimensions.gapSmall),
                  child: ChoiceChip(
                    label: Text(city),
                    selected: header.selectedCity == city,
                    onSelected: (bool _) => cubit.onCityChanged(city),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
