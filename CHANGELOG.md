# Changelog

## 1.2.1

- No change to the published code. CI now runs on `macos-latest`, the platform
  the example's screenshot goldens are recorded on, so they no longer fail over
  pixels nobody changed.

## 1.2.0

- Fixed: `LineTabIndicator.lerp` no longer trips the non-negative asserts on
  `strokeWidth`, `indicatorWidth` or `radius` when an overshooting curve
  (`elasticOut`, `easeOutBack`) drives `t` outside 0..1; they are floored at 0.
- Fixed: a gradient bar repainted with the same rect but a different text
  direction no longer reuses a shader built for the old direction, so
  directional gradients (`AlignmentDirectional`, `GradientRotation`) follow the
  reading direction.
- CI moved to the shared reusable workflow in CtrlAltDevelop/ci-workflows:
  formatting, `analyze --fatal-infos`, the tests, the example, a changelog
  entry per version, and a pana score with no points lost.
- Dependency bounds are explicit ranges rather than carets — a floor that
  resolves on the supported SDK, the next major as the ceiling — so a consumer
  already on an older version in the same major is not forced to move.
- The README carries the pub, pub points, CI and licence badges the other
  packages here carry.

## 1.1.0

- `LineTabIndicator.alignment` — where the bar sits inside the tab. It still
  defaults to `Alignment.bottomCenter`, so nothing moves unless you ask;
  `Alignment.topCenter` makes it an overline for a `TabBar` below what it
  selects, and `AlignmentDirectional.bottomStart` tucks it under the leading
  edge of the label and flips with the reading direction.
- `LineTabIndicator.insets` — deflates the rect the bar is aligned within, so
  an underline can be lifted clear of the bottom edge and let the `TabBar`
  divider show beneath it.
- `LineTabIndicator.gradient` constructor — fills the bar with a `Gradient`
  instead of a flat colour. The gradient is laid out across the bar itself, not
  across the tab, so it runs over exactly `indicatorWidth` logical pixels, and
  its shader is rebuilt only when the bar moves.
- `hitTest`, `getClipPath` and painting now resolve `TextDirection`, falling
  back to `TextDirection.ltr` for callers that have none to give.
- A null side of `lerp` now fades the fill towards transparent without moving
  the bar, gradients included, instead of lerping the colour alone.
- `copyWith`, `==`, `hashCode` and `debugFillProperties` cover the new fields.

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
