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
      // The top card stays solid while it slides off, so the card below
      // never shows through it.
      return CarouselItemTransform(
        matrix: (ItemMatrix()
              ..rotateZ(d * leaveAngle)
              ..translate(d * (info.layout.slotExtent + width * 0.15)))
            .value,
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

/// The current item lies on top of a stack that spreads to both sides: its
/// neighbours hide behind it, smaller and paler, so only slivers of them
/// peek out.
class LayeredCarouselEffect extends CarouselEffect {
  /// Creates a layered stack.
  const LayeredCarouselEffect({
    this.spread = 0.19,
    this.outerSpread = 0.32,
    this.scaleStep = 0.3,
    this.minScale = 0.5,
    this.fade = 0.5,
    this.maxFade = 0.8,
    this.fadeColor = const Color(0xFFFFFFFF),
    this.balanceEnds = true,
    this.viewportFraction = 0.84,
  });

  /// How far the direct neighbours sit from the current item, as a fraction
  /// of an item's width.
  final double spread;

  /// How far the items two places away sit, as a fraction of an item's
  /// width. Items further away wait hidden behind them.
  final double outerSpread;

  /// How much smaller each item is than the one in front of it.
  final double scaleStep;

  /// The smallest size an item shrinks to, from 0 to 1.
  final double minScale;

  /// How much paler each item is than the one in front of it, from 0 to 1.
  final double fade;

  /// The palest an item gets, from 0 to 1.
  final double maxFade;

  /// The color items fade towards. White makes them paler; the color behind
  /// the carousel makes them sink into it.
  final Color fadeColor;

  /// Whether a carousel that does not loop moves the stack sideways near its
  /// first and last items, so the stack stays centered while one side has
  /// fewer items.
  final bool balanceEnds;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get shadesItems => fade > 0 && maxFade > 0;

  @override
  Color get shadeColor => fadeColor;

  @override
  int? itemsPerSide(CarouselLayout layout) => 3;

  @override
  double dragExtent(CarouselLayout layout) =>
      math.max(layout.itemMainExtent * 0.5, 1.0);

  /// The distance of an item [away] places from the current one, as a
  /// fraction of an item's width: a curve through [spread] and [outerSpread]
  /// that stops two places away.
  double _offset(double away) {
    final double a = math.min(away, 2.0);
    final double bend = (outerSpread - 2 * spread) / 2;
    return (spread - bend) * a + bend * a * a;
  }

  double _scale(double away) =>
      math.max(clampDouble(minScale, 0, 1), 1 - scaleStep * away);

  /// How far the stack reaches to one side, as a fraction of an item's
  /// width, when [count] items (up to 2) are there.
  double _reach(double count) {
    double edge(double away) => _offset(away) + _scale(away) / 2;
    final double c = clampDouble(count, 0, 2);
    return c <= 1 ? _lerp(0.5, edge(1), c) : _lerp(edge(1), edge(2), c - 1);
  }

  double _balance(CarouselItemInfo info) {
    final CarouselLayout layout = info.layout;
    if (!balanceEnds || layout.loop || layout.itemCount < 2) {
      return 0;
    }
    final double before = info.page;
    final double after = layout.itemCount - 1 - info.page;
    // Shift the stack so its two ends sit evenly around the middle.
    return (_reach(before) - _reach(after)) / 2 * layout.itemMainExtent;
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double away = d.abs();
    if (away > 3) {
      return CarouselItemTransform.hidden;
    }
    final double x =
        d.sign * _offset(away) * info.layout.itemMainExtent + _balance(info);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(_scale(away))
            ..translate(x))
          .value,
      shade: math.min(
        clampDouble(maxFade, 0, 1),
        clampDouble(fade, 0, 1) * away,
      ),
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

/// Every item shows as a panel side by side across the carousel: the current
/// one is wide and the others are narrow strips, and moving hands the width
/// from one panel to the next. This is the expanding cards gallery from the
/// web.
///
/// Items are masked, not squeezed: their content keeps its size and the
/// rounded mask around it changes. All items are on screen at once, so this
/// suits a handful of items.
class ExpandingCardsCarouselEffect extends CarouselEffect {
  /// Creates expanding cards.
  const ExpandingCardsCarouselEffect({
    this.expandedFraction = 0.6,
    this.gap = 8,
    this.cornerRadius = 24,
  });

  /// How much of the carousel the current panel takes, from 0 to 1.
  final double expandedFraction;

  /// The gap between panels, in logical pixels.
  final double gap;

  /// The corner radius of the panels.
  final double cornerRadius;

  @override
  double get defaultViewportFraction => clampDouble(expandedFraction, 0.05, 1);

  @override
  bool get uniqueItems => true;

  @override
  int? itemsPerSide(CarouselLayout layout) => math.max(1, layout.itemCount - 1);

  /// The widths of a wide and a narrow panel.
  (double, double) _widths(CarouselLayout layout) {
    final int count = math.max(1, layout.itemCount);
    final double room = math.max(
      0.0,
      layout.viewportMainExtent - (count - 1) * math.max(0.0, gap),
    );
    if (count == 1) {
      return (room, room);
    }
    final double wide = room * clampDouble(expandedFraction, 0, 1);
    return (wide, (room - wide) / (count - 1));
  }

  @override
  double dragExtent(CarouselLayout layout) {
    final (double wide, double narrow) = _widths(layout);
    return math.max(wide - narrow, 1.0);
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final CarouselLayout layout = info.layout;
    final int count = math.max(1, layout.itemCount);
    final (double wide, double narrow) = _widths(layout);
    final double page = layout.loop
        ? info.page % count
        : clampDouble(info.page, 0, count - 1.0);
    final int from = page.floor();
    final double t = page - from;
    final int to =
        layout.loop ? (from + 1) % count : math.min(from + 1, count - 1);
    double widthOf(int index) {
      double active = 0;
      if (index == from) {
        active += 1 - t;
      }
      if (index == to && to != from) {
        active += t;
      }
      return narrow + (wide - narrow) * active;
    }

    final int index = info.index;
    double left = 0;
    for (int i = 0; i < index; i++) {
      left += widthOf(i) + math.max(0.0, gap);
    }
    final double width = widthOf(index);
    if (width <= 0.5) {
      return CarouselItemTransform.hidden;
    }
    final double base = layout.viewportMainExtent / 2 + layout.alignmentOffset;
    return CarouselItemTransform(
      matrix: Matrix4.translationValues(left + width / 2 - base, 0, 0),
      clipPath: Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width,
              height: layout.itemCrossExtent,
            ),
            Radius.circular(math.min(cornerRadius, width / 2)),
          ),
        ),
    );
  }
}

