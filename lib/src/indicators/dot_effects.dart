import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'indicator_effect.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// How [WormIndicatorEffect] draws its worm.
enum WormStyle {
  /// A full-height worm drawn over the dots.
  normal,

  /// A worm that gets thinner while it stretches.
  thin,

  /// A full-height worm that crawls under the dots.
  underground,

  /// A thin worm that crawls under the dots.
  thinUnderground,
}

/// How [SwapIndicatorEffect] swaps two dots.
enum SwapStyle {
  /// The dots slide past each other in a straight line.
  normal,

  /// The dots circle each other as if seen from above: the current dot passes
  /// in front, bigger, while the other passes behind.
  yRotation,

  /// The dots circle each other in the plane: one over the top, one under
  /// the bottom.
  zRotation,
}

/// The shared settings of indicators made of dots.
abstract class DotIndicatorEffect extends IndicatorEffect {
  /// Creates dot settings. The defaults suit most designs.
  const DotIndicatorEffect({
    this.dotWidth = 10,
    this.dotHeight = 10,
    this.spacing = 8,
    this.radius = 5,
    this.dotColor = const Color(0x66808080),
    this.activeDotColor = const Color(0xFF3F51B5),
    this.strokeWidth = 1,
    this.paintStyle = PaintingStyle.fill,
  });

  /// The width of one dot.
  final double dotWidth;

  /// The height of one dot.
  final double dotHeight;

  /// The gap between dots.
  final double spacing;

  /// The corner radius of the dots. Half the dot size makes round dots.
  final double radius;

  /// The color of the other dots.
  final Color dotColor;

  /// The color of the current dot.
  final Color activeDotColor;

  /// The outline width when [paintStyle] is [PaintingStyle.stroke].
  final double strokeWidth;

  /// Whether the other dots are filled or outlined. The current dot is
  /// always filled.
  final PaintingStyle paintStyle;

  /// The distance between the left edges of neighbouring dots.
  double get step => dotWidth + spacing;

  /// Extra room on each side, for effects that grow the dots.
  double get horizontalPadding => 0;

  /// Extra room above and below, for effects that move or grow the dots.
  double get verticalPadding => 0;

  @override
  Size calculateSize(int count) {
    return Size(
      count * dotWidth +
          math.max(0, count - 1) * spacing +
          2 * horizontalPadding,
      dotHeight + 2 * verticalPadding,
    );
  }

  /// The left edge of dot [index].
  double dotLeft(int index) => horizontalPadding + index * step;

  /// The top edge of a dot in a canvas of [size].
  double dotTop(Size size) => (size.height - dotHeight) / 2;

  /// The paint for the other dots.
  Paint get dotPaint => Paint()
    ..color = dotColor
    ..style = paintStyle
    ..strokeWidth = strokeWidth
    ..isAntiAlias = true;

  /// The paint for the current dot.
  Paint get activePaint => Paint()
    ..color = activeDotColor
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  /// A dot-shaped rounded rectangle with its center at [center].
  RRect dotAt(Offset center,
      {double scale = 1, double? width, double? height}) {
    final double w = (width ?? dotWidth) * scale;
    final double h = (height ?? dotHeight) * scale;
    return RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      Radius.circular(radius * scale),
    );
  }

  /// The center of dot [index] in a canvas of [size].
  Offset dotCenter(int index, Size size) =>
      Offset(dotLeft(index) + dotWidth / 2, size.height / 2);

  /// Paints all dots in their resting state.
  void paintDots(Canvas canvas, Size size, int count) {
    final Paint paint = dotPaint;
    for (int i = 0; i < count; i++) {
      canvas.drawRRect(dotAt(dotCenter(i, size)), paint);
    }
  }

  @override
  int? hitTest(Offset position, Size size, double page, int count) {
    final int index =
        ((position.dx - horizontalPadding + spacing / 2) / step).floor();
    return index >= 0 && index < count ? index : null;
  }
}

/// A pill that stretches from one dot to the next like a worm.
class WormIndicatorEffect extends DotIndicatorEffect {
  /// Creates a worm.
  const WormIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
    this.style = WormStyle.normal,
  });

  /// How the worm is drawn.
  final WormStyle style;

  bool get _under =>
      style == WormStyle.underground || style == WormStyle.thinUnderground;

  bool get _thin =>
      style == WormStyle.thin || style == WormStyle.thinUnderground;

  void _paintWorm(Canvas canvas, Size size, int from, double t) {
    final double head = math.min(t, 0.5) * 2;
    final double tail = math.max(t - 0.5, 0) * 2;
    final double left = dotLeft(from) + tail * step;
    final double right = dotLeft(from) + dotWidth + head * step;
    final double stretch = math.sin(t * math.pi);
    final double height = _thin ? dotHeight * (1 - 0.5 * stretch) : dotHeight;
    final double top = (size.height - height) / 2;
    canvas.drawRRect(
      RRect.fromLTRBR(left, top, right, top + height, Radius.circular(radius)),
      activePaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    if (!_under) {
      paintDots(canvas, size, count);
    }
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    if (segment.wraps) {
      paintWithOpacity(canvas, size, 1 - segment.t,
          () => _paintWorm(canvas, size, segment.from, 0));
      paintWithOpacity(canvas, size, segment.t,
          () => _paintWorm(canvas, size, segment.to, 0));
    } else {
      _paintWorm(canvas, size, segment.from, segment.t);
    }
    if (_under) {
      paintDots(canvas, size, count);
    }
  }
}

