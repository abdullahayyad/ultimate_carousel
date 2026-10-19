import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../item.dart';
import 'effect.dart';
import 'item_matrix.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Items are the faces of a turning cube.
class CubeCarouselEffect extends CarouselEffect {
  /// Creates a cube effect.
  const CubeCarouselEffect({
    this.inside = false,
    this.angle = math.pi / 2,
    this.perspective = 0.0015,
    this.shade = 0.35,
  });

  /// Whether the viewer is inside the cube instead of outside it.
  final bool inside;

  /// How far a face turns while it leaves, in radians. A real cube turns by
  /// a quarter turn (pi / 2).
  final double angle;

  /// The strength of the 3D perspective.
  final double perspective;

  /// How dark a face gets as it turns away, from 0 to 1.
  final double shade;

  @override
  bool get shadesItems => shade > 0;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double dragExtent(CarouselLayout layout) => layout.itemMainExtent;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d.abs() >= 1) {
      return CarouselItemTransform.hidden;
    }
    final double width = info.layout.itemMainExtent;
    final double edge = width / 2;
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..rotateY(
              (inside ? 1 : -1) * d * angle,
              pivot: Offset(d < 0 ? edge : -edge, 0),
            )
            ..translate(d * width)
            ..perspective(perspective))
          .value,
      shade: d.abs() * clampDouble(shade, 0, 1),
    );
  }
}

/// Each item flips over like a card to show the next one on its back.
class FlipCarouselEffect extends CarouselEffect {
  /// Creates a flip effect.
  const FlipCarouselEffect({this.vertical = false, this.perspective = 0.002});

  /// Whether the card flips over its horizontal middle line (like a
  /// calendar) instead of its vertical one.
  final bool vertical;

  /// The strength of the 3D perspective.
  final double perspective;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double dragExtent(CarouselLayout layout) => layout.itemMainExtent;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d.abs() >= 0.5) {
      return CarouselItemTransform.hidden;
    }
    final ItemMatrix matrix = ItemMatrix();
    if (vertical) {
      matrix.rotateX(d * math.pi);
    } else {
      matrix.rotateY(-d * math.pi);
    }
    matrix.perspective(perspective);
    return CarouselItemTransform(matrix: matrix.value);
  }
}

/// The classic cover flow: the current item faces you and its neighbours
/// stand angled to the sides, stacked like records on a shelf.
class CoverflowCarouselEffect extends CarouselEffect {
  /// Creates a cover flow effect.
  const CoverflowCarouselEffect({
    this.angle = 0.9,
    this.sideScale = 0.85,
    this.sideOffset = 0.6,
    this.stackSpacing = 0.25,
    this.depth = 60,
    this.shade = 0.35,
    this.perspective = 0.0015,
    this.viewportFraction = 0.55,
  });

  /// How far the side items are turned, in radians.
  final double angle;

  /// The scale of the side items.
  final double sideScale;

  /// The distance from the current item to its direct neighbours, as a
  /// fraction of an item's width.
  final double sideOffset;

  /// The distance between the further side items, as a fraction of an
  /// item's width. Smaller values stack them more tightly.
  final double stackSpacing;

  /// How far back the side items sit, in logical pixels.
  final double depth;

  /// How dark the side items are, from 0 to 1.
  final double shade;

  /// The strength of the 3D perspective.
  final double perspective;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get shadesItems => shade > 0;

  @override
  int? itemsPerSide(CarouselLayout layout) {
    final double slot = math.max(layout.slotExtent, 1.0);
    final double reach = layout.viewportMainExtent / 2 +
        layout.alignmentOffset.abs() +
        layout.itemMainExtent / 2;
    final double first = sideOffset * slot;
    final double step = math.max(stackSpacing * slot, 1.0);
    final int extra = math.max(0, ((reach - first) / step).ceil());
    return math.min(32, 1 + extra);
  }

