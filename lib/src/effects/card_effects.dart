import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../item.dart';
import 'effect.dart';
import 'item_matrix.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// The upcoming items wait in a deck behind the current one; the current
/// item slides off and the deck moves up.
class DeckCarouselEffect extends CarouselEffect {
  /// Creates a deck.
  const DeckCarouselEffect({
    this.visibleCards = 3,
    this.offset = 0.08,
    this.scaleStep = 0.07,
    this.leaveAngle = 0,
    this.viewportFraction = 0.78,
  });

  /// How many cards show behind the current one.
  final int visibleCards;

  /// How far each card behind peeks out, as a fraction of the card's width.
  final double offset;

  /// How much smaller each card behind is.
  final double scaleStep;

  /// How far the leaving card turns, in radians.
  final double leaveAngle;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  int? itemsPerSide(CarouselLayout layout) => math.max(1, visibleCards) + 1;

  @override
  double paintOrder(CarouselItemInfo info) =>
      info.delta <= 0 ? 1 - info.delta : -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double width = info.layout.itemMainExtent;
    final int cards = math.max(1, visibleCards);
    if (d <= -1 || d > cards + 1) {
      return CarouselItemTransform.hidden;
    }
    if (d <= 0) {
      return CarouselItemTransform(
        matrix: (ItemMatrix()
              ..rotateZ(d * leaveAngle)
              ..translate(d * (info.layout.slotExtent + width * 0.15)))
            .value,
        opacity: clampDouble(1 + d * 0.6, 0, 1),
      );
    }
    final double fade = clampDouble(cards + 1 - d, 0, 1);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(math.max(0.1, 1 - d * scaleStep))
            ..translate(d * offset * width))
          .value,
      opacity: fade,
    );
  }
}

/// A pile of cards: the top card is thrown off to the side with a twist,
/// like swiping a dating app, and the pile moves up.
class TinderCarouselEffect extends CarouselEffect {
  /// Creates a tinder-style pile.
  const TinderCarouselEffect({
    this.visibleCards = 3,
    this.maxAngle = 0.35,
    this.peek = 14,
    this.scaleStep = 0.06,
    this.viewportFraction = 0.8,
  });

  /// How many cards show under the top card.
  final int visibleCards;

  /// How far the thrown card turns, in radians.
  final double maxAngle;

  /// How far each card underneath peeks out at the bottom, in logical
  /// pixels.
  final double peek;

  /// How much smaller each card underneath is.
  final double scaleStep;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  int? itemsPerSide(CarouselLayout layout) => math.max(1, visibleCards) + 1;

  @override
  double paintOrder(CarouselItemInfo info) =>
      info.delta <= 0 ? 1 - info.delta : -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final int cards = math.max(1, visibleCards);
    if (d <= -1 || d > cards + 1) {
      return CarouselItemTransform.hidden;
    }
    final double height = info.layout.itemCrossExtent;
    if (d <= 0) {
      return CarouselItemTransform(
        matrix: (ItemMatrix()
              ..rotateZ(d * maxAngle, pivot: Offset(0, height / 2))
              ..translate(
                d * (info.layout.slotExtent + info.layout.itemMainExtent * 0.3),
                d * height * 0.08,
              ))
            .value,
      );
    }
    final double fade = clampDouble(cards + 1 - d, 0, 1);
    final double scale = math.max(0.1, 1 - d * scaleStep);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(scale)
            ..translate(0, d * peek + height * (1 - scale) / 2))
          .value,
      opacity: fade,
    );
  }
}

/// Items spread out like a hand of cards, turning around a point below the
/// carousel.
class FanCarouselEffect extends CarouselEffect {
  /// Creates a fan.
  const FanCarouselEffect({
    this.angle = 0.18,
    this.radius = 2.2,
    this.sideScale = 0.92,
    this.viewportFraction = 0.55,
  });

  /// The turn between neighbouring cards, in radians.
  final double angle;

  /// The distance from a card's center to the point the fan turns around,
  /// as a multiple of the card's height.
  final double radius;

  /// The scale of the cards next to the current one.
  final double sideScale;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  int? itemsPerSide(CarouselLayout layout) {
    final double turn = math.max(angle.abs(), 0.01);
    return math.min(12, (math.pi / 2 / turn).floor());
  }