/// The current dot stretches into a wide pill and the others make room.
class ExpandingDotsIndicatorEffect extends DotIndicatorEffect {
  /// Creates expanding dots.
  const ExpandingDotsIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
    this.expansionFactor = 3,
  });

  /// How many times wider the current dot is.
  final double expansionFactor;

  double get _extra => dotWidth * (math.max(1.0, expansionFactor) - 1);

  @override
  Size calculateSize(int count) {
    final Size base = super.calculateSize(count);
    return Size(base.width + _extra, base.height);
  }

  /// The left edges and widths of all dots for [page].
  List<Rect> _layout(Size size, double page, int count) {
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    final double top = dotTop(size);
    final List<Rect> rects = <Rect>[];
    double x = 0;
    for (int i = 0; i < count; i++) {
      final double width = dotWidth + _extra * segment.activeness(i);
      rects.add(Rect.fromLTWH(x, top, width, dotHeight));
      x += width + spacing;
    }
    return rects;
  }

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    final List<Rect> rects = _layout(size, page, count);
    for (int i = 0; i < count; i++) {
      final double active = segment.activeness(i);
      final Paint paint = active > 0
          ? (Paint()
            ..color = Color.lerp(dotColor, activeDotColor, active)!
            ..isAntiAlias = true)
          : dotPaint;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rects[i], Radius.circular(radius)),
        paint,
      );
    }
  }

  @override
  int? hitTest(Offset position, Size size, double page, int count) {
    final List<Rect> rects = _layout(size, page, count);
    for (int i = 0; i < count; i++) {
      final Rect rect = rects[i];
      if (position.dx >= rect.left - spacing / 2 &&
          position.dx < rect.right + spacing / 2) {
        return i;
      }
    }
    return null;
  }
}

/// The current dot jumps from one place to the next, growing mid-air.
class JumpingDotIndicatorEffect extends DotIndicatorEffect {
  /// Creates a jumping dot.
  const JumpingDotIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
    this.jumpScale = 1.4,
    this.verticalOffset = 0,
  });

  /// How big the dot gets at the top of its jump.
  final double jumpScale;

  /// How high the dot jumps, in logical pixels.
  final double verticalOffset;

  double get _scale => math.max(1.0, jumpScale);

  @override
  double get horizontalPadding => dotWidth * (_scale - 1) / 2;

  @override
  double get verticalPadding =>
      dotHeight * (_scale - 1) / 2 + verticalOffset.abs();

  void _paintDot(Canvas canvas, Size size, int from, int to, double t) {
    final double lift = math.sin(t * math.pi);
    final Offset start = dotCenter(from, size);
    final Offset end = dotCenter(to, size);
    final Offset center = Offset(
      _lerp(start.dx, end.dx, t),
      start.dy - verticalOffset * lift,
    );
    canvas.drawRRect(
      dotAt(center, scale: 1 + (_scale - 1) * lift),
      activePaint,
    );
  }

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    paintDots(canvas, size, count);
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    if (segment.wraps) {
      paintWithOpacity(canvas, size, 1 - segment.t,
          () => _paintDot(canvas, size, segment.from, segment.from, 0));
      paintWithOpacity(canvas, size, segment.t,
          () => _paintDot(canvas, size, segment.to, segment.to, 0));
    } else {
      _paintDot(canvas, size, segment.from, segment.to, segment.t);
    }
  }
}

