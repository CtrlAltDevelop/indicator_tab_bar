import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indicator_tab_bar/indicator_tab_bar.dart';

/// Paints [indicator] into a box of [size] and returns what it drew.
Future<RenderBox> _paint(
  WidgetTester tester,
  LineTabIndicator indicator, {
  Size size = const Size(100, 40),
}) async {
  await tester.pumpWidget(
    Center(
      child: SizedBox.fromSize(
        size: size,
        child: DecoratedBox(decoration: indicator),
      ),
    ),
  );
  return tester.renderObject<RenderBox>(find.byType(DecoratedBox));
}

void main() {
  group('painting', () {
    testWidgets('draws a bar of exactly indicatorWidth, centred, on the '
        'bottom edge', (WidgetTester tester) async {
      final RenderBox box = await _paint(
        tester,
        const LineTabIndicator(color: Color(0xFF00FF00), indicatorWidth: 20),
      );

      // 100 wide, so a 20-wide bar centres on 40..60; 3 tall by default,
      // sitting on the bottom edge of the 40-tall box.
      expect(
        box,
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(40, 37, 20, 3),
            Radius.zero,
          ),
          color: const Color(0xFF00FF00),
        ),
      );
    });

    testWidgets('width does not follow the tab width', (
      WidgetTester tester,
    ) async {
      const LineTabIndicator indicator = LineTabIndicator(
        color: Color(0xFF000000),
        indicatorWidth: 20,
      );

      for (final double tabWidth in <double>[40, 300]) {
        final RenderBox box = await _paint(
          tester,
          indicator,
          size: Size(tabWidth, 40),
        );
        expect(
          box,
          paints..rrect(
            rrect: RRect.fromRectAndRadius(
              Rect.fromLTWH(tabWidth / 2 - 10, 37, 20, 3),
              Radius.zero,
            ),
          ),
          reason: 'the bar stays 20 wide under a $tabWidth-wide tab',
        );
      }
    });

    testWidgets('a bar wider than its tab overhangs it evenly', (
      WidgetTester tester,
    ) async {
      final RenderBox box = await _paint(
        tester,
        const LineTabIndicator(color: Color(0xFF000000), indicatorWidth: 60),
        size: const Size(40, 40),
      );

      expect(
        box,
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(-10, 37, 60, 3),
            Radius.zero,
          ),
        ),
      );
    });

    testWidgets('radius is clamped to half the height', (
      WidgetTester tester,
    ) async {
      final RenderBox box = await _paint(
        tester,
        const LineTabIndicator(
          color: Color(0xFF000000),
          strokeWidth: 4,
          indicatorWidth: 20,
          radius: 99,
        ),
      );

      expect(
        box,
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(40, 36, 20, 4),
            const Radius.circular(2),
          ),
        ),
      );
    });

    testWidgets('a zero-size indicator still paints nothing invalid', (
      WidgetTester tester,
    ) async {
      final RenderBox box = await _paint(
        tester,
        const LineTabIndicator(
          color: Color(0xFF000000),
          strokeWidth: 0,
          indicatorWidth: 0,
        ),
      );

      expect(
        box,
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(50, 40, 0, 0),
            Radius.zero,
          ),
        ),
      );
    });

    test('a painter given no size paints nothing', () {
      final BoxPainter painter = const LineTabIndicator(
        color: Color(0xFF000000),
      ).createBoxPainter();
      final TestRecordingCanvas canvas = TestRecordingCanvas();

      painter.paint(canvas, Offset.zero, const ImageConfiguration());

      expect(canvas.invocations, isEmpty);
    });

    test('negative metrics are rejected', () {
      expect(
        () => LineTabIndicator(color: const Color(0xFF000000), radius: -1),
        throwsAssertionError,
      );
      expect(
        () => LineTabIndicator(color: const Color(0xFF000000), strokeWidth: -1),
        throwsAssertionError,
      );
      expect(
        () => LineTabIndicator(
          color: const Color(0xFF000000),
          indicatorWidth: -1,
        ),
        throwsAssertionError,
      );
    });
  });

  group('inside a TabBar', () {
    testWidgets('follows the selected tab', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: LineTabIndicator(
                    color: Color(0xFFFF0000),
                    indicatorWidth: 20,
                    radius: 4,
                  ),
                  tabs: <Widget>[
                    Tab(text: 'Spot'),
                    Tab(text: 'Futures'),
                  ],
                ),
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );

      RRect drawn() {
        // The indicator is painted by the `TabBar`'s own render object.
        final _RecordingCanvas canvas = _RecordingCanvas();
        tester
            .renderObject(find.byType(TabBar))
            .paint(TestRecordingPaintingContext(canvas), Offset.zero);
        return canvas.rrects.single;
      }

      final RRect first = drawn();
      expect(first.width, 20);
      expect(first.blRadiusY, 1.5, reason: 'radius 4 clamps to strokeWidth/2');

      await tester.tap(find.text('Futures'));
      await tester.pumpAndSettle();

      final RRect second = drawn();
      expect(second.width, 20);
      expect(
        second.left,
        greaterThan(first.left),
        reason: 'the bar moved to the second tab',
      );
    });
  });

  group('value semantics', () {
    const LineTabIndicator base = LineTabIndicator(
      color: Color(0xFF112233),
      strokeWidth: 3,
      indicatorWidth: 20,
      radius: 4,
    );

    test('equal indicators compare and hash equal', () {
      expect(base, equals(base.copyWith()));
      expect(base.hashCode, base.copyWith().hashCode);
    });

    test('each field is part of the identity', () {
      expect(base, isNot(base.copyWith(color: const Color(0xFF000000))));
      expect(base, isNot(base.copyWith(strokeWidth: 4)));
      expect(base, isNot(base.copyWith(indicatorWidth: 21)));
      expect(base, isNot(base.copyWith(radius: 5)));
    });

    test('toString names the fields', () {
      expect(base.toString(), contains('indicatorWidth: 20.0'));
    });
  });

  group('lerp', () {
    const LineTabIndicator a = LineTabIndicator(
      color: Color(0xFF000000),
      strokeWidth: 2,
      indicatorWidth: 10,
      radius: 0,
    );
    const LineTabIndicator b = LineTabIndicator(
      color: Color(0xFFFFFFFF),
      strokeWidth: 4,
      indicatorWidth: 30,
      radius: 8,
    );

    test('interpolates every field', () {
      final LineTabIndicator half = LineTabIndicator.lerp(a, b, 0.5)!;
      expect(half.strokeWidth, 3);
      expect(half.indicatorWidth, 20);
      expect(half.radius, 4);
      expect(half.color, Color.lerp(a.color, b.color, 0.5));
    });

    test('the endpoints are the endpoints', () {
      expect(LineTabIndicator.lerp(a, b, 0), a);
      expect(LineTabIndicator.lerp(a, b, 1), b);
    });

    test('a null side fades the other one', () {
      expect(LineTabIndicator.lerp(null, b, 0)!.color.a, 0);
      expect(LineTabIndicator.lerp(a, null, 1)!.color.a, 0);
      expect(LineTabIndicator.lerp(null, null, 0.5), isNull);
    });

    test('Decoration.lerp routes through it in both directions', () {
      expect(Decoration.lerp(a, b, 0.5), LineTabIndicator.lerp(a, b, 0.5));
      expect(Decoration.lerp(a, null, 0.5), a.lerpTo(null, 0.5));
      expect(Decoration.lerp(null, b, 0.5), b.lerpFrom(null, 0.5));
    });

    test('an unrelated decoration is left to the base implementation', () {
      const BoxDecoration other = BoxDecoration(color: Color(0xFF00FF00));
      expect(a.lerpFrom(other, 0.5), isNull);
      expect(a.lerpTo(other, 0.5), isNull);
    });
  });

  group('geometry', () {
    const LineTabIndicator indicator = LineTabIndicator(
      color: Color(0xFF000000),
      strokeWidth: 4,
      indicatorWidth: 20,
    );

    test('hitTest covers the bar and nothing above it', () {
      const Size size = Size(100, 40);
      expect(indicator.hitTest(size, const Offset(50, 38)), isTrue);
      expect(indicator.hitTest(size, const Offset(50, 20)), isFalse);
      expect(indicator.hitTest(size, const Offset(5, 38)), isFalse);
    });

    test('getClipPath clips to the bar', () {
      final Path path = indicator.getClipPath(
        const Rect.fromLTWH(0, 0, 100, 40),
        TextDirection.ltr,
      );
      expect(path.getBounds(), const Rect.fromLTWH(40, 36, 20, 4));
    });
  });
}

/// A canvas that keeps the rounded rects painted through it.
class _RecordingCanvas extends TestRecordingCanvas {
  final List<RRect> rrects = <RRect>[];

  @override
  void drawRRect(RRect rrect, Paint paint) {
    rrects.add(rrect);
    super.drawRRect(rrect, paint);
  }
}
