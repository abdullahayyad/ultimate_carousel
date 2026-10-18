import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../item.dart';
import 'basic_effects.dart';
import 'card_effects.dart';
import 'custom_effect.dart';
import 'reveal_effects.dart';
import 'three_d_effects.dart';

/// A transition between the items of an `UltimateCarousel`.
///
/// Pick one of the built-in effects with the named constructors, for example
/// `const CarouselEffect.cube()`, or write your own with
/// [CarouselEffect.custom] or by subclassing.
///
/// An effect decides how every item is drawn for its position relative to
/// the current page. The carousel asks it on every frame while it moves, so
/// effects must be cheap and must not keep state between calls.
///
/// Effects are written for a horizontal, left-to-right carousel (see
/// `CarouselLayout`); the carousel adapts them to vertical, reversed and
/// right-to-left carousels on its own.
abstract class CarouselEffect {
  /// Lets subclasses be const.
  const CarouselEffect();

  // ---------------------------------------------------------------------------
  // Slides and fades

  /// Items slide side by side. This is the default.
  const factory CarouselEffect.slide() = SlideCarouselEffect;

  /// Items fade into each other in place.
  const factory CarouselEffect.fade({bool crossFade, double zoom}) =
      FadeCarouselEffect;

  /// The current item is full size and its neighbours are smaller.
  const factory CarouselEffect.enlarge({
    double factor,
    CarouselEnlargeStrategy strategy,
    double minOpacity,
    double viewportFraction,
  }) = EnlargeCarouselEffect;

  /// Neighbours shrink a little and fade while sliding.
  const factory CarouselEffect.zoomOut({double minScale, double minOpacity}) =
      ZoomOutCarouselEffect;

  /// Items shrink as they slide away and grow as they arrive.
  const factory CarouselEffect.zoomIn({double minScale, double minOpacity}) =
      ZoomInCarouselEffect;

  /// The current item slides away while the next one rises from below.
  const factory CarouselEffect.depth({double minScale}) = DepthCarouselEffect;

  /// Items slide while their content moves more slowly.
  const factory CarouselEffect.parallax({double factor}) =
      ParallaxCarouselEffect;

  /// The next item slides in over the current one, which sinks back.
  const factory CarouselEffect.stack({double minScale, double shade}) =
      StackCarouselEffect;

  /// Items fold and unfold like an accordion.
  const factory CarouselEffect.accordion() = AccordionCarouselEffect;

  /// Neighbours swing around a point below (or above) the carousel.
  const factory CarouselEffect.rotate({double angle, bool fromTop}) =
      RotateCarouselEffect;

  /// The current item shrinks into the background while the next one slides
  /// in over it.
  const factory CarouselEffect.foregroundToBackground({double drift}) =
      ForegroundToBackgroundCarouselEffect;

  /// The next item grows out of the background while the current one slides
  /// away over it.
  const factory CarouselEffect.backgroundToForeground({double drift}) =
      BackgroundToForegroundCarouselEffect;

  /// Neighbours shrink, darken and blur, so the current item is in focus.
  const factory CarouselEffect.focus({
    double blur,
    double sideScale,
    double shade,
    double viewportFraction,
  }) = FocusCarouselEffect;

  /// Neighbours tuck in behind the current item.
  const factory CarouselEffect.overlap({
    double overlap,
    double sideScale,
    double shade,
    double viewportFraction,
  }) = OverlapCarouselEffect;

  // ---------------------------------------------------------------------------
  // 3D

  /// Items are the faces of a turning cube.
  const factory CarouselEffect.cube({
    bool inside,
    double angle,
    double perspective,
    double shade,
  }) = CubeCarouselEffect;

  /// Each item flips over like a card.
  const factory CarouselEffect.flip({bool vertical, double perspective}) =
      FlipCarouselEffect;

  /// The classic cover flow.
  const factory CarouselEffect.coverflow({
    double angle,
    double sideScale,
    double sideOffset,
    double stackSpacing,
    double depth,
    double shade,
    double perspective,
    double viewportFraction,
  }) = CoverflowCarouselEffect;

  /// Neighbours turn away as if on the screen of a tilted tablet.
  const factory CarouselEffect.tablet({
    double angle,
    double perspective,
    double shade,
  }) = TabletCarouselEffect;

  /// Items stand around a turning ring.
  const factory CarouselEffect.ring({
    int? itemsOnRing,
    double? radius,
    bool faceViewer,
    bool showBackItems,
    double tilt,
    double perspective,
    double shade,
    double viewportFraction,
  }) = RingCarouselEffect;

  /// Items ride on the outside of a turning drum.
  const factory CarouselEffect.wheel({
    double diameterRatio,
    double perspective,
    double shade,
    double viewportFraction,
  }) = WheelCarouselEffect;

  /// Items line the inside of a curved wall around the viewer.
  const factory CarouselEffect.cylinder({
    double diameterRatio,
    double perspective,
    double shade,
    double viewportFraction,
  }) = CylinderCarouselEffect;

