import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'dot_effects.dart';
import 'other_effects.dart';

/// How a `CarouselIndicator` looks and moves.
///
/// Pick a built-in effect with the named constructors, for example
/// `const IndicatorEffect.expandingDots()`, or subclass this to paint your
/// own.
///
/// Effects paint in a horizontal, left-to-right space; the indicator turns
/// and mirrors them for vertical and right-to-left layouts.
abstract class IndicatorEffect {
  /// Lets subclasses be const.
  const IndicatorEffect();

  /// A pill that stretches from one dot to the next like a worm.
  const factory IndicatorEffect.worm({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    WormStyle style,
  }) = WormIndicatorEffect;

  /// The current dot stretches into a wide pill.
  const factory IndicatorEffect.expandingDots({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    double expansionFactor,
  }) = ExpandingDotsIndicatorEffect;

  /// The current dot jumps from one place to the next.
  const factory IndicatorEffect.jumpingDot({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    double jumpScale,
    double verticalOffset,
  }) = JumpingDotIndicatorEffect;

  /// The current dot hops to the next place and shrinks in mid-air, like a
  /// drop of water.
  const factory IndicatorEffect.drop({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    double dropHeight,
    double dropScale,
  }) = DropIndicatorEffect;

  /// The current dot slides to the next place and shrinks on the way.
  const factory IndicatorEffect.wave({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    double minScale,
  }) = WaveIndicatorEffect;

  /// Rings like radio buttons: a dot grows inside the current ring.
  const factory IndicatorEffect.radio({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    double innerScale,
  }) = RadioIndicatorEffect;

  /// Only a few dots show and they scroll along, for long lists.
  const factory IndicatorEffect.scrollingDots({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    int maxVisibleDots,
    double activeDotScale,
    double smallDotScale,
    bool fixedCenter,
  }) = ScrollingDotsIndicatorEffect;

  /// The current dot slides over (or under) the others.
  const factory IndicatorEffect.slide({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    bool underneath,
  }) = SlideIndicatorEffect;

  /// The current dot grows and changes color.
  const factory IndicatorEffect.scale({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    double activeDotScale,
  }) = ScaleIndicatorEffect;

  /// The current dot swaps places with the next one.
  const factory IndicatorEffect.swap({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
    SwapStyle style,
  }) = SwapIndicatorEffect;

  /// The dots only change color.
  const factory IndicatorEffect.colorTransition({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
  }) = ColorTransitionIndicatorEffect;

  /// The dots fill up one after another, like a progress bar made of dots.
  const factory IndicatorEffect.fill({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
  }) = FillIndicatorEffect;

  /// Story-style bars that fill up one after another.
  const factory IndicatorEffect.segments({
    double dotWidth,
    double dotHeight,
    double spacing,
    double radius,
    Color dotColor,
    Color activeDotColor,
    double strokeWidth,
    PaintingStyle paintStyle,
  }) = SegmentsIndicatorEffect;

  /// A thin track with a sliding (or filling) bar.
  const factory IndicatorEffect.line({
    double? length,
    double thickness,
    Color trackColor,
    Color activeColor,
    bool fill,
  }) = LineIndicatorEffect;

  /// The position as text, such as "3 / 10".
  const factory IndicatorEffect.fraction({
    TextStyle style,
    String separator,
  }) = FractionIndicatorEffect;

  /// The size of the indicator for [count] items, in its own horizontal
  /// space.
  Size calculateSize(int count);

  /// Paints the indicator for [page], which runs from 0 to [count].
  ///
  /// Values above `count - 1` mean a looping carousel is moving from its last
  /// item to its first.
  void paint(Canvas canvas, Size size, double page, int count);

  /// The index of the item whose dot is at [position], or `null`.
  int? hitTest(Offset position, Size size, double page, int count) => null;

  /// Whether the indicator turns with a vertical carousel. Text-based effects
  /// return false so their text stays upright.
  bool get followsAxis => true;
}

/// Where a page value sits between two items.
@immutable
class IndicatorSegment {
  /// Splits [page] (from 0 to [count]) into the item it leaves, the item it
  /// moves to and how far along it is.
  factory IndicatorSegment.of(double page, int count) {
    if (count <= 1) {
      return const IndicatorSegment._(0, 0, 0);
    }
    int from = page.floor();
    double t = page - from;
    if (from >= count) {
      from = count - 1;
      t = 1;
    } else if (from < 0) {
      from = 0;
      t = 0;
    }
    return IndicatorSegment._(from, (from + 1) % count, t);
  }

  const IndicatorSegment._(this.from, this.to, this.t);

  /// The item being left.
  final int from;

  /// The item being moved to.
  final int to;

  /// How far the move has come, from 0 to 1.
  final double t;

  /// Whether this move goes from the last item back to the first.
  bool get wraps => to < from && t > 0;

  /// How strongly item [index] counts as the current one, from 0 to 1.
  double activeness(int index) {
    if (from == to) {
      return index == from ? 1 : 0;
    }
    if (index == from) {
      return 1 - t;
    }
    if (index == to) {
      return t;
    }
    return 0;
  }
}

/// Paints [draw] at [opacity] by using a translucent layer.
void paintWithOpacity(
  Canvas canvas,
  Size size,
  double opacity,
  VoidCallback draw,
) {
  if (opacity <= 0) {
    return;
  }
  if (opacity >= 1) {
    draw();
    return;
  }
  final Rect bounds = (Offset.zero & size).inflate(math.max(size.width, 40));
  canvas.saveLayer(
    bounds,
    Paint()..color = Color.fromARGB((opacity * 255).round(), 0, 0, 0),
  );
  draw();
  canvas.restore();
}