  @override
  double dragExtent(CarouselLayout layout) =>
      math.max(layout.itemCrossExtent * radius * angle.abs(), 1.0);

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double turn = d * angle;
    if (turn.abs() >= math.pi / 2) {
      return CarouselItemTransform.hidden;
    }
    final double pivot = info.layout.itemCrossExtent * radius;
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(_lerp(1, sideScale, info.clampedDelta.abs()))
            ..rotateZ(turn, pivot: Offset(0, pivot)))
          .value,
    );
  }
}

/// Items sit on a curve, like a smile or a rainbow, and travel along it.
class ArcCarouselEffect extends CarouselEffect {
  /// Creates an arc.
  const ArcCarouselEffect({
    this.radius = 3,
    this.upward = true,
    this.tilt = true,
    this.sideScale = 0.9,
    this.viewportFraction = 0.42,
  });

  /// The radius of the curve, as a multiple of an item's width.
  final double radius;

  /// Whether the curve bends up at the ends like a smile; otherwise it bends
  /// down like a rainbow.
  final bool upward;

  /// Whether items lean along the curve instead of staying upright.
  final bool tilt;

  /// The scale of the direct neighbours.
  final double sideScale;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  double _radius(CarouselLayout layout) =>
      math.max(1.0, layout.itemMainExtent * radius);

  @override
  int? itemsPerSide(CarouselLayout layout) {
    final double slot = math.max(layout.slotExtent, 1.0);
    return math.min(16, (layout.viewportMainExtent / slot).ceil() + 1);
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double r = _radius(info.layout);
    final double angle = info.delta * info.layout.slotExtent / r;
    if (angle.abs() >= math.pi / 2) {
      return CarouselItemTransform.hidden;
    }
    final double turn = upward ? -angle : angle;
    final ItemMatrix matrix = ItemMatrix()
      ..scale(_lerp(1, sideScale, info.clampedDelta.abs()));
    if (!tilt) {
      matrix.rotateZ(-turn);
    }
    matrix.rotateZ(turn, pivot: Offset(0, upward ? -r : r));
    return CarouselItemTransform(matrix: matrix.value);
  }
}

/// A messy pile of photos: each item lies at its own angle and the top one
/// straightens up before it is tossed aside.
class ScatterCarouselEffect extends CarouselEffect {
  /// Creates a scattered pile.
  const ScatterCarouselEffect({
    this.maxAngle = 0.22,
    this.spread = 0.06,
    this.visibleCards = 4,
    this.viewportFraction = 0.72,
  });

  /// The largest angle an item in the pile lies at, in radians.
  final double maxAngle;

  /// How far items in the pile are pushed off center, as a fraction of their
  /// size.
  final double spread;

  /// How many items show under the top one.
  final int visibleCards;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  int? itemsPerSide(CarouselLayout layout) => math.max(1, visibleCards) + 1;

  @override
  double paintOrder(CarouselItemInfo info) =>
      info.delta <= 0 ? 1 - info.delta : -info.delta;

  /// A repeatable pseudo-random number between -1 and 1 for an item.
  static double _noise(int index, int salt) {
    final double x = math.sin(index * 12.9898 + salt * 78.233) * 43758.5453;
    return (x - x.floorToDouble()) * 2 - 1;
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final int cards = math.max(1, visibleCards);
    if (d <= -1 || d > cards + 1) {
      return CarouselItemTransform.hidden;
    }
    final CarouselLayout layout = info.layout;
    if (d <= 0) {
      return CarouselItemTransform(
        matrix: (ItemMatrix()
              ..rotateZ(d * maxAngle * 1.5)
              ..translate(
                d * (layout.slotExtent + layout.itemMainExtent * 0.3),
                -d * layout.itemCrossExtent * 0.05,
              ))
            .value,
      );
    }
    final double pose = clampDouble(d, 0, 1);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(1 - 0.03 * math.min(d, cards.toDouble()))
            ..rotateZ(_noise(info.index, 1) * maxAngle * pose)
            ..translate(
              _noise(info.index, 2) * spread * layout.itemMainExtent * pose,
              _noise(info.index, 3) * spread * layout.itemCrossExtent * pose,
            ))
          .value,
      opacity: clampDouble(cards + 1 - d, 0, 1),
    );
  }
}
