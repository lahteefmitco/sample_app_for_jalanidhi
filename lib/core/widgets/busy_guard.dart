import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';

/// Disables everything inside [child] while the screen's Cubit is busy.
///
/// "Busy" means a request is in progress (see `ScreenCubit.isBusy`). While it
/// is true the guard:
///  * ignores taps and drags (`AbsorbPointer`),
///  * removes keyboard focus, so nobody can type or press Enter
///    (`ExcludeFocus`),
///  * dims the content a little so the user can see it is locked.
///
/// This prevents, for example, tapping "Save" twice (two POST requests) or
/// deleting a post while it is being edited.
///
/// Put it around the screen body, not around the app bar's back button:
/// the user must always be able to leave a screen, which also cancels its
/// running read requests.
class BusyGuard<C extends ScreenCubit<B>, B> extends StatelessWidget {
  /// Creates a guard for the screen Cubit of type [C].
  const BusyGuard({super.key, required this.child});

  /// The part of the screen that gets disabled while busy.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The busy flag lives in the Cubit (not in its state), so a plain
    // ValueListenableBuilder is enough: it rebuilds only when the flag flips.
    final ScreenCubit<B> cubit = context.read<C>();
    return ValueListenableBuilder<bool>(
      valueListenable: cubit.busyListenable,
      builder: (BuildContext context, bool isBusy, Widget? staticChild) {
        return AbsorbPointer(
          absorbing: isBusy,
          child: ExcludeFocus(
            excluding: isBusy,
            child: AnimatedOpacity(
              opacity: isBusy ? 0.6 : 1,
              duration: const Duration(milliseconds: 150),
              child: staticChild,
            ),
          ),
        );
      },
      // The guarded content is built once by the screen, not on every flip.
      child: child,
    );
  }
}