/// Only a few dots show at a time and they scroll along, for long lists.
class ScrollingDotsIndicatorEffect extends DotIndicatorEffect {
  /// Creates scrolling dots.
  const ScrollingDotsIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
    this.maxVisibleDots = 5,
    this.activeDotScale = 1.3,
    this.smallDotScale = 0.6,
    this.fixedCenter = false,
  });

  /// The most dots shown at once.
  final int maxVisibleDots;

  /// The size of the current dot compared with the others.
  final double activeDotScale;

  /// The size of the dots at the edges that hint at more dots beyond.
  final double smallDotScale;

  /// Whether the current dot stays in the middle while the dots scroll
  /// under it.
  final bool fixedCenter;

  int _visible(int count) => math.max(1, math.min(count, maxVisibleDots));

  @override
  double get horizontalPadding =>
      dotWidth * (math.max(1.0, activeDotScale) - 1) / 2;

  @override
  double get verticalPadding =>
      dotHeight * (math.max(1.0, activeDotScale) - 1) / 2;

  @override
  Size calculateSize(int count) => super.calculateSize(_visible(count));

  double _windowStart(double page, int count) {
    final int visible = _visible(count);
    final double start = page - (visible - 1) / 2;
    if (fixedCenter) {
      return start;
    }
    return clampDouble(start, 0, (count - visible).toDouble());
  }

  void _paintAt(Canvas canvas, Size size, double page, int count) {
    final int visible = _visible(count);
    final double start = _windowStart(page, count);
    final Paint paint = dotPaint;
    final double centerY = size.height / 2;
    for (int i = 0; i < count; i++) {
      final double place = i - start;
      if (place < -1 || place > visible) {
        continue;
      }
      final double edge = math.min(place, visible - 1 - place);
      final bool moreBeyond = fixedCenter ||
          (place < (visible - 1) / 2
              ? start > 0.001
              : start < count - visible - 0.001);
      double scale = 1;
      if (edge < 1 && moreBeyond && visible > 2) {
        scale = _lerp(smallDotScale, 1, clampDouble(edge, 0, 1));
      }
      if (edge < 0) {
        scale *= clampDouble(1 + edge, 0, 1);
      }
      if (scale <= 0.01) {
        continue;
      }
      final Offset center = Offset(
        horizontalPadding + place * step + dotWidth / 2,
        centerY,
      );
      canvas.drawRRect(dotAt(center, scale: scale), paint);
    }
    final Offset active = Offset(
      horizontalPadding + (page - start) * step + dotWidth / 2,
      centerY,
    );
    canvas.drawRRect(dotAt(active, scale: activeDotScale), activePaint);
  }

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (segment.wraps) {
      paintWithOpacity(canvas, size, 1 - segment.t,
          () => _paintAt(canvas, size, (count - 1).toDouble(), count));
      paintWithOpacity(
          canvas, size, segment.t, () => _paintAt(canvas, size, 0, count));
    } else {
      _paintAt(canvas, size, page, count);
    }
    canvas.restore();
  }

  @override
  int? hitTest(Offset position, Size size, double page, int count) {
    final double start = _windowStart(page.roundToDouble(), count);
    final int index =
        (start + (position.dx - horizontalPadding + spacing / 2) / step)
            .floor();
    return index >= 0 && index < count ? index : null;
  }
}

/// The current dot slides over (or under) the others.
class SlideIndicatorEffect extends DotIndicatorEffect {
  /// Creates a sliding dot.
  const SlideIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
    this.underneath = false,
  });

  /// Whether the dot slides under the others instead of over them.
  final bool underneath;

  void _paintDot(Canvas canvas, Size size, double position) {
    final Offset center = Offset(
      horizontalPadding + position * step + dotWidth / 2,
      size.height / 2,
    );
    canvas.drawRRect(dotAt(center), activePaint);
  }

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    if (!underneath) {
      paintDots(canvas, size, count);
    }
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    if (segment.wraps) {
      paintWithOpacity(canvas, size, 1 - segment.t,
          () => _paintDot(canvas, size, segment.from.toDouble()));
      paintWithOpacity(canvas, size, segment.t,
          () => _paintDot(canvas, size, segment.to.toDouble()));
    } else {
      _paintDot(canvas, size, segment.from + segment.t);
    }
    if (underneath) {
      paintDots(canvas, size, count);
    }
  }
}

/// The current dot grows and changes color.
class ScaleIndicatorEffect extends DotIndicatorEffect {
  /// Creates a scaling dot.
  const ScaleIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
    this.activeDotScale = 1.4,
  });

  /// The size of the current dot compared with the others.
  final double activeDotScale;

  double get _scale => math.max(1.0, activeDotScale);

  @override
  double get horizontalPadding => dotWidth * (_scale - 1) / 2;

  @override
  double get verticalPadding => dotHeight * (_scale - 1) / 2;

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    for (int i = 0; i < count; i++) {
      final double active = segment.activeness(i);
      final Paint paint = active > 0
          ? (Paint()
            ..color = Color.lerp(dotColor, activeDotColor, active)!
            ..isAntiAlias = true)
          : dotPaint;
      canvas.drawRRect(
        dotAt(dotCenter(i, size), scale: 1 + (_scale - 1) * active),
        paint,
      );
    }
  }
}

