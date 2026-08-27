import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A [Decoration] for `TabBar.indicator` that draws a short bar of a **fixed
/// width**, by default centred under the tab, instead of one stretched across
/// it.
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
/// The bar is a rounded rectangle [strokeWidth] tall and exactly
/// [indicatorWidth] wide, placed inside the tab by [alignment] — bottom centre
/// unless told otherwise — within the rect [insets] leaves. [radius] rounds its
/// corners, clamped to half the height: at or above `strokeWidth / 2` the ends
/// are semicircles and rounding further has nothing left to round.
///
/// [LineTabIndicator.gradient] fills the bar with a [Gradient] instead of a
/// flat colour, for an underline that shades along its length.
@immutable
class LineTabIndicator extends Decoration {
  /// Creates a fixed-width tab indicator filled with [color].
  ///
  /// A [gradient] given as well paints over the colour; [LineTabIndicator.gradient]
  /// is the shorter way to ask for that.
  const LineTabIndicator({
    required this.color,
    this.gradient,
    this.strokeWidth = 3.0,
    this.indicatorWidth = 50.0,
    this.radius = 0.0,
    this.alignment = Alignment.bottomCenter,
    this.insets = EdgeInsets.zero,
  }) : assert(strokeWidth >= 0, 'strokeWidth must not be negative'),
       assert(indicatorWidth >= 0, 'indicatorWidth must not be negative'),
       assert(radius >= 0, 'radius must not be negative');

  /// Creates a fixed-width tab indicator filled with [gradient].
  ///
  /// [color] is transparent, so a bar that lerps to or from this one fades the
  /// gradient in or out rather than crossing through a flat colour.
  const LineTabIndicator.gradient({
    required Gradient this.gradient,
    this.strokeWidth = 3.0,
    this.indicatorWidth = 50.0,
    this.radius = 0.0,
    this.alignment = Alignment.bottomCenter,
    this.insets = EdgeInsets.zero,
  }) : color = const Color(0x00000000),
       assert(strokeWidth >= 0, 'strokeWidth must not be negative'),
       assert(indicatorWidth >= 0, 'indicatorWidth must not be negative'),
       assert(radius >= 0, 'radius must not be negative');

  /// The colour the bar is filled with.
  ///
  /// Ignored while [gradient] is non-null, which paints over it — but still
  /// what a lerp between a gradient bar and a flat one fades through.
  final Color color;

  /// A gradient to fill the bar with, in place of [color].
  ///
  /// Laid out across the bar itself, not across the tab, so a
  /// [LinearGradient] runs over exactly [indicatorWidth] logical pixels.
  final Gradient? gradient;

  /// The height of the bar, in logical pixels.
  final double strokeWidth;

  /// The width of the bar, in logical pixels.
  ///
  /// Independent of the tab it sits under: a tab narrower than this gets an
  /// indicator that overhangs it evenly on both sides.
  final double indicatorWidth;

  /// The corner radius of the bar, clamped to `strokeWidth / 2`.
  ///
  /// `0` — the default — gives square ends.
  final double radius;

  /// Where the bar sits within the tab, after [insets] are taken off.
  ///
  /// Defaults to [Alignment.bottomCenter], an underline on the bottom edge.
  /// [Alignment.topCenter] makes it an overline instead, for a `TabBar` that
  /// sits below what it selects; [AlignmentDirectional.bottomStart] tucks it
  /// under the leading edge of the label and flips with the reading direction.
  final AlignmentGeometry alignment;

  /// Deflates the rect the bar is aligned within.
  ///
  /// `EdgeInsets.only(bottom: 6)` lifts an underline 6 logical pixels clear of
  /// the bottom edge — room for the `TabBar` divider to show through beneath
  /// it.
  final EdgeInsetsGeometry insets;

  /// This indicator with the given fields replaced.
  ///
  /// Passing null keeps the current value, so this cannot clear [color] or
  /// [gradient]; build a new indicator for that.
  LineTabIndicator copyWith({
    Color? color,
    Gradient? gradient,
    double? strokeWidth,
    double? indicatorWidth,
    double? radius,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? insets,
  }) {
    return LineTabIndicator(
      color: color ?? this.color,
      gradient: gradient ?? this.gradient,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      indicatorWidth: indicatorWidth ?? this.indicatorWidth,
      radius: radius ?? this.radius,
      alignment: alignment ?? this.alignment,
      insets: insets ?? this.insets,
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
    if (a == null) return b?._scaled(t);
    if (b == null) return a._scaled(1.0 - t);
    return LineTabIndicator(
      color: Color.lerp(a.color, b.color, t)!,
      gradient: Gradient.lerp(a.gradient, b.gradient, t),
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t)!,
      indicatorWidth: lerpDouble(a.indicatorWidth, b.indicatorWidth, t)!,
      radius: lerpDouble(a.radius, b.radius, t)!,
      alignment: AlignmentGeometry.lerp(a.alignment, b.alignment, t)!,
      insets: EdgeInsetsGeometry.lerp(a.insets, b.insets, t)!,
    );
  }

