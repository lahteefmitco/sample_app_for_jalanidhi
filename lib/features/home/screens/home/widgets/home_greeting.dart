import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_state.dart';

/// `Welcome, name` headline; rebuilds only when the user name changes.
class HomeGreeting extends StatelessWidget {
  /// Creates the greeting. Needs a `HomeCubit` above it in the tree.
  const HomeGreeting({super.key});

  /// Builds the headline from the user name selected out of the state.
  @override
  Widget build(BuildContext context) {
    // Picks only `userName` out of HomeState. BlocSelector rebuilds only when
    // the selected value changes, so loading the summary or emitting an
    // effect does not rebuild the greeting.
    return BlocSelector<HomeCubit, HomeState, String>(
      selector: (HomeState state) => state.build.userName,
      builder: (BuildContext context, String userName) {
        // Plain "Welcome" until the name is known.
        return Text(
          userName.isEmpty ? 'Welcome' : 'Welcome, $userName',
          style: TextStyle(
            fontSize: AppDimensions.fontHeadline,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }
}
