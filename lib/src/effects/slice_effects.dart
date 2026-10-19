import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../item.dart';
import 'effect.dart';

/// How the strips of [SlicerCarouselEffect] leave.
enum CarouselSliceStyle {
  /// The strips slide away, up and down in turn.
  slide,

  /// The strips shrink to nothing.
  shrink,

  /// The strips turn edge-on, like blinds closing.
  turn,
}

/// The current item breaks into strips that leave one after another and
/// uncover the next item waiting underneath, like the Slicer slider of the
/// Swiper web slider.
///
/// Every strip draws the whole item and shows its own part of it, so the
/// item is built once per strip. That is fine for pictures; keep heavy
/// widgets out of slicer carousels.
class SlicerCarouselEffect extends CarouselEffect {
  /// Creates a slicer.
  const SlicerCarouselEffect({
    this.slices = 6,
    this.style = CarouselSliceStyle.slide,
    this.stagger = 0.5,
  });

  /// How many strips the item breaks into.
  final int slices;

  /// How the strips leave.
  final CarouselSliceStyle style;

  /// How far apart the strips start moving, from 0 (all together) to 0.9
  /// (one after another).
  final double stagger;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double dragExtent(CarouselLayout layout) =>
      math.max(layout.itemMainExtent, 1.0);

  // The leaving item is drawn over the one it uncovers.
  @override
  double paintOrder(CarouselItemInfo info) => -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    return info.delta.abs() >= 1
        ? CarouselItemTransform.hidden
        : CarouselItemTransform.identity;
  }

  @override
  Widget decorate(BuildContext context, Widget child, CarouselItemInfo info) {
    return _Slices(
      count: math.max(1, slices),
      // Only an item that is leaving breaks up.
      amount: clampDouble(-info.delta, 0, 1),
      stagger: clampDouble(stagger, 0, 0.9),
      style: style,
      layout: info.layout,
      child: child,
    );
  }
}

/// The next item comes in as slats that turn open one after another over
/// the current item, like the Shutters slider of the Swiper web slider.
///
/// Every slat draws the whole item and shows its own part of it, so the
/// item is built once per slat. That is fine for pictures; keep heavy
/// widgets out of shutters carousels.
class ShuttersCarouselEffect extends CarouselEffect {
  /// Creates shutters.
  const ShuttersCarouselEffect({this.slats = 8, this.stagger = 0.5});

  /// How many slats the item is cut into.
  final int slats;

  /// How far apart the slats start turning, from 0 (all together) to 0.9
  /// (one after another).
  final double stagger;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double dragExtent(CarouselLayout layout) =>
      math.max(layout.itemMainExtent, 1.0);

  // The arriving item is drawn over the one it covers.
  @override
  double paintOrder(CarouselItemInfo info) => info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    return info.delta.abs() >= 1
        ? CarouselItemTransform.hidden
        : CarouselItemTransform.identity;
  }

  @override
  Widget decorate(BuildContext context, Widget child, CarouselItemInfo info) {
    return _Slices(
      count: math.max(1, slats),
      // Only an item that is arriving has slats still turned away.
      amount: clampDouble(info.delta, 0, 1),
      stagger: clampDouble(stagger, 0, 0.9),
      style: CarouselSliceStyle.turn,
      layout: info.layout,
      child: child,
    );
  }
}

/// Draws [child] as [count] strips across the scroll direction, each moved
/// away by its share of [amount].
class _Slices extends StatelessWidget {
  const _Slices({
    required this.count,
    required this.amount,
    required this.stagger,
    required this.style,
    required this.layout,
    required this.child,
  });

  final int count;
  final double amount;
  final double stagger;
  final CarouselSliceStyle style;
  final CarouselLayout layout;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool horizontal = layout.scrollDirection == Axis.horizontal;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        for (int i = 0; i < count; i++) _strip(i, horizontal),
      ],
    );
  }

  Widget _strip(int index, bool horizontal) {
    // The strip nearest the next item moves first.
    final int order = layout.reversed ? index : count - 1 - index;
    final double start = count == 1 ? 0 : stagger * order / (count - 1);
    final double local = clampDouble((amount - start) / (1 - stagger), 0, 1);
    final double moved = Curves.easeIn.transform(local);
    final double middle = -1 + (2 * index + 1) / count;
    final Alignment center =
        horizontal ? Alignment(middle, 0) : Alignment(0, middle);
    Widget strip = ClipRect(
      clipper: _StripClipper(index, count, horizontal),
      // Screen readers only need to hear the item once.
      child: index == 0 ? child : ExcludeSemantics(child: child),
    );
    switch (style) {
      case CarouselSliceStyle.slide:
        final double away = index.isEven ? -moved : moved;
        strip = FractionalTranslation(
          translation: horizontal ? Offset(0, away) : Offset(away, 0),
          child: strip,
        );
      case CarouselSliceStyle.shrink:
        strip = Transform.scale(
          scale: 1 - moved,
          alignment: center,
          child: strip,
        );
      case CarouselSliceStyle.turn:
        final double angle = moved * math.pi / 2;
        strip = Transform(
          alignment: center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..multiply(
              horizontal ? Matrix4.rotationY(angle) : Matrix4.rotationX(angle),
            ),
          child: strip,
        );
    }
    return strip;
  }
}

class _StripClipper extends CustomClipper<Rect> {
  const _StripClipper(this.index, this.count, this.horizontal);

  final int index;
  final int count;
  final bool horizontal;

  @override
  Rect getClip(Size size) {
    if (horizontal) {
      final double width = size.width / count;
      return Rect.fromLTWH(index * width, 0, width, size.height);
    }
    final double height = size.height / count;
    return Rect.fromLTWH(0, index * height, size.width, height);
  }

  @override
  bool shouldReclip(_StripClipper oldClipper) {
    return oldClipper.index != index ||
        oldClipper.count != count ||
        oldClipper.horizontal != horizontal;
  }
}