/// The current dot swaps places with the next one.
class SwapIndicatorEffect extends DotIndicatorEffect {
  /// Creates swapping dots.
  const SwapIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
    this.style = SwapStyle.normal,
  });

  /// How the two dots get past each other.
  final SwapStyle style;

  @override
  double get horizontalPadding =>
      style == SwapStyle.yRotation ? dotWidth * 0.15 : 0;

  @override
  double get verticalPadding => switch (style) {
        SwapStyle.normal => 0,
        SwapStyle.yRotation => dotHeight * 0.15,
        SwapStyle.zRotation => step / 2,
      };

  void _paintSwap(
      Canvas canvas, Size size, int count, int from, int to, double t) {
    final Paint paint = dotPaint;
    for (int i = 0; i < count; i++) {
      if (i != from && i != to) {
        canvas.drawRRect(dotAt(dotCenter(i, size)), paint);
      }
    }
    final Offset start = dotCenter(from, size);
    final Offset end = dotCenter(to, size);
    final double x = _lerp(start.dx, end.dx, t);
    final double otherX = _lerp(end.dx, start.dx, t);
    final double arc = math.sin(t * math.pi);
    switch (style) {
      case SwapStyle.normal:
        if (from != to) {
          canvas.drawRRect(dotAt(Offset(otherX, end.dy)), paint);
        }
        canvas.drawRRect(dotAt(Offset(x, start.dy)), activePaint);
      case SwapStyle.yRotation:
        if (from != to) {
          canvas.drawRRect(
            dotAt(Offset(otherX, end.dy), scale: 1 - 0.3 * arc),
            paint,
          );
        }
        canvas.drawRRect(
          dotAt(Offset(x, start.dy), scale: 1 + 0.3 * arc),
          activePaint,
        );
      case SwapStyle.zRotation:
        final double lift = (end.dx - start.dx).abs() / 2 * arc;
        if (from != to) {
          canvas.drawRRect(dotAt(Offset(otherX, end.dy + lift)), paint);
        }
        canvas.drawRRect(dotAt(Offset(x, start.dy - lift)), activePaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    if (segment.wraps) {
      paintDots(canvas, size, count);
      paintWithOpacity(canvas, size, 1 - segment.t, () {
        canvas.drawRRect(dotAt(dotCenter(segment.from, size)), activePaint);
      });
      paintWithOpacity(canvas, size, segment.t, () {
        canvas.drawRRect(dotAt(dotCenter(segment.to, size)), activePaint);
      });
      return;
    }
    _paintSwap(canvas, size, count, segment.from, segment.to, segment.t);
  }
}

/// The dots stay still and only change color.
class ColorTransitionIndicatorEffect extends DotIndicatorEffect {
  /// Creates a color transition.
  const ColorTransitionIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
  });

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    for (int i = 0; i < count; i++) {
      final double active = segment.activeness(i);
      final Paint paint = active > 0
          ? (Paint()
            ..color = Color.lerp(dotColor, activeDotColor, active)!
            ..style = active >= 0.5 ? PaintingStyle.fill : paintStyle
            ..strokeWidth = strokeWidth
            ..isAntiAlias = true)
          : dotPaint;
      canvas.drawRRect(dotAt(dotCenter(i, size)), paint);
    }
  }
}

/// The dots fill up one after another, like a progress bar made of dots.
class FillIndicatorEffect extends DotIndicatorEffect {
  /// Creates filling dots.
  const FillIndicatorEffect({
    super.dotWidth,
    super.dotHeight,
    super.spacing,
    super.radius,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
  });

  /// How full dot [index] is for [segment], from 0 to 1.
  double fillOf(int index, IndicatorSegment segment) {
    if (segment.wraps) {
      return index == 0 ? 1 : 1 - segment.t;
    }
    if (index <= segment.from) {
      return 1;
    }
    if (index == segment.to) {
      return segment.t;
    }
    return 0;
  }

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    final Paint paint = dotPaint;
    final Paint active = activePaint;
    for (int i = 0; i < count; i++) {
      final RRect dot = dotAt(dotCenter(i, size));
      canvas.drawRRect(dot, paint);
      final double fill = fillOf(i, segment);
      if (fill <= 0) {
        continue;
      }
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(
            dot.left, dot.top, dot.left + dot.width * fill, dot.bottom),
      );
      canvas.drawRRect(dot, active);
      canvas.restore();
    }
  }
}

/// Story-style bars that fill up one after another.
class SegmentsIndicatorEffect extends FillIndicatorEffect {
  /// Creates story-style segments.
  const SegmentsIndicatorEffect({
    super.dotWidth = 28,
    super.dotHeight = 4,
    super.spacing = 4,
    super.radius = 2,
    super.dotColor,
    super.activeDotColor,
    super.strokeWidth,
    super.paintStyle,
  });
}
