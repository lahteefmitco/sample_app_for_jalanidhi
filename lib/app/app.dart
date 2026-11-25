import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/app/app_routes.dart';
import 'package:sample_app_for_jalanidhi/app/app_theme.dart';
import 'package:sample_app_for_jalanidhi/app/dependency_injection.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_cubit.dart';
import 'package:sample_app_for_jalanidhi/global/cubits/theme/theme_state.dart';
import 'package:sizer/sizer.dart';

/// Root widget: provides the global [ThemeCubit], initialises Sizer once and
/// builds the [MaterialApp] with the user's theme choice.
class App extends StatelessWidget {
  /// Creates the root widget that opens [initialRoute] first.
  const App({super.key, required this.initialRoute});

  /// First route to open (login or home, decided by `AppInitializer`).
  final String initialRoute;

  /// Builds the provider, Sizer and [MaterialApp] stack of the whole app.
  @override
  Widget build(BuildContext context) {
    // Provides the global ThemeCubit to the whole app.
    // `.value` because ThemeCubit is a GetIt singleton: the provider must
    // not close it when the widget tree is torn down.
    return BlocProvider<ThemeCubit>.value(
      value: getIt<ThemeCubit>(),
      // Sizer is initialised once at the root; every screen can use .w/.h/.sp.
      child: Sizer(
        maxMobileWidth: Breakpoints.mobileMax,
        maxTabletWidth: Breakpoints.tabletMax,
        builder:
            (
              BuildContext context,
              Orientation orientation,
              ScreenType screenType,
            ) {
              // Rebuilds only the MaterialApp, and only when the theme mode
              // changes (buildWhen ignores any other state change).
              return BlocBuilder<ThemeCubit, ThemeState>(
                buildWhen: (ThemeState previous, ThemeState current) =>
                    previous.mode != current.mode,
                builder: (BuildContext context, ThemeState themeState) {
                  // The app itself: themes, routing and the first route.
                  return MaterialApp(
                    title: AppConstants.appName,
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light(),
                    darkTheme: AppTheme.dark(),
                    // system (default) / light (day) / dark (night)
                    themeMode: themeState.mode,
                    initialRoute: initialRoute,
                    // Open exactly ONE page. Without this, Flutter (on the web
                    // especially) first builds a "/" route below "/login", which
                    // gives the login page a back arrow to nowhere.
                    onGenerateInitialRoutes: (String initialRouteName) {
                      return <Route<Object?>>[
                        AppRoutes.onGenerateRoute(
                          RouteSettings(name: initialRouteName),
                        ),
                      ];
                    },
                    onGenerateRoute: AppRoutes.onGenerateRoute,
                  );
                },
              );
            },
      ),
    );
  }
}
