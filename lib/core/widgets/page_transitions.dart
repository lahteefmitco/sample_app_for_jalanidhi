import 'package:material_ui/material_ui.dart';

/// Page animation used for every screen change in the app.
///
/// * **Forward** (push): the new page slides in from the RIGHT edge towards the
///   LEFT, while the page below slides a little to the left (a "parallax"
///   effect that makes the movement feel deeper).
/// * **Backward** (pop / back button): the exact reverse. The top page slides
///   out to the RIGHT (left-to-right movement) and the page below slides back
///   into place.
///
/// It is registered once in `AppTheme` (`pageTransitionsTheme`), so every
/// `MaterialPageRoute` created by `AppRoutes` uses it automatically.
class SlideRightToLeftTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates the builder. It has no options.
  const SlideRightToLeftTransitionsBuilder();

  /// How far the page below moves to the left while a page covers it, as a
  /// fraction of the screen width (0.25 = a quarter of the width).
  static const double _backgroundShift = 0.25;

  /// Duration of the forward animation.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  /// Going back is a little faster than going forward, which feels snappier.
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 320);

  /// Wraps [child] (the page) with the slide animations.
  ///
  /// [animation] runs from 0 to 1 when [route] is pushed and from 1 to 0 when
  /// it is popped. [secondaryAnimation] does the same for the page BELOW the
  /// route: it runs 0 to 1 when another page is pushed on top of [route].
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Decelerates when entering, accelerates when leaving.
    final CurvedAnimation enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    // Same idea for the page that is being covered.
    final CurvedAnimation cover = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // This page entering from the right (and leaving to the right on pop).
    final Animation<Offset> enterPosition = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(enter);

    // This page being pushed to the left when another page covers it.
    final Animation<Offset> coverPosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-_backgroundShift, 0),
    ).animate(cover);

    return SlideTransition(
      position: coverPosition,
      child: SlideTransition(
        position: enterPosition,
        // A soft shadow on the left edge separates the sliding page from the
        // page below it.
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0x33000000),
                blurRadius: 16,
                offset: const Offset(-4, 0),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
