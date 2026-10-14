import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Builds the transition wrapped around an incoming sliver.
///
/// The sliver returned must itself be a sliver — [SliverFadeTransition],
/// [SliverOpacity] and friends qualify; [FadeTransition] does not.
typedef SliverAnimatedSwitcherTransitionBuilder =
    Widget Function(Widget sliver, Animation<double> animation);

/// An [AnimatedSwitcher] for slivers: swap [child] for another sliver and the
/// new one fades in, in place, inside a `CustomScrollView`.
///
/// The plain [AnimatedSwitcher] cannot be used here twice over — it stacks its
/// children in a [Stack], which is a box, and it wraps them in box transitions.
/// This widget keeps the same driving animation but lays the incoming sliver
/// out on its own and fades it with a [SliverFadeTransition].
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     const SliverAppBar(title: Text('History')),
///     SliverAnimatedSwitcher(
///       child: switch (tab) {
///         Tab.orders => SliverList.list(key: const ValueKey('orders'), ...),
///         Tab.trades => SliverList.list(key: const ValueKey('trades'), ...),
///       },
///     ),
///   ],
/// )
/// ```
///
/// As with [AnimatedSwitcher], the swap is detected by [Widget.canUpdate] — two
/// slivers of the same runtime type with the same key are the *same* sliver
/// updated, and nothing animates. Give each branch its own [Key] when they
/// share a type, as the two [SliverList]s above do.
///
/// ## Only the incoming sliver animates
///
/// Slivers cannot be overlaid — there is no sliver [Stack] to hold the old one
/// over the new — so the outgoing sliver is removed as soon as the swap
/// begins, and what you see is the incoming one fading up in the space it
/// leaves. That is why there is no `switchOutCurve` or `reverseDuration` here:
/// there is no outgoing animation for them to shape.
///
/// When the platform asks for reduced motion (`MediaQuery.disableAnimations`)
/// the swap is immediate, and [duration] is not waited on.
class SliverAnimatedSwitcher extends StatelessWidget {
  /// Creates a switcher that fades between slivers.
  const SliverAnimatedSwitcher({
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.switchInCurve = Curves.linear,
    this.transitionBuilder = defaultTransitionBuilder,
    super.key,
  });

  /// The sliver currently shown.
  ///
  /// Replacing it with a sliver [Widget.canUpdate] rejects starts the swap.
  final Widget child;

  /// How long the incoming sliver takes to appear.
  final Duration duration;

  /// The curve the incoming sliver's animation is driven along.
  final Curve switchInCurve;

  /// Wraps the incoming sliver in its transition.
  ///
  /// Defaults to [defaultTransitionBuilder], a [SliverFadeTransition]. A
  /// replacement must return a sliver.
  final SliverAnimatedSwitcherTransitionBuilder transitionBuilder;

  /// Fades the incoming sliver in with a [SliverFadeTransition].
  static Widget defaultTransitionBuilder(
    Widget sliver,
    Animation<double> animation,
  ) {
    return SliverFadeTransition(opacity: animation, sliver: sliver);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      // Reduce-motion users get the swap at once, as `MaterialApp` page
      // transitions do for them.
      duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
          ? Duration.zero
          : duration,
      switchInCurve: switchInCurve,
      transitionBuilder: transitionBuilder,
      // Drop the outgoing slivers rather than stacking them: `AnimatedSwitcher`
      // defaults to a `Stack`, and a box cannot hold a sliver.
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) =>
          currentChild ?? const SliverToBoxAdapter(),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<Duration>(
          'duration',
          duration,
          defaultValue: const Duration(milliseconds: 200),
        ),
      )
      ..add(
        DiagnosticsProperty<Curve>(
          'switchInCurve',
          switchInCurve,
          defaultValue: Curves.linear,
        ),
      );
  }
}
