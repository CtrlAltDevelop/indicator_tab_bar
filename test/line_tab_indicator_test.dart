import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indicator_tab_bar/indicator_tab_bar.dart';

/// Paints [indicator] into a box of [size] and returns what it drew.
///
/// With no [textDirection] there is no [Directionality] above the box either,
/// which is the case a decoration painted outside a `TabBar` has to survive.
Future<RenderBox> _paint(
  WidgetTester tester,
  LineTabIndicator indicator, {
  Size size = const Size(100, 40),
  TextDirection? textDirection,
}) async {
  Widget box = Center(
    child: SizedBox.fromSize(
      size: size,
      child: DecoratedBox(decoration: indicator),
    ),
  );
  if (textDirection != null) {
    box = Directionality(textDirection: textDirection, child: box);
  }
  await tester.pumpWidget(box);
  return tester.renderObject<RenderBox>(find.byType(DecoratedBox));
}

/// The rounded rect [indicator] paints into a [size] box, and its fill.
({RRect rrect, Paint paint}) _record(
  LineTabIndicator indicator, {
  Size size = const Size(100, 40),
  Offset offset = Offset.zero,
  TextDirection? textDirection,
}) {
  final _RecordingCanvas canvas = _RecordingCanvas();
  indicator.createBoxPainter().paint(
    canvas,
    offset,
    ImageConfiguration(size: size, textDirection: textDirection),
  );
  return (rrect: canvas.rrects.single, paint: canvas.paints.single);
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

  group('inside a TabBar, with geometry', () {
    /// The rect the `TabBar` itself paints for [indicator].
    Future<RRect> drawnFor(
      WidgetTester tester,
      LineTabIndicator indicator, {
      TextDirection textDirection = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: textDirection,
            child: DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  bottom: TabBar(
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: indicator,
                    tabs: const <Widget>[
                      Tab(text: 'Spot'),
                      Tab(text: 'Futures'),
                    ],
                  ),
                ),
                body: const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final _RecordingCanvas canvas = _RecordingCanvas();
      tester
          .renderObject(find.byType(TabBar))
          .paint(TestRecordingPaintingContext(canvas), Offset.zero);
      return canvas.rrects.single;
    }

    const LineTabIndicator base = LineTabIndicator(
      color: Color(0xFFFF0000),
      indicatorWidth: 20,
    );

    testWidgets('a bottom inset lifts the bar off the divider', (
      WidgetTester tester,
    ) async {
      final RRect plain = await drawnFor(tester, base);
      final RRect lifted = await drawnFor(
        tester,
        base.copyWith(insets: const EdgeInsets.only(bottom: 8)),
      );

      expect(lifted.top, plain.top - 8);
      expect(lifted.width, 20);
    });

    testWidgets('a top alignment turns it into an overline', (
      WidgetTester tester,
    ) async {
      final RRect plain = await drawnFor(tester, base);
      final RRect over = await drawnFor(
        tester,
        base.copyWith(alignment: Alignment.topCenter),
      );

      expect(over.top, lessThan(plain.top));
      expect(over.left, plain.left, reason: 'only the vertical edge changed');
    });

    testWidgets('the TabBar hands the indicator its reading direction', (
      WidgetTester tester,
    ) async {
      final LineTabIndicator indicator = base.copyWith(
        alignment: AlignmentDirectional.bottomStart,
      );

      final RRect ltr = await drawnFor(tester, indicator);
      final RRect rtl = await drawnFor(
        tester,
        indicator,
        textDirection: TextDirection.rtl,
      );

      // The first tab is on the left in LTR and on the right in RTL, and the
      // bar is tucked under the start of its label either way.
      expect(rtl.left, greaterThan(ltr.left));
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

    test('an overshooting t never yields a negative size', () {
      const LineTabIndicator thin = LineTabIndicator(
        color: Color(0xFF000000),
        strokeWidth: 1,
        indicatorWidth: 10,
        radius: 1,
      );
      const LineTabIndicator wide = LineTabIndicator(
        color: Color(0xFF000000),
        strokeWidth: 5,
        indicatorWidth: 50,
        radius: 5,
      );
      final LineTabIndicator back = LineTabIndicator.lerp(wide, thin, 1.5)!;
      expect(back.strokeWidth, 0);
      expect(back.indicatorWidth, 0);
      expect(back.radius, 0);
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

  group('alignment', () {
    testWidgets('topCenter draws the bar on the top edge instead', (
      WidgetTester tester,
    ) async {
      final RenderBox box = await _paint(
        tester,
        const LineTabIndicator(
          color: Color(0xFF000000),
          indicatorWidth: 20,
          alignment: Alignment.topCenter,
        ),
      );

      expect(
        box,
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(40, 0, 20, 3),
            Radius.zero,
          ),
        ),
      );
    });

    testWidgets('centre puts it in the middle of the tab', (
      WidgetTester tester,
    ) async {
      final RenderBox box = await _paint(
        tester,
        const LineTabIndicator(
          color: Color(0xFF000000),
          indicatorWidth: 20,
          strokeWidth: 4,
          alignment: Alignment.center,
        ),
      );

      expect(
        box,
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            const Rect.fromLTWH(40, 18, 20, 4),
            Radius.zero,
          ),
        ),
      );
    });

    test('a directional alignment follows the reading direction', () {
      const LineTabIndicator indicator = LineTabIndicator(
        color: Color(0xFF000000),
        indicatorWidth: 20,
        alignment: AlignmentDirectional.bottomStart,
      );

      expect(
        _record(indicator, textDirection: TextDirection.ltr).rrect.left,
        0,
      );
      expect(
        _record(indicator, textDirection: TextDirection.rtl).rrect.left,
        80,
        reason: 'start is the right-hand edge in RTL',
      );
    });

    test('no reading direction at all resolves as LTR', () {
      const LineTabIndicator indicator = LineTabIndicator(
        color: Color(0xFF000000),
        indicatorWidth: 20,
        alignment: AlignmentDirectional.bottomEnd,
      );

      expect(_record(indicator).rrect.left, 80);
      expect(
        indicator.hitTest(const Size(100, 40), const Offset(90, 38)),
        isTrue,
      );
    });

    test('alignment is part of the identity, and lerps', () {
      const LineTabIndicator bottom = LineTabIndicator(
        color: Color(0xFF000000),
      );
      final LineTabIndicator top = bottom.copyWith(
        alignment: Alignment.topCenter,
      );

      expect(top, isNot(bottom));
      expect(top.hashCode, isNot(bottom.hashCode));
      expect(
        LineTabIndicator.lerp(bottom, top, 0.5)!.alignment,
        Alignment.center,
      );
    });
  });

  group('insets', () {
    testWidgets('a bottom inset lifts the bar clear of the edge', (
      WidgetTester tester,
    ) async {
      final RenderBox box = await _paint(
        tester,
        const LineTabIndicator(
          color: Color(0xFF000000),
          indicatorWidth: 20,
          insets: EdgeInsets.only(bottom: 6),
        ),
      );

      expect(
        box,
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            // 3 tall, sitting 6 above the bottom of the 40-tall box.
            const Rect.fromLTWH(40, 31, 20, 3),
            Radius.zero,
          ),
        ),
      );
    });

    test('horizontal insets shift the centre the bar is centred on', () {
      const LineTabIndicator indicator = LineTabIndicator(
        color: Color(0xFF000000),
        indicatorWidth: 20,
        insets: EdgeInsets.only(left: 20),
      );

      // Centred in 20..100 rather than 0..100.
      expect(_record(indicator).rrect.left, 50);
    });

    test('a directional inset follows the reading direction', () {
      const LineTabIndicator indicator = LineTabIndicator(
        color: Color(0xFF000000),
        indicatorWidth: 20,
        insets: EdgeInsetsDirectional.only(start: 20),
      );

      expect(
        _record(indicator, textDirection: TextDirection.ltr).rrect.left,
        50,
      );
      expect(
        _record(indicator, textDirection: TextDirection.rtl).rrect.left,
        30,
      );
    });

    test('insets are part of the identity, and lerp', () {
      const LineTabIndicator base = LineTabIndicator(color: Color(0xFF000000));
      final LineTabIndicator inset = base.copyWith(
        insets: const EdgeInsets.only(bottom: 8),
      );

      expect(inset, isNot(base));
      expect(
        LineTabIndicator.lerp(base, inset, 0.5)!.insets,
        const EdgeInsets.only(bottom: 4),
      );
    });
  });

  group('gradient', () {
    const LinearGradient gradient = LinearGradient(
      colors: <Color>[Color(0xFFFF0000), Color(0xFF0000FF)],
    );

    test('the gradient constructor fills with a shader, not a colour', () {
      const LineTabIndicator indicator = LineTabIndicator.gradient(
        gradient: gradient,
        indicatorWidth: 20,
      );

      expect(indicator.color.a, 0, reason: 'nothing flat to fade through');

      final ({RRect rrect, Paint paint}) drawn = _record(indicator);
      expect(drawn.paint.shader, isNotNull);
      expect(drawn.rrect.width, 20);
    });

    test('a gradient given alongside a colour paints over it', () {
      const LineTabIndicator indicator = LineTabIndicator(
        color: Color(0xFF00FF00),
        gradient: gradient,
      );

      expect(_record(indicator).paint.shader, isNotNull);
    });

    test(
      'the shader is rebuilt as the bar moves, and reused while it sits',
      () {
        final BoxPainter painter = const LineTabIndicator.gradient(
          gradient: gradient,
          indicatorWidth: 20,
        ).createBoxPainter();
        final _RecordingCanvas canvas = _RecordingCanvas();

        void paintAt(double dx) => painter.paint(
          canvas,
          Offset(dx, 0),
          const ImageConfiguration(size: Size(100, 40)),
        );

        paintAt(0);
        paintAt(0);
        paintAt(200);

        expect(canvas.paints, hasLength(3));
        expect(
          canvas.paints[1].shader,
          same(canvas.paints[0].shader),
          reason: 'the bar did not move, so the shader is still good',
        );
        expect(canvas.paints[2].shader, isNot(same(canvas.paints[0].shader)));
      },
    );

    test('gradient is part of the identity, and lerps', () {
      const LineTabIndicator flat = LineTabIndicator(color: Color(0xFF000000));
      const LineTabIndicator shaded = LineTabIndicator.gradient(
        gradient: gradient,
      );

      expect(shaded, isNot(flat));
      expect(shaded, equals(shaded.copyWith()));
      expect(shaded.hashCode, shaded.copyWith().hashCode);

      final LineTabIndicator half = LineTabIndicator.lerp(flat, shaded, 0.5)!;
      expect(half.gradient, isNotNull);
      expect(half.gradient, Gradient.lerp(null, gradient, 0.5));
    });

    test('a null side of lerp fades the gradient out, keeping the shape', () {
      const LineTabIndicator shaded = LineTabIndicator.gradient(
        gradient: gradient,
        indicatorWidth: 20,
      );

      final LineTabIndicator gone = LineTabIndicator.lerp(shaded, null, 1)!;
      expect(
        (gone.gradient! as LinearGradient).colors.every((Color c) => c.a == 0),
        isTrue,
      );
      expect(gone.indicatorWidth, 20, reason: 'it faded, it did not shrink');
    });

    test('toString names the new fields when they are set', () {
      const LineTabIndicator indicator = LineTabIndicator(
        color: Color(0xFF000000),
        gradient: gradient,
        alignment: Alignment.topCenter,
        insets: EdgeInsets.only(bottom: 6),
      );

      expect(indicator.toString(), contains('gradient: LinearGradient'));
      expect(indicator.toString(), contains('alignment: Alignment.topCenter'));
      expect(
        indicator.toString(),
        contains('insets: EdgeInsets(0.0, 0.0, 0.0, 6.0)'),
      );
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

/// A canvas that keeps the rounded rects painted through it, and their fills.
class _RecordingCanvas extends TestRecordingCanvas {
  final List<RRect> rrects = <RRect>[];
  final List<Paint> paints = <Paint>[];

  @override
  void drawRRect(RRect rrect, Paint paint) {
    rrects.add(rrect);
    paints.add(paint);
    super.drawRRect(rrect, paint);
  }
}