  /// This indicator with its fill scaled towards transparent.
  ///
  /// `1.0` leaves it as it is, `0.0` makes it invisible; the shape does not
  /// move, which is what makes a null side of [lerp] a plain fade.
  LineTabIndicator _scaled(double factor) {
    return copyWith(
      color: Color.lerp(null, color, factor),
      gradient: gradient?.scale(factor),
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
      Path()..addRRect(_rrectFor(rect, textDirection));

  /// A hit lands only on the bar, not on the whole rect it was laid out in.
  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      _rrectFor(Offset.zero & size, textDirection).contains(position);

  /// The bar [alignment] and [insets] put inside [rect].
  ///
  /// [textDirection] resolves both; it only matters for the directional forms
  /// of either, and falls back to [TextDirection.ltr] when a caller has none
  /// to give.
  RRect _rrectFor(Rect rect, TextDirection? textDirection) {
    final TextDirection direction = textDirection ?? TextDirection.ltr;
    final Rect bar = alignment
        .resolve(direction)
        .inscribe(
          Size(indicatorWidth, strokeWidth),
          insets.resolve(direction).deflateRect(rect),
        );
    return RRect.fromRectAndRadius(
      bar,
      Radius.circular(radius.clamp(0.0, strokeWidth / 2)),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LineTabIndicator &&
        other.color == color &&
        other.gradient == gradient &&
        other.strokeWidth == strokeWidth &&
        other.indicatorWidth == indicatorWidth &&
        other.radius == radius &&
        other.alignment == alignment &&
        other.insets == insets;
  }

  @override
  int get hashCode => Object.hash(
    color,
    gradient,
    strokeWidth,
    indicatorWidth,
    radius,
    alignment,
    insets,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('color', color))
      ..add(
        DiagnosticsProperty<Gradient>('gradient', gradient, defaultValue: null),
      )
      ..add(DoubleProperty('strokeWidth', strokeWidth, defaultValue: 3.0))
      ..add(
        DoubleProperty('indicatorWidth', indicatorWidth, defaultValue: 50.0),
      )
      ..add(DoubleProperty('radius', radius, defaultValue: 0.0))
      ..add(
        DiagnosticsProperty<AlignmentGeometry>(
          'alignment',
          alignment,
          defaultValue: Alignment.bottomCenter,
        ),
      )
      ..add(
        DiagnosticsProperty<EdgeInsetsGeometry>(
          'insets',
          insets,
          defaultValue: EdgeInsets.zero,
        ),
      );
  }
}

class _LineTabIndicatorPainter extends BoxPainter {
  _LineTabIndicatorPainter(this.decoration);

  final LineTabIndicator decoration;

  /// The bar the cached [_paint]'s shader was built for.
  Rect? _shadedRect;
  Paint? _paint;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    // `TabBar` always lays the indicator out against a sized tab, but
    // `ImageConfiguration.size` is nullable for decorations painted elsewhere.
    if (size == null) return;

    final RRect rrect = decoration._rrectFor(
      offset & size,
      configuration.textDirection,
    );
    canvas.drawRRect(
      rrect,
      _paintFor(rrect.outerRect, configuration.textDirection),
    );
  }

  /// The fill for a bar occupying [rect].
  ///
  /// A gradient shader is tied to the rect it was made for, so it is rebuilt
  /// as the bar moves between tabs and reused while it sits still.
  Paint _paintFor(Rect rect, TextDirection? textDirection) {
    final Gradient? gradient = decoration.gradient;
    if (gradient == null) {
      return _paint ??= (Paint()..color = decoration.color);
    }
    if (_paint == null || _shadedRect != rect) {
      _shadedRect = rect;
      _paint = Paint()
        ..shader = gradient.createShader(rect, textDirection: textDirection);
    }
    return _paint!;
  }
}
