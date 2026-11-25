import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/widgets/theme_mode_button.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_state.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/widgets/home_greeting.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/widgets/home_menu_grid.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/widgets/home_summary_grid.dart';

/// Dashboard: greeting, summary cards and the navigation menu.
///
/// * App bar: theme switch and logout (logout asks for confirmation).
/// * Pull to refresh reloads every number.
/// * Content is capped to a maximum width so it never stretches on desktop.
/// The summary cards rebuild by themselves when the data loads; the menu is
/// static.
class HomeScreen extends StatelessWidget {
  /// Creates the dashboard. The `HomeCubit` must already be provided above
  /// it (the route does that).
  const HomeScreen({super.key});

  /// Builds the static page layout; only the greeting and the summary grid
  /// rebuild when the state changes.
  @override
  Widget build(BuildContext context) {
    // The Cubit is created by the route (see AppRoutes) and closed with it.
    final HomeCubit cubit = context.read<HomeCubit>();
    // Shared style of the "Summary" and "Navigation" section titles.
    final TextStyle titleStyle = TextStyle(
      fontSize: AppDimensions.fontTitle,
      fontWeight: FontWeight.w600,
    );
    // Listens to HomeCubit and executes its one-time effects (snackbars,
    // logout confirmation dialog, navigation). It does not rebuild the page.
    return ScreenEffectListener<HomeCubit, HomeBuildState>(
      screenName: 'HomeScreen',
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConstants.appName),
          actions: <Widget>[
            // Day / Night / System theme switch.
            const ThemeModeButton(),
            // Logout button; the Cubit first asks for confirmation.
            BusyGuard<HomeCubit, HomeBuildState>(
              // App-bar action: disabled while a request is running.
              child: IconButton(
                tooltip: AppStrings.logout,
                icon: const Icon(Icons.logout),
                onPressed: cubit.onLogoutPressed,
              ),
            ),
          ],
        ),
        // Pull-to-refresh reloads the summary from the API.
        body: BusyGuard<HomeCubit, HomeBuildState>(
          // Disabled while a request is running.
          child: RefreshIndicator(
            onRefresh: () => cubit.load(forceRefresh: true),
            // Keeps the content readable on wide (desktop / web) screens.
            child: MaxWidthContainer(
              child: ListView(
                // Always scrollable, so pull-to-refresh works even when the
                // content is shorter than the screen.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(AppDimensions.pagePadding),
                children: <Widget>[
                  // "Welcome, <name>".
                  const HomeGreeting(),
                  SizedBox(height: AppDimensions.gapLarge),
                  // "Summary" section title.
                  Text(AppStrings.summary, style: titleStyle),
                  SizedBox(height: AppDimensions.gap),
                  // Totals for users, posts, comments, albums and todos.
                  const HomeSummaryGrid(),
                  SizedBox(height: AppDimensions.gapLarge),
                  // "Navigation" section title.
                  Text(AppStrings.navigation, style: titleStyle),
                  SizedBox(height: AppDimensions.gap),
                  // Shortcuts to the feature screens.
                  const HomeMenuGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