/// A neat pile of cards whose top card flips over as it is dealt off to the
/// side, catching the light on the way; the cards below lie a little askew
/// and in shadow until their turn comes.
///
/// This is the card deck demo of the flutter_custom_carousel package.
class DealCarouselEffect extends CarouselEffect {
  /// Creates a dealt pile.
  const DealCarouselEffect({
    this.visibleCards = 3,
    this.tilt = 0.05,
    this.shade = 0.15,
    this.flipAngle = 0.8,
    this.distance = 1.3,
    this.gloss = 0.5,
    this.perspective = 0.002,
    this.viewportFraction = 0.6,
  });

  /// How many cards show under the top one.
  final int visibleCards;

  /// How far each card under the top one is turned, in radians.
  final double tilt;

  /// How much darker each card under the top one is, from 0 to 1.
  final double shade;

  /// How far the dealt card turns over, in radians.
  final double flipAngle;

  /// How far the dealt card travels, in card widths.
  final double distance;

  /// How bright the glint that crosses the dealt card is, from 0 (none) to
  /// 1. The glint draws every card through a shader mask, so turn it off on
  /// slow devices.
  final double gloss;

  /// The strength of the 3D perspective of the flip.
  final double perspective;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  int get _cards => math.max(1, visibleCards);

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get shadesItems => shade > 0;

  @override
  int? itemsPerSide(CarouselLayout layout) => _cards + 1;

