import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A [Decoration] for `TabBar.indicator` that draws a short bar of a **fixed
/// width**, centred under the tab, instead of one stretched across it.
///
/// `TabBar` sizes its indicator from `TabBarIndicatorSize`, which offers a
/// choice between the width of the whole tab and the width of its label — both
/// of which move as the labels do. This one is neither: [indicatorWidth] is the
/// width it draws, whatever the tab underneath measures, so a row of tabs with
/// labels of very different lengths still gets underlines of one length.
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
/// The bar is drawn as a rounded rectangle sitting on the bottom edge of the
/// tab, [strokeWidth] tall and exactly [indicatorWidth] wide. [radius] rounds
/// its corners, clamped to half the height — at or above `strokeWidth / 2` the
/// ends are semicircles and rounding further has nothing left to round.
@immutable
class LineTabIndicator extends Decoration {
  /// Creates a fixed-width tab indicator.
  const LineTabIndicator({
    required this.color,
    this.strokeWidth = 3.0,
    this.indicatorWidth = 50.0,
    this.radius = 0.0,
  }) : assert(strokeWidth >= 0, 'strokeWidth must not be negative'),
       assert(indicatorWidth >= 0, 'indicatorWidth must not be negative'),
       assert(radius >= 0, 'radius must not be negative');

  /// The colour the bar is filled with.
  final Color color;

  /// The height of the bar, in logical pixels.
  ///
  /// It grows upwards from the bottom edge of the tab.
  final double strokeWidth;

  /// The width of the bar, in logical pixels.
  ///
  /// Independent of the tab it sits under: a tab narrower than this gets an
  /// indicator that overhangs it on both sides.
  final double indicatorWidth;

  /// The corner radius of the bar, clamped to `strokeWidth / 2`.
  ///
  /// `0` — the default — gives square ends.
  final double radius;

  /// This indicator with the given fields replaced.
  LineTabIndicator copyWith({
    Color? color,
    double? strokeWidth,
    double? indicatorWidth,
    double? radius,
  }) {
    return LineTabIndicator(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      indicatorWidth: indicatorWidth ?? this.indicatorWidth,
      radius: radius ?? this.radius,
    );
  }

  /// Linearly interpolates between two indicators.
  ///
  /// A null argument is treated as an indicator of the same shape faded out,
  /// so a fade in or out is what you get when only one side is given.
  static LineTabIndicator? lerp(
    LineTabIndicator? a,
    LineTabIndicator? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null) return b?.copyWith(color: Color.lerp(null, b.color, t));
    if (b == null) return a.copyWith(color: Color.lerp(a.color, null, t));
    return LineTabIndicator(
      color: Color.lerp(a.color, b.color, t)!,
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t)!,
      indicatorWidth: lerpDouble(a.indicatorWidth, b.indicatorWidth, t)!,
      radius: lerpDouble(a.radius, b.radius, t)!,
    );
  }

  @override
  Decoration? lerpFrom(Decoration? a, double t) {
    if (a is LineTabIndicator?) return LineTabIndicator.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  Decoration? lerpTo(Decoration? b, double t) {
    if (b is LineTabIndicator?) return LineTabIndicator.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _LineTabIndicatorPainter(this);
  }

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) =>
      Path()..addRRect(_rrectFor(rect));

  /// A hit lands only on the bar, not on the whole rect it was laid out in.
  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      _rrectFor(Offset.zero & size).contains(position);

  RRect _rrectFor(Rect rect) {
    final double centerX = rect.left + rect.width / 2;
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - indicatorWidth / 2,
        rect.bottom - strokeWidth,
        indicatorWidth,
        strokeWidth,
      ),
      Radius.circular(radius.clamp(0.0, strokeWidth / 2)),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LineTabIndicator &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.indicatorWidth == indicatorWidth &&
        other.radius == radius;
  }

  @override
  int get hashCode => Object.hash(color, strokeWidth, indicatorWidth, radius);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color))
      ..add(DoubleProperty('strokeWidth', strokeWidth, defaultValue: 3.0))
      ..add(
        DoubleProperty('indicatorWidth', indicatorWidth, defaultValue: 50.0),
      )
      ..add(DoubleProperty('radius', radius, defaultValue: 0.0));
  }
}

class _LineTabIndicatorPainter extends BoxPainter {
  _LineTabIndicatorPainter(this.decoration);

  final LineTabIndicator decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    // `TabBar` always lays the indicator out against a sized tab, but
    // `ImageConfiguration.size` is nullable for decorations painted elsewhere.
    if (size == null) return;

    canvas.drawRRect(
      decoration._rrectFor(offset & size),
      Paint()..color = decoration.color,
    );
  }
}