  @override
  double dragExtent(CarouselLayout layout) =>
      math.max(layout.slotExtent * sideOffset, 1.0);

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double c = info.clampedDelta;
    final double rest = d - c;
    final double slot = info.layout.slotExtent;
    final double x = c * sideOffset * slot + rest * stackSpacing * slot;
    final double strength = clampDouble(shade, 0, 1);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..rotateY(-c * angle)
            ..scale(_lerp(1, sideScale, c.abs()))
            ..translate(x, 0, c.abs() * depth + rest.abs() * depth * 0.2)
            ..perspective(perspective))
          .value,
      shade: clampDouble(c.abs() * strength + rest.abs() * 0.08, 0, 1),
    );
  }
}

/// Items stand around a ring that turns like a merry-go-round.
class RingCarouselEffect extends CarouselEffect {
  /// Creates a ring.
  const RingCarouselEffect({
    this.itemsOnRing,
    this.radius,
    this.faceViewer = false,
    this.showBackItems = false,
    this.tilt = 0,
    this.perspective = 0.0012,
    this.shade = 0.5,
    this.viewportFraction = 0.5,
  });

  /// How many items fit around the ring. `null` places every item of the
  /// carousel on it, each once.
  final int? itemsOnRing;

  /// The ring's radius in logical pixels. `null` sizes the ring so the
  /// items touch edge to edge.
  final double? radius;

  /// Whether every item turns to face the viewer instead of facing outwards
  /// from the ring.
  final bool faceViewer;

  /// Whether items on the far side of the ring are drawn. Items that face
  /// outwards are seen from behind there, mirrored.
  final bool showBackItems;

  /// How far above the ring the viewer is, in radians. Positive values make
  /// the far side of the ring rise, like looking down on a carousel ride.
  ///
  /// The far side then rises above the items, so leave room for it: give
  /// the carousel `clipBehavior: Clip.none` and some space above it, or pad
  /// the top of your item widgets.
  final double tilt;

  /// The strength of the 3D perspective.
  final double perspective;

  /// How dark the items at the back are, from 0 to 1.
  final double shade;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get uniqueItems => itemsOnRing == null;

  @override
  bool get shadesItems => shade > 0;

  int _count(CarouselLayout layout) =>
      math.max(3, itemsOnRing ?? layout.itemCount);

  double _radius(CarouselLayout layout, int count) {
    return radius ?? (layout.slotExtent / 2) / math.tan(math.pi / count);
  }

  @override
  int? itemsPerSide(CarouselLayout layout) => math.min(32, _count(layout) ~/ 2);

  @override
  double paintOrder(CarouselItemInfo info) {
    return math.cos(info.delta * 2 * math.pi / _count(info.layout));
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final int count = _count(info.layout);
    final double theta = info.delta * 2 * math.pi / count;
    final double cos = math.cos(theta);
    final double sin = math.sin(theta);
    if (!faceViewer && !showBackItems && cos < 0) {
      return CarouselItemTransform.hidden;
    }
    final double r = _radius(info.layout, count);
    final double back = r * (1 - cos);
    final ItemMatrix matrix = ItemMatrix();
    if (!faceViewer) {
      matrix.rotateY(-theta);
    }
    matrix
      ..translate(r * sin, -back * math.sin(tilt), back * math.cos(tilt))
      ..perspective(perspective);
    return CarouselItemTransform(
      matrix: matrix.value,
      shade: clampDouble(shade, 0, 1) * (1 - cos) / 2,
    );
  }
}

/// Items ride on the outside of a turning drum, like a picker wheel.
class WheelCarouselEffect extends CarouselEffect {
  /// Creates a wheel.
  const WheelCarouselEffect({
    this.diameterRatio = 2,
    this.perspective = 0.003,
    this.shade = 0.35,
    this.viewportFraction = 0.3,
  });

  /// The drum's diameter relative to the carousel's length.
  final double diameterRatio;

  /// The strength of the 3D perspective.
  final double perspective;

