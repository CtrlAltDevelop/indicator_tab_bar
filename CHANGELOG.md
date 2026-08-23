# Changelog

## 1.0.0

- First release.
- `LineTabIndicator` — a `TabBar.indicator` decoration that draws a bar of a
  fixed `indicatorWidth`, centred on the bottom edge of the tab, rather than
  one sized to the tab or to its label. A tab narrower than the bar gets one
  that overhangs it evenly.
- The bar is a rounded rectangle `strokeWidth` tall and exactly
  `indicatorWidth` wide, with `radius` clamped to `strokeWidth / 2` — past half
  the height the ends are already semicircles and there is nothing left to
  round.
- Value semantics: `==`, `hashCode`, `copyWith`, `debugFillProperties`, and
  `lerpFrom`/`lerpTo` over every field, so the indicator animates across a
  theme change and a rebuild that changes nothing does not repaint.
- `hitTest` and `getClipPath` describe the bar itself, not the whole rect it
  was laid out in.
- `SliverAnimatedSwitcher` — an `AnimatedSwitcher` for slivers, for a tab body
  living in a `CustomScrollView`. The plain one stacks its children in a `Stack`
  and wraps them in box transitions, neither of which a sliver survives.
- Only the incoming sliver animates: slivers cannot be overlaid, so the
  outgoing one is dropped as the swap begins. `switchOutCurve` and
  `reverseDuration` are deliberately absent rather than present and inert.
- `transitionBuilder` for a transition other than the default
  `SliverFadeTransition`.
- No Material import anywhere in `lib/`. `TabBar.indicator` takes a plain
  `Decoration`, so the indicator serves a `TabBar` from
  `package:flutter/material.dart` and one from the `material_ui` fork alike.
- README images are generated from the real widgets by
  `example/test/screenshots_test.dart`.
