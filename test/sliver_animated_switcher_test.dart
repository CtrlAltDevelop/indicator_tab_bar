import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indicator_tab_bar/indicator_tab_bar.dart';

/// A `CustomScrollView` whose one body sliver is the switcher.
Widget _scroller(Widget sliver, {Duration? duration, Curve? curve}) {
  return MaterialApp(
    home: CustomScrollView(
      slivers: <Widget>[
        const SliverToBoxAdapter(child: Text('header')),
        SliverAnimatedSwitcher(
          duration: duration ?? const Duration(milliseconds: 200),
          switchInCurve: curve ?? Curves.linear,
          child: sliver,
        ),
      ],
    ),
  );
}

Widget _page(String label) {
  return SliverToBoxAdapter(
    key: ValueKey<String>(label),
    child: SizedBox(height: 100, child: Text(label)),
  );
}

/// The opacity the incoming sliver is currently drawn at.
double _opacity(WidgetTester tester) {
  return tester
      .widget<SliverFadeTransition>(find.byType(SliverFadeTransition))
      .opacity
      .value;
}

void main() {
  testWidgets('lays its sliver out inside a CustomScrollView', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_scroller(_page('orders')));

    expect(find.text('header'), findsOneWidget);
    expect(find.text('orders'), findsOneWidget);
    // Directly under the header, not stacked over it.
    expect(tester.getTopLeft(find.text('orders')).dy, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fades the incoming sliver in over the duration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _scroller(_page('orders'), duration: const Duration(milliseconds: 200)),
    );
    expect(_opacity(tester), 1.0);

    await tester.pumpWidget(
      _scroller(_page('trades'), duration: const Duration(milliseconds: 200)),
    );
    await tester.pump();
    expect(_opacity(tester), 0.0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester), closeTo(0.5, 0.01));

    await tester.pump(const Duration(milliseconds: 100));
    expect(_opacity(tester), 1.0);
  });

  testWidgets('the outgoing sliver leaves at once — nothing is stacked', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_scroller(_page('orders')));
    await tester.pumpWidget(_scroller(_page('trades')));
    await tester.pump();

    expect(find.text('orders'), findsNothing);
    expect(find.text('trades'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('trades'), findsOneWidget);
  });

  testWidgets('a sliver that only updates does not re-animate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _scroller(
        const SliverToBoxAdapter(
          key: ValueKey<String>('body'),
          child: Text('a'),
        ),
      ),
    );
    await tester.pumpWidget(
      _scroller(
        const SliverToBoxAdapter(
          key: ValueKey<String>('body'),
          child: Text('b'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('b'), findsOneWidget);
    expect(
      _opacity(tester),
      1.0,
      reason: 'same key, so it was updated in place',
    );
  });

  testWidgets('switchInCurve shapes the fade', (WidgetTester tester) async {
    Widget build(String label) => _scroller(
      _page(label),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInCubic,
    );

    await tester.pumpWidget(build('orders'));
    await tester.pumpWidget(build('trades'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      _opacity(tester),
      lessThan(0.4),
      reason: 'easeInCubic is well under linear at the halfway point',
    );
  });

  testWidgets('a custom transitionBuilder replaces the fade', (
    WidgetTester tester,
  ) async {
    Widget build(String label) => MaterialApp(
      home: CustomScrollView(
        slivers: <Widget>[
          SliverAnimatedSwitcher(
            transitionBuilder: (Widget sliver, Animation<double> animation) =>
                SliverOpacity(opacity: animation.value, sliver: sliver),
            child: _page(label),
          ),
        ],
      ),
    );

    await tester.pumpWidget(build('orders'));
    await tester.pumpWidget(build('trades'));
    await tester.pump();

    expect(find.byType(SliverFadeTransition), findsNothing);
    expect(find.byType(SliverOpacity), findsOneWidget);
    expect(find.text('trades'), findsOneWidget);
  });

  testWidgets('an empty switcher is still a valid sliver', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomScrollView(
          slivers: <Widget>[
            SliverAnimatedSwitcher(child: SliverToBoxAdapter()),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('reports its knobs to the debug tree', (
    WidgetTester tester,
  ) async {
    const SliverAnimatedSwitcher switcher = SliverAnimatedSwitcher(
      duration: Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      child: SliverToBoxAdapter(),
    );

    expect(switcher.toString(), contains('0:00:00.400000'));
    expect(switcher.toString(), contains('switchInCurve: Cubic'));
  });
}