  @override
  double paintOrder(CarouselItemInfo info) =>
      info.delta <= 0 ? 1 - info.delta : -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final int cards = _cards;
    if (d <= -1 || d > cards + 1) {
      return CarouselItemTransform.hidden;
    }
    if (d <= 0) {
      // The top card turns its trailing edge up towards the viewer while it
      // is dealt off towards the side the user swiped.
      final double travel = -d;
      return CarouselItemTransform(
        matrix: (ItemMatrix()
              ..rotateY(flipAngle * travel)
              ..translate(-travel * distance * info.layout.itemMainExtent)
              ..perspective(perspective))
            .value,
      );
    }
    final double depth = math.min(d, cards.toDouble());
    return CarouselItemTransform(
      matrix: (ItemMatrix()..rotateZ(tilt * depth)).value,
      shade: clampDouble(shade * depth, 0, 0.9),
      opacity: clampDouble(cards + 1 - d, 0, 1),
    );
  }

  @override
  Widget decorate(BuildContext context, Widget child, CarouselItemInfo info) {
    if (gloss <= 0) {
      return child;
    }
    final double travel = clampDouble(-info.delta, 0, 1);
    // The glint sweeps across the card while it flips and is gone by the
    // time the card lands, so cards at rest show no trace of it.
    final double strength =
        clampDouble(gloss, 0, 1) * math.sin(math.pi * travel);
    final double center = -0.2 + 1.4 * travel;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (Rect bounds) => _glint(bounds, center, strength),
      child: child,
    );
  }

  static Shader _glint(Rect bounds, double center, double strength) {
    const double half = 0.2;
    const Color clear = Color(0x00FFFFFF);
    final Color light = const Color(0xFFFFFFFF)
        .withAlpha((255 * clampDouble(strength, 0, 1)).round());
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[clear, light, clear],
      stops: <double>[
        clampDouble(center - half, 0, 1),
        clampDouble(center, 0, 1),
        clampDouble(center + half, 0, 1),
      ],
    ).createShader(bounds);
  }
}

/// The upcoming cards wait in a stack that climbs away behind the current
/// card, each one further over, more blurred and fainter; the current card
/// slides off to the side to show the next one, like the cards of a
/// digital wallet.
///
/// The cards are made a little smaller so the whole stack fits inside the
/// carousel. This is the digital wallet demo of the flutter_custom_carousel
/// package.
class WalletCarouselEffect extends CarouselEffect {
  /// Creates a wallet stack.
  const WalletCarouselEffect({
    this.visibleCards = 3,
    this.offset = const Offset(0.12, -0.12),
    this.blur = 2.5,
    this.fade = 0.25,
    this.viewportFraction = 0.75,
  });

  /// How many cards show behind the current one.
  final int visibleCards;

  /// Where each card sits relative to the one in front of it, as fractions
  /// of a card's size: `dx` along the carousel (positive is towards the next
  /// item) and `dy` across it (negative is up).
  final Offset offset;

  /// How much more each card behind is blurred, as a blur radius in logical
  /// pixels.
  final double blur;

  /// How much fainter each card is than the one in front of it, from the
  /// second card back, from 0 to 1.
  final double fade;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  int get _cards => math.max(1, visibleCards);

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get blursItems => blur > 0;

  @override
  int? itemsPerSide(CarouselLayout layout) => _cards + 1;

  @override
  double paintOrder(CarouselItemInfo info) =>
      info.delta <= 0 ? 1 - info.delta : -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final int cards = _cards;
    if (d <= -1 || d > cards + 1) {
      return CarouselItemTransform.hidden;
    }
    final CarouselLayout layout = info.layout;
    final double width = layout.itemMainExtent;
    final double height = layout.itemCrossExtent;
    // Shrink the cards so the stack, front card to back card, fits in the
    // item's box, and centre the stack in it.
    final double fit = math.min(
      1 / (1 + cards * offset.dx.abs()),
      1 / (1 + cards * offset.dy.abs()),
    );
    final double stepX = offset.dx * fit * width;
    final double stepY = offset.dy * fit * height;
    final double frontX = -stepX * cards / 2;
    final double frontY = -stepY * cards / 2;
    if (d <= 0) {
      // The front card slides off, staying sharp, far enough to leave the
      // carousel.
      return CarouselItemTransform(
        matrix: (ItemMatrix()
              ..scale(fit)
              ..translate(
                  frontX + d * (layout.slotExtent + width * 0.1), frontY))
            .value,
      );
    }
    final double depth = math.min(d, cards.toDouble());
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(fit)
            ..translate(frontX + depth * stepX, frontY + depth * stepY))
          .value,
      blur: math.max(0.0, blur) * depth,
      opacity: clampDouble(1 - math.max(0.0, depth - 1) * fade, 0, 1) *
          clampDouble(cards + 1 - d, 0, 1),
    );
  }
}