  /// How dark items get towards the drum's edges, from 0 to 1.
  final double shade;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get shadesItems => shade > 0;

  double _radius(CarouselLayout layout) =>
      math.max(1.0, layout.viewportMainExtent * diameterRatio / 2);

  @override
  int? itemsPerSide(CarouselLayout layout) {
    final double slot = math.max(layout.slotExtent, 1.0);
    return math.min(32, (math.pi / 2 * _radius(layout) / slot).ceil() + 1);
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double r = _radius(info.layout);
    final double theta = info.delta * info.layout.slotExtent / r;
    if (theta.abs() >= math.pi / 2) {
      return CarouselItemTransform.hidden;
    }
    final double cos = math.cos(theta);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..rotateY(-theta)
            ..translate(r * math.sin(theta), 0, r * (1 - cos))
            ..perspective(perspective))
          .value,
      shade: clampDouble(shade, 0, 1) * (1 - cos),
    );
  }
}

/// Items line the inside of a curved wall that wraps around the viewer.
class CylinderCarouselEffect extends CarouselEffect {
  /// Creates a cylinder.
  const CylinderCarouselEffect({
    this.diameterRatio = 2.5,
    this.perspective = 0.0012,
    this.shade = 0.25,
    this.viewportFraction = 0.4,
  });

  /// The cylinder's diameter relative to the carousel's length.
  final double diameterRatio;

  /// The strength of the 3D perspective.
  final double perspective;

  /// How dark the items at the sides are, from 0 to 1.
  final double shade;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get shadesItems => shade > 0;

  double _radius(CarouselLayout layout) =>
      math.max(1.0, layout.viewportMainExtent * diameterRatio / 2);

  @override
  int? itemsPerSide(CarouselLayout layout) {
    final double slot = math.max(layout.slotExtent, 1.0);
    return math.min(32, (1.4 * _radius(layout) / slot).ceil() + 1);
  }

  @override
  double paintOrder(CarouselItemInfo info) => info.distance;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double r = _radius(info.layout);
    final double theta = info.delta * info.layout.slotExtent / r;
    if (theta.abs() >= 1.4) {
      return CarouselItemTransform.hidden;
    }
    // Keep the closest items from coming too near the viewer.
    final double strength = math.min(perspective, 0.6 / r);
    final double cos = math.cos(theta);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..rotateY(theta)
            ..translate(r * math.sin(theta), 0, -r * (1 - cos))
            ..perspective(strength))
          .value,
      shade: clampDouble(shade, 0, 1) * (1 - cos) * 2,
    );
  }
}

/// Items spiral around a column, rising as they go.
class HelixCarouselEffect extends CarouselEffect {
  /// Creates a helix.
  const HelixCarouselEffect({
    this.itemsPerTurn = 8,
    this.radius,
    this.rise = 0.18,
    this.perspective = 0.0012,
    this.shade = 0.5,
    this.viewportFraction = 0.45,
  });

  /// How many items make one full turn.
  final int itemsPerTurn;

  /// The radius of the spiral in logical pixels. `null` sizes it so the
  /// items touch edge to edge.
  final double? radius;

  /// How far each item rises above the previous one, as a fraction of the
  /// item's height.
  final double rise;

  /// The strength of the 3D perspective.
  final double perspective;

  /// How dark the items at the back are, from 0 to 1.
  final double shade;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get shadesItems => shade > 0;

  int get _perTurn => math.max(3, itemsPerTurn);

  @override
  int? itemsPerSide(CarouselLayout layout) => math.min(32, _perTurn ~/ 2);

  @override
  double paintOrder(CarouselItemInfo info) =>
      math.cos(info.delta * 2 * math.pi / _perTurn);

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double theta = info.delta * 2 * math.pi / _perTurn;
    final double cos = math.cos(theta);
    if (cos < -0.2) {
      return CarouselItemTransform.hidden;
    }
    final double r =
        radius ?? (info.layout.slotExtent / 2) / math.tan(math.pi / _perTurn);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..rotateY(-theta)
            ..translate(
              r * math.sin(theta),
              -info.delta * rise * info.layout.itemCrossExtent,
              r * (1 - cos),
            )
            ..perspective(perspective))
          .value,
      shade: clampDouble(shade, 0, 1) * (1 - cos) / 2,
    );
  }
}

