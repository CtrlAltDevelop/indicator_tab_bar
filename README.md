# indicator_tab_bar

[![pub package](https://img.shields.io/pub/v/indicator_tab_bar.svg)](https://pub.dev/packages/indicator_tab_bar)
[![pub points](https://img.shields.io/pub/points/indicator_tab_bar)](https://pub.dev/packages/indicator_tab_bar/score)
[![CI](https://github.com/CtrlAltDevelop/indicator_tab_bar/actions/workflows/ci.yml/badge.svg)](https://github.com/CtrlAltDevelop/indicator_tab_bar/actions/workflows/ci.yml)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/CtrlAltDevelop/indicator_tab_bar/blob/main/LICENSE)

A tab indicator that draws a **short bar of a fixed width** under the tab
instead of one stretched across it, and a **sliver `AnimatedSwitcher`** for
cross-fading the body each tab selects.

Nothing here imports Material. `TabBar.indicator` takes a plain `Decoration`,
so the indicator works the same whether the `TabBar` comes from
`package:flutter/material.dart` or from the `material_ui` fork — and the sliver
switcher is pure `flutter/widgets`. No assets, no other pub.dev dependency.

![The indicator at five shapes and placements, light and dark](screenshots/indicator.png)

## Install

```bash
flutter pub add indicator_tab_bar
```

Or add it to `pubspec.yaml` yourself — it is a runtime dependency:

```yaml
dependencies:
  indicator_tab_bar: ">=1.2.0 <2.0.0"
```

Requires Flutter 3.44.0 or newer, and so Dart 3.12.0 or newer — that is the
Flutter release which ships it.

## `LineTabIndicator`

`TabBar` sizes its indicator from `TabBarIndicatorSize`, which offers a choice
between the width of the whole tab and the width of its label — both of which
move as the labels do. This one is neither: `indicatorWidth` is the width it
draws, whatever the tab underneath measures, so a row of tabs with labels of
very different lengths still gets underlines of one length.

```dart
TabBar(
  isScrollable: true,
  tabAlignment: TabAlignment.start,
  indicatorSize: TabBarIndicatorSize.label,
  indicator: LineTabIndicator(
    color: theme.colorScheme.primary,
    strokeWidth: 3,
    indicatorWidth: 20,
    radius: 4,
  ),
  tabs: const [
    Tab(text: 'Spot'),
    Tab(text: 'Futures & derivatives'),
    Tab(text: 'Earn'),
  ],
)
```

The bar is a rounded rectangle `strokeWidth` tall and **exactly**
`indicatorWidth` wide, placed inside the tab by `alignment` — bottom centre
unless told otherwise — within the rect `insets` leaves. A tab narrower than the
bar gets one that overhangs it evenly on both sides.

| | |
|---|---|
| `color` | what the bar is filled with |
| `gradient` | fills it in place of `color` — see below — default `null` |
| `strokeWidth` | its height — default `3` |
| `indicatorWidth` | its width, independent of the tab — default `50` |
| `radius` | its corner radius, clamped to `strokeWidth / 2` — default `0`, square ends |
| `alignment` | where it sits in the tab — default `Alignment.bottomCenter` |
| `insets` | deflates the rect it is aligned within — default `EdgeInsets.zero` |

`radius` is clamped because past half the height there is nothing left to
round: at or above `strokeWidth / 2` the ends are already semicircles. So
`radius: 4` on a 3-tall bar and `radius: 999` on the same bar draw the same
pill, and the second screenshot row above — `radius: 0` — is the only shape
that reads differently at that thickness.

### Placement

`alignment` and `insets` decide where in the tab the bar lands, and the default
pair — `Alignment.bottomCenter` with no insets — is the underline sitting flush
on the bottom edge.

```dart
LineTabIndicator(
  color: theme.colorScheme.primary,
  indicatorWidth: 20,
  radius: 4,
  // Lift it clear of the bottom edge, so the TabBar divider shows beneath.
  insets: const EdgeInsets.only(bottom: 6),
  // Tuck it under the leading edge of the label instead of centring it;
  // the directional form flips with the reading direction.
  alignment: AlignmentDirectional.bottomStart,
)
```

`Alignment.topCenter` makes it an overline instead, for a `TabBar` that sits
below what it selects, and `Alignment.center` strikes through the label.

### Gradient

`LineTabIndicator.gradient` fills the bar with a `Gradient` rather than a flat
colour. The gradient is laid out across **the bar**, not across the tab, so a
`LinearGradient` runs over exactly `indicatorWidth` logical pixels no matter how
wide the tab is.

```dart
LineTabIndicator.gradient(
  gradient: LinearGradient(
    colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
  ),
  indicatorWidth: 40,
  strokeWidth: 4,
  radius: 2,
)
```

The shader is rebuilt only when the bar moves, so a gradient indicator sliding
between tabs costs one shader per frame of the slide and none while it rests.

### Value semantics

Two indicators with the same fields are `==`, so `TabBar` does not repaint on a
rebuild that changes nothing, and `Decoration.lerp` interpolates every field —
alignment, insets and gradient included — so it animates across a theme change.
A lerp against `null` fades the fill towards transparent without moving the bar.

## `SliverAnimatedSwitcher`

When the tab body is a **sliver** inside a `CustomScrollView` — a `SliverList`
under a `SliverAppBar`, say — the plain `AnimatedSwitcher` cannot be used, twice
over: it stacks its children in a `Stack`, which is a box, and it wraps them in
box transitions. This keeps the same driving animation but lays the incoming
sliver out on its own and fades it with a `SliverFadeTransition`.

```dart
CustomScrollView(
  slivers: [
    const SliverAppBar(title: Text('History'), pinned: true),
    SliverAnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      child: SliverList.list(
        // The key is what marks this as a *different* sliver.
        key: ValueKey(tab),
        children: rows,
      ),
    ),
  ],
)
```

![The switcher half way through a fade](screenshots/sliver_switcher.png)

As with `AnimatedSwitcher`, the swap is detected by `Widget.canUpdate`: two
slivers of the same runtime type with the same key are the *same* sliver
updated, and nothing animates. Give each branch its own `Key` when they share a
type, as the `SliverList` above does.

`transitionBuilder` replaces the fade with something else — anything that
returns a sliver, so `SliverOpacity` and friends, not `FadeTransition`.

### Only the incoming sliver animates

Slivers cannot be overlaid — there is no sliver `Stack` to hold the old one
over the new — so the outgoing sliver is removed the moment the swap begins,
and what you see is the incoming one fading up in the space it leaves. That is
why there is no `switchOutCurve` or `reverseDuration` here: there would be no
outgoing animation for them to shape.

## Example

`example/` is a runnable app: a scrollable `TabBar` with the indicator under
it, live controls for every field — the three metrics, the inset, the placement
and the gradient — and a `CustomScrollView` whose body sliver is swapped per
tab.

```bash
cd example && flutter run
```

The images above are rendered from the real widgets, so they can be
regenerated whenever the package changes:

```bash
cd example && flutter test --update-goldens test/screenshots_test.dart
```

## Licence

MIT — see [LICENSE](LICENSE).
