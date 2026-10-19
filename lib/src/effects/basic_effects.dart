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
  const FadeCarouselEffect({this.crossFade = false, this.zoom = 1});

  /// Whether the outgoing item fades out while the incoming one fades in.
  final bool crossFade;

  /// The scale the incoming item starts from. Values above 1 make it settle
  /// into place while it fades in, like a slow camera zoom.
  final double zoom;

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
    return CarouselItemTransform(
      matrix:
          zoom == 1 ? null : (ItemMatrix()..scale(1 + (zoom - 1) * d)).value,
      opacity: 1 - d,
    );
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
  double paintOrder(CarouselItemInfo info) => info.delta <= 0 ? 1 : -info.delta;

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

/// Neighbours shrink, darken and blur, so the current item is in focus.
class FocusCarouselEffect extends CarouselEffect {
  /// Creates a focus effect.
  const FocusCarouselEffect({
    this.blur = 4,
    this.sideScale = 0.88,
    this.shade = 0.25,
    this.viewportFraction = 0.7,
  });

  /// The blur radius of a neighbour, in logical pixels.
  final double blur;

  /// The scale of a neighbour.
  final double sideScale;

  /// How dark a neighbour is, from 0 to 1.
  final double shade;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get blursItems => blur > 0;

  @override
  bool get shadesItems => shade > 0;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double t = info.clampedDelta.abs();
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(_lerp(1, sideScale, t))
            ..translate(info.delta * info.layout.slotExtent))
          .value,
      blur: math.max(0.0, blur) * t,
      shade: clampDouble(shade, 0, 1) * t,
    );
  }
}

/// Neighbours tuck in behind the current item, smaller and darker.
class OverlapCarouselEffect extends CarouselEffect {
  /// Creates an overlap effect.
  const OverlapCarouselEffect({
    this.overlap = 0.5,
    this.sideScale = 0.82,
    this.shade = 0.3,
    this.viewportFraction = 0.6,
  });

  /// How much of a neighbour hides behind the current item, from 0 (side by
  /// side) to 0.9.
  final double overlap;

  /// The scale of the direct neighbours.
  final double sideScale;

  /// How dark the direct neighbours are, from 0 to 1.
  final double shade;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get shadesItems => shade > 0;

  double _step(CarouselLayout layout) =>
      math.max(1.0, layout.slotExtent * (1 - clampDouble(overlap, 0, 0.9)));

  @override
  double dragExtent(CarouselLayout layout) => _step(layout);

  @override
  int? itemsPerSide(CarouselLayout layout) {
    final double reach =
        layout.viewportMainExtent / 2 + layout.itemMainExtent / 2;
    return math.min(16, (reach / (_step(layout) * 0.6)).ceil() + 1);
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double c = info.clampedDelta;
    final double rest = d - c;
    final double step = _step(info.layout);
    final double scale =
        _lerp(1, sideScale, c.abs()) * (1 - 0.06 * math.min(rest.abs(), 4.0));
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(scale)
            ..translate(c * step + rest * step * 0.6))
          .value,
      shade: clampDouble(c.abs() * shade + rest.abs() * 0.1, 0, 1),
    );
  }
}

/// The current item shrinks into the background while the next one slides
/// in over it at full size.
class ForegroundToBackgroundCarouselEffect extends CarouselEffect {
  /// Creates a foreground-to-background effect.
  const ForegroundToBackgroundCarouselEffect({
    this.drift = 0.25,
    this.endScale = 0,
  });

  /// How far the shrinking item drifts with the motion, as a fraction of a
  /// full slide. 1 keeps it sliding at full speed.
  final double drift;

  /// The size the shrinking item reaches as it leaves, from 0 to 1.
  final double endScale;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double paintOrder(CarouselItemInfo info) => info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double slot = info.layout.slotExtent;
    if (d > 0) {
      return CarouselItemTransform(
        matrix: Matrix4.translationValues(d * slot, 0, 0),
      );
    }
    if (d <= -1) {
      return CarouselItemTransform.hidden;
    }
    final double lowest = clampDouble(endScale, 0, 1);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(1 + d * (1 - lowest))
            ..translate(d * slot * drift))
          .value,
    );
  }
}