/// Items turn like the pages of a book, around their left edge.
class PageTurnCarouselEffect extends CarouselEffect {
  /// Creates a page turn.
  const PageTurnCarouselEffect({this.perspective = 0.0012, this.shade = 0.5});

  /// The strength of the 3D perspective.
  final double perspective;

  /// How dark the turning page and the page below it get, from 0 to 1.
  final double shade;

  @override
  bool get shadesItems => shade > 0;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double dragExtent(CarouselLayout layout) => layout.itemMainExtent;

  @override
  double paintOrder(CarouselItemInfo info) =>
      info.delta <= 0 ? 1 + info.delta : -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d <= -0.5 || d >= 1) {
      return CarouselItemTransform.hidden;
    }
    final double strength = clampDouble(shade, 0, 1);
    if (d > 0) {
      return CarouselItemTransform(shade: strength * d * 0.6);
    }
    final double edge = info.layout.itemMainExtent / 2;
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..rotateY(-d * math.pi, pivot: Offset(-edge, 0))
            ..perspective(perspective))
          .value,
      shade: strength * -d,
    );
  }
}

/// Items wait in a line that disappears into the distance and fly past the
/// viewer when they leave.
class TunnelCarouselEffect extends CarouselEffect {
  /// Creates a tunnel.
  const TunnelCarouselEffect({
    this.depth = 0.55,
    this.visibleItems = 3,
    this.rise = 0.06,
  });

  /// How quickly items shrink with distance.
  final double depth;

  /// How many upcoming items are visible.
  final int visibleItems;

  /// How far each upcoming item rises towards the horizon, as a fraction of
  /// the item's height.
  final double rise;

  int get _visible => math.max(1, visibleItems);

  @override
  int? itemsPerSide(CarouselLayout layout) => _visible + 1;

  @override
  double dragExtent(CarouselLayout layout) =>
      math.max(layout.itemMainExtent, 1.0);

  @override
  double paintOrder(CarouselItemInfo info) => -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d <= -1 || d > _visible + 1) {
      return CarouselItemTransform.hidden;
    }
    if (d <= 0) {
      return CarouselItemTransform(
        matrix: (ItemMatrix()..scale(1 - d * 1.6)).value,
        opacity: 1 + d,
      );
    }
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(1 / (1 + d * math.max(0.0, depth)))
            ..translate(0, -d * rise * info.layout.itemCrossExtent))
          .value,
      opacity: clampDouble(_visible + 1 - d, 0, 1),
    );
  }
}

/// Neighbours turn away from the viewer as if on the screen of a tilted
/// tablet, staying edge to edge with the current item.
class TabletCarouselEffect extends CarouselEffect {
  /// Creates a tablet effect.
  const TabletCarouselEffect({
    this.angle = 0.52,
    this.perspective = 0.0015,
    this.shade = 0.2,
  });

  /// How far a neighbour is turned, in radians.
  final double angle;

  /// The strength of the 3D perspective.
  final double perspective;

  /// How dark a neighbour gets, from 0 to 1.
  final double shade;

  @override
  bool get shadesItems => shade > 0;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double c = info.clampedDelta;
    final double turn = -c * angle;
    final double half = info.layout.itemMainExtent / 2;
    // Pull the turned item back towards the current one, so their facing
    // edges stay together while the turn narrows it.
    final double pull = half * (1 - math.cos(turn)) * (d < 0 ? 1 : -1);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..rotateY(turn)
            ..translate(d * info.layout.slotExtent + pull)
            ..perspective(perspective))
          .value,
      shade: clampDouble(shade, 0, 1) * c.abs(),
    );
  }
}
