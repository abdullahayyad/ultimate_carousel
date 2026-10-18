import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../item.dart';
import 'effect.dart';
import 'item_matrix.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// How [EnlargeCarouselEffect] makes the current item stand out.
enum CarouselEnlargeStrategy {
  /// Shrink the neighbours evenly around their centers.
  scale,

  /// Shrink only the neighbours' height (their extent across the carousel).
  height,

  /// Shrink the neighbours towards the current item, so they look closer.
  zoom,
}

/// Items slide side by side. This is the default effect.
class SlideCarouselEffect extends CarouselEffect {
  /// Creates a plain slide.
  const SlideCarouselEffect();

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    return CarouselItemTransform(
      matrix: Matrix4.translationValues(
        info.delta * info.layout.slotExtent,
        0,
        0,
      ),
    );
  }
}

/// Items fade into each other in place.
class FadeCarouselEffect extends CarouselEffect {
  /// Creates a fade.
  ///
  /// By default the incoming item fades in over the outgoing one, which
  /// stays solid. With [crossFade] both fade at the same time.
  const FadeCarouselEffect({this.crossFade = false});

  /// Whether the outgoing item fades out while the incoming one fades in.
  final bool crossFade;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double paintOrder(CarouselItemInfo info) => info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d.abs() >= 1) {
      return CarouselItemTransform.hidden;
    }
    if (d <= 0) {
      return CarouselItemTransform(opacity: crossFade ? 1 + d : 1);
    }
    return CarouselItemTransform(opacity: 1 - d);
  }
}

/// The current item is full size and its neighbours are smaller, like the
/// "enlarge center page" option of popular carousels.
class EnlargeCarouselEffect extends CarouselEffect {
  /// Creates an enlarge effect.
  const EnlargeCarouselEffect({
    this.factor = 0.3,
    this.strategy = CarouselEnlargeStrategy.scale,
    this.minOpacity = 1,
    this.viewportFraction = 0.8,
  });

  /// How much smaller a neighbour is, from 0 to 1.
  final double factor;

  /// How the neighbours shrink.
  final CarouselEnlargeStrategy strategy;

  /// The opacity of a neighbour one item away.
  final double minOpacity;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double ratio =
        clampDouble(1 - info.distance * clampDouble(factor, 0, 1), 0, 1);
    final double scale = Curves.easeOut.transform(ratio);
    final ItemMatrix matrix = ItemMatrix();
    switch (strategy) {
      case CarouselEnlargeStrategy.scale:
        matrix.scale(scale);
      case CarouselEnlargeStrategy.height:
        matrix.scale(1, y: scale);
      case CarouselEnlargeStrategy.zoom:
        final double edge = info.layout.itemMainExtent / 2;
        matrix.scale(scale, pivot: Offset(d < 0 ? edge : -edge, 0));
    }
    matrix.translate(d * info.layout.slotExtent);
    return CarouselItemTransform(
      matrix: matrix.value,
      opacity: _lerp(1, clampDouble(minOpacity, 0, 1), info.clampedDelta.abs()),
    );
  }
}

/// Neighbours shrink a little and fade while sliding, like Android's classic
/// zoom-out page transformer.
class ZoomOutCarouselEffect extends CarouselEffect {
  /// Creates a zoom-out effect.
  const ZoomOutCarouselEffect({this.minScale = 0.85, this.minOpacity = 0.5});

  /// The scale of an item one position away.
  final double minScale;

  /// The opacity of an item one position away.
  final double minOpacity;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final CarouselLayout layout = info.layout;
    if (d.abs() > 1) {
      return CarouselItemTransform(
        matrix: Matrix4.translationValues(d * layout.slotExtent, 0, 0),
        visible: false,
      );
    }
    final double lowest = clampDouble(minScale, 0, 1);
    final double scale = math.max(lowest, 1 - d.abs());
    final double across = layout.itemCrossExtent * (1 - scale) / 2;
    final double along = layout.itemMainExtent * (1 - scale) / 2;
    final double shift = d < 0 ? along - across / 2 : -along + across / 2;
    final double opacity = lowest >= 1
        ? 1
        : minOpacity + (scale - lowest) / (1 - lowest) * (1 - minOpacity);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(scale)
            ..translate(d * layout.slotExtent + shift))
          .value,
      opacity: clampDouble(opacity, 0, 1),
    );
  }
}

