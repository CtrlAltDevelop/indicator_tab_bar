/// A fixed-width tab indicator, and a sliver [AnimatedSwitcher] for the body
/// each tab selects.
///
/// [LineTabIndicator] goes on `TabBar.indicator` and draws a short bar of a
/// set width centred under the tab, rather than one stretched across the tab
/// or across its label:
///
/// ```dart
/// TabBar(
///   indicatorSize: TabBarIndicatorSize.label,
///   indicator: const LineTabIndicator(
///     color: Color(0xFF2F6BFF),
///     strokeWidth: 3,
///     indicatorWidth: 20,
///     radius: 4,
///   ),
///   tabs: const [Tab(text: 'Spot'), Tab(text: 'Futures')],
/// )
/// ```
///
/// [SliverAnimatedSwitcher] cross-fades what that tab reveals, when the body
/// is a sliver inside a `CustomScrollView` rather than a box:
///
/// ```dart
/// SliverAnimatedSwitcher(
///   child: SliverList.list(key: ValueKey(tab), children: rows),
/// )
/// ```
///
/// Nothing here imports Material. `TabBar.indicator` takes a plain
/// [Decoration], so the indicator works the same whether the `TabBar` comes
/// from `package:flutter/material.dart` or from the `material_ui` fork.
///
/// @docImport 'package:flutter/widgets.dart';
library;

export 'src/line_tab_indicator.dart';
export 'src/sliver_animated_switcher.dart';