/// The next item grows out of the background while the current one slides
/// away over it.
class BackgroundToForegroundCarouselEffect extends CarouselEffect {
  /// Creates a background-to-foreground effect.
  const BackgroundToForegroundCarouselEffect({
    this.drift = 0.25,
    this.startScale = 0,
  });

  /// How far the growing item drifts with the motion, as a fraction of a
  /// full slide. 1 keeps it sliding at full speed.
  final double drift;

  /// The size the growing item starts from, from 0 to 1.
  final double startScale;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double paintOrder(CarouselItemInfo info) => info.delta <= 0 ? 1 : -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    final double slot = info.layout.slotExtent;
    if (d <= 0) {
      return CarouselItemTransform(
        matrix: Matrix4.translationValues(d * slot, 0, 0),
      );
    }
    if (d >= 1) {
      return CarouselItemTransform.hidden;
    }
    final double lowest = clampDouble(startScale, 0, 1);
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(1 - d * (1 - lowest))
            ..translate(d * slot * drift))
          .value,
    );
  }
}

/// The current item slides away on top and uncovers the next one, which
/// waits underneath, moving slowly and brightening as it comes forward.
class UncoverCarouselEffect extends CarouselEffect {
  /// Creates an uncover effect.
  const UncoverCarouselEffect({this.parallax = 0.3, this.shade = 0.3});

  /// How fast the waiting item moves compared with the one leaving, from 0
  /// (it stays still) to 1 (an ordinary slide).
  final double parallax;

  /// How dark the waiting item is before it is uncovered, from 0 to 1.
  final double shade;

  @override
  bool get shadesItems => shade > 0;

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double paintOrder(CarouselItemInfo info) => -info.delta;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d <= -1 || d >= 1) {
      return CarouselItemTransform.hidden;
    }
    final double slot = info.layout.slotExtent;
    if (d <= 0) {
      return CarouselItemTransform(
        matrix: Matrix4.translationValues(d * slot, 0, 0),
      );
    }
    return CarouselItemTransform(
      matrix: Matrix4.translationValues(
        d * slot * clampDouble(parallax, 0, 1),
        0,
        0,
      ),
      shade: d * clampDouble(shade, 0, 1),
    );
  }
}

/// Items lean as they slide, like cards dealt quickly across a table, and
/// straighten up in the middle.
class SkewCarouselEffect extends CarouselEffect {
  /// Creates a skew effect.
  const SkewCarouselEffect({
    this.angle = 0.25,
    this.sideScale = 0.9,
    this.viewportFraction = 0.75,
  });

  /// How far the neighbours lean, in radians.
  final double angle;

  /// The scale of the neighbours.
  final double sideScale;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double c = info.clampedDelta;
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            // Items lean away from the middle, tops first.
            ..skew(-c * angle)
            ..scale(_lerp(1, sideScale, c.abs()))
            ..translate(info.delta * info.layout.slotExtent))
          .value,
    );
  }
}

/// Neighbours shrink and turn grey while their content drifts inside them,
/// so the current item stands out in full color, like the Expo slider of
/// the Swiper web slider.
class ExpoCarouselEffect extends CarouselEffect {
  /// Creates an expo effect.
  const ExpoCarouselEffect({
    this.sideScale = 0.85,
    this.grayscale = 1,
    this.parallax = 0.2,
    this.viewportFraction = 0.7,
  });

  /// The scale of the neighbours.
  final double sideScale;

  /// How grey the neighbours get, from 0 (full color) to 1 (grey).
  final double grayscale;

  /// How far the content drifts inside the neighbours, as a fraction of an
  /// item's width. The content zooms in just enough to keep filling the
  /// item. Use 0 for content with its own rounded corners.
  final double parallax;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get grayscalesItems => grayscale > 0;

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double c = info.clampedDelta;
    final double drift = clampDouble(parallax, 0, 1);
    final double width = info.layout.itemMainExtent;
    return CarouselItemTransform(
      matrix: (ItemMatrix()
            ..scale(_lerp(1, sideScale, c.abs()))
            ..translate(info.delta * info.layout.slotExtent))
          .value,
      contentMatrix: drift == 0
          ? null
          : (ItemMatrix()
                ..scale(1 + drift * c.abs())
                ..translate(-c * width * drift / 2))
              .value,
      clipContent: drift > 0,
      grayscale: clampDouble(grayscale, 0, 1) * c.abs(),
    );
  }
}