/// Items shrink as they slide away and grow as they arrive.
class ZoomInCarouselEffect extends CarouselEffect {
  /// Creates a zoom-in effect.
  const ZoomInCarouselEffect({this.minScale = 0, this.minOpacity = 1});

  /// The scale of an item one position away.
  final double minScale;

  /// The opacity of an item one position away.
  final double minOpacity;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double t = info.clampedDelta.abs();
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(_lerp(1, clampDouble(minScale, 0, 1), t))
            ..translate(info.delta * info.layout.slotExtent))
          .value,
      opacity: _lerp(1, clampDouble(minOpacity, 0, 1), t),
    );
  }
}

/// The current item slides away while the next one rises from below, like
/// Android's depth page transformer.
class DepthCarouselEffect extends CarouselEffect {
  /// Creates a depth effect.
  const DepthCarouselEffect({this.minScale = 0.75});

  /// The scale the next item starts from.
  final double minScale;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double paintOrder(CarouselItemInfo info) =>
      info.delta <= 0 ? 1 : -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d <= 0) {
      return CarouselItemTransform(
        matrix: Matrix4.translationValues(d * info.layout.slotExtent, 0, 0),
      );
    }
    if (d >= 1) {
      return CarouselItemTransform.hidden;
    }
    final double lowest = clampDouble(minScale, 0, 1);
    return CarouselItemTransform(
      matrix: (ItemMatrix()..scale(lowest + (1 - lowest) * (1 - d))).value,
      opacity: 1 - d,
    );
  }
}

/// Items slide while their content moves more slowly, for a sense of depth.
///
/// Works best with a viewport fraction of 1. For parallax inside items that
/// show their neighbours, use `CarouselParallax` instead.
class ParallaxCarouselEffect extends CarouselEffect {
  /// Creates a parallax slide.
  const ParallaxCarouselEffect({this.factor = 0.5});

  /// How much the content lags behind, from 0 (no parallax) to 1 (the
  /// content stays still while its frame slides).
  final double factor;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double slot = info.layout.slotExtent;
    final double amount = clampDouble(factor, 0, 1);
    return CarouselItemTransform(
      matrix: Matrix4.translationValues(info.delta * slot, 0, 0),
      contentMatrix:
          Matrix4.translationValues(-info.clampedDelta * slot * amount, 0, 0),
      clipContent: true,
    );
  }
}

/// The next item slides in over the current one, which sinks back a little.
class StackCarouselEffect extends CarouselEffect {
  /// Creates a stack effect.
  const StackCarouselEffect({this.minScale = 0.9, this.shade = 0.4});

  /// The scale the covered item shrinks to.
  final double minScale;

  /// How dark the covered item gets, from 0 to 1.
  final double shade;

  @override
  bool get shadesItems => shade > 0;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double paintOrder(CarouselItemInfo info) => info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d >= 0) {
      return CarouselItemTransform(
        matrix: Matrix4.translationValues(d * info.layout.slotExtent, 0, 0),
      );
    }
    if (d <= -1) {
      return CarouselItemTransform.hidden;
    }
    final double lowest = clampDouble(minScale, 0, 1);
    return CarouselItemTransform(
      matrix: (ItemMatrix()..scale(1 + d * (1 - lowest))).value,
      shade: -d * clampDouble(shade, 0, 1),
    );
  }
}

/// Items fold like an accordion: the outgoing item squeezes towards its
/// outer edge while the incoming one unfolds from the other side.
class AccordionCarouselEffect extends CarouselEffect {
  /// Creates an accordion effect.
  const AccordionCarouselEffect();

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
    final double edge = info.layout.itemMainExtent / 2;
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(1 - d.abs(), y: 1, pivot: Offset(d < 0 ? -edge : edge, 0)))
          .value,
    );
  }
}

/// Neighbours swing around a point below (or above) the carousel, like
/// cards fanned in a hand.
class RotateCarouselEffect extends CarouselEffect {
  /// Creates a rotate effect.
  const RotateCarouselEffect({this.angle = 0.33, this.fromTop = false});

  /// The rotation, in radians, of an item one position away.
  final double angle;

  /// Whether the items hang from the top edge instead of standing on the
  /// bottom edge.
  final bool fromTop;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double edge = info.layout.itemCrossExtent / 2;
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..rotateZ(
              fromTop ? -d * angle : d * angle,
              pivot: Offset(0, fromTop ? -edge : edge),
            )
            ..translate(d * info.layout.slotExtent))
          .value,
    );
  }
}