  /// Items spiral around a column.
  const factory CarouselEffect.helix({
    int itemsPerTurn,
    double? radius,
    double rise,
    double perspective,
    double shade,
    double viewportFraction,
  }) = HelixCarouselEffect;

  /// Items turn like the pages of a book.
  const factory CarouselEffect.pageTurn({double perspective, double shade}) =
      PageTurnCarouselEffect;

  /// Items wait in a line into the distance and fly past when they leave.
  const factory CarouselEffect.tunnel({
    double depth,
    int visibleItems,
    double rise,
  }) = TunnelCarouselEffect;

  // ---------------------------------------------------------------------------
  // Cards

  /// The upcoming items wait in a deck behind the current one.
  const factory CarouselEffect.deck({
    int visibleCards,
    double offset,
    double scaleStep,
    double leaveAngle,
    double viewportFraction,
  }) = DeckCarouselEffect;

  /// A pile of cards whose top card is thrown off to the side with a twist.
  const factory CarouselEffect.tinder({
    int visibleCards,
    double maxAngle,
    double peek,
    double scaleStep,
    double viewportFraction,
  }) = TinderCarouselEffect;

  /// Items spread out like a hand of cards.
  const factory CarouselEffect.fan({
    double angle,
    double radius,
    double sideScale,
    double viewportFraction,
  }) = FanCarouselEffect;

  /// Items sit on a curve and travel along it.
  const factory CarouselEffect.arc({
    double radius,
    bool upward,
    bool tilt,
    double sideScale,
    double viewportFraction,
  }) = ArcCarouselEffect;

  /// A messy pile of photos whose top one is tossed aside.
  const factory CarouselEffect.scatter({
    double maxAngle,
    double spread,
    int visibleCards,
    double viewportFraction,
  }) = ScatterCarouselEffect;

  // ---------------------------------------------------------------------------
  // Reveals

  /// The next item appears inside a growing circle.
  const factory CarouselEffect.circularReveal({
    Offset origin,
    bool followPointer,
  }) = CircularRevealCarouselEffect;

  /// The next item is wiped in from the trailing edge.
  const factory CarouselEffect.wipe() = WipeCarouselEffect;

  /// The next item appears through a gap that opens from the middle.
  const factory CarouselEffect.curtain() = CurtainCarouselEffect;

  /// The next item appears through opening slats.
  const factory CarouselEffect.blinds({int count}) = BlindsCarouselEffect;

  /// The next item pours in from the trailing edge in a liquid wave.
  const factory CarouselEffect.liquid({double waveHeight, bool followPointer}) =
      LiquidCarouselEffect;

  // ---------------------------------------------------------------------------
  // Your own

  /// An effect made from a function.
  ///
  /// ```dart
  /// CarouselEffect.custom(
  ///   transform: (info) => CarouselItemTransform(
  ///     matrix: Matrix4.translationValues(
  ///       info.delta * info.layout.slotExtent, 0, 0,
  ///     )..multiply(Matrix4.rotationZ(info.delta * 0.2)),
  ///     opacity: 1 - info.distance.clamp(0.0, 1.0) * 0.5,
  ///   ),
  /// )
  /// ```
  const factory CarouselEffect.custom({
    required CarouselTransformBuilder transform,
    CarouselPaintOrderBuilder? paintOrder,
    double viewportFraction,
    int? itemsPerSide,
    bool shadesItems,
  }) = CustomCarouselEffect;

  // ---------------------------------------------------------------------------
  // The effect API

  /// The fraction of the carousel's length one item takes when the carousel
  /// sets no `viewportFraction` of its own.
  double get defaultViewportFraction => 1;

  /// Whether a looping carousel shows each item at most once.
  ///
  /// Effects that place every item around a closed shape, such as a ring,
  /// set this so short lists do not show duplicates.
  bool get uniqueItems => false;

  /// Whether [transform] uses `CarouselItemTransform.shade`.
  ///
  /// Shading adds a color filter layer to every item, so effects only turn
  /// it on when they need it.
  bool get shadesItems => false;

  /// Whether [transform] uses `CarouselItemTransform.blur`.
  ///
  /// Blurring adds an image filter to every item, so effects only turn it on
  /// when they need it.
  bool get blursItems => false;

  /// How many items to build on each side of the current one.
  ///
  /// `null` lets the carousel work it out from the item size, which suits
  /// effects that place items side by side.
  int? itemsPerSide(CarouselLayout layout) => null;

  /// How far, in logical pixels along the scroll direction, a drag must go
  /// to move by one item.
  double dragExtent(CarouselLayout layout) =>
      math.max(layout.slotExtent, 1.0);

  /// The paint order of an item: items with larger values are drawn on top.
  ///
  /// By default the current item is on top and items further away are drawn
  /// below it.
  double paintOrder(CarouselItemInfo info) => -info.distance;

  /// How to draw one item.
  CarouselItemTransform transform(CarouselItemInfo info);

  /// Wraps an item in extra widgets, for looks a transform cannot express.
  ///
  /// Called every frame for every visible item. To keep the items' state,
  /// return the same widget structure every time and only change values.
  Widget decorate(BuildContext context, Widget child, CarouselItemInfo info) {
    return child;
  }
}
