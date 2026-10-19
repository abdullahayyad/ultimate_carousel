import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../item.dart';
import 'effect.dart';
import 'item_matrix.dart';

/// Where an item goes as it moves one place away from the middle, for
/// [CreativeCarouselEffect].
///
/// The current item has no pose at all; the pose grows as an item moves away
/// and is reached in full one place away. Values are in carousel space: x
/// runs along the scroll direction and y across it.
@immutable
class CarouselPose {
  /// Creates a pose. The defaults leave the item where it is.
  const CarouselPose({
    this.offset = Offset.zero,
    this.depth = 0,
    this.rotateX = 0,
    this.rotateY = 0,
    this.rotateZ = 0,
    this.scale = 1,
    this.opacity = 1,
    this.shade = 0,
    this.origin = Alignment.center,
  });

  /// How far the item moves, as fractions of its own size: `dx` along the
  /// scroll direction (1 is one item towards the next item) and `dy` across
  /// it.
  final Offset offset;

  /// How far the item moves away from the viewer, in logical pixels.
  /// Negative values bring it closer.
  final double depth;

  /// The turn around the horizontal axis, in radians. Positive values tip
  /// the bottom edge away from the viewer.
  final double rotateX;

  /// The turn around the vertical axis, in radians. Positive values swing
  /// the leading edge (the one towards the next item) towards the viewer.
  final double rotateY;

  /// The turn in the screen's plane, in radians. Positive values turn it
  /// clockwise.
  final double rotateZ;

  /// The item's size.
  final double scale;

  /// The item's opacity, from 0 to 1.
  final double opacity;

  /// How dark the item gets, from 0 to 1.
  final double shade;

  /// The point the item turns and scales around.
  final Alignment origin;

  @override
  bool operator ==(Object other) {
    return other is CarouselPose &&
        other.offset == offset &&
        other.depth == depth &&
        other.rotateX == rotateX &&
        other.rotateY == rotateY &&
        other.rotateZ == rotateZ &&
        other.scale == scale &&
        other.opacity == opacity &&
        other.shade == shade &&
        other.origin == origin;
  }

  @override
  int get hashCode => Object.hash(
        offset,
        depth,
        rotateX,
        rotateY,
        rotateZ,
        scale,
        opacity,
        shade,
        origin,
      );
}

/// The shade the presets give items as they leave, like Swiper's slide
/// shadows.
const double _presetShade = 0.25;

/// Describe where the previous and the next items go, and the carousel moves
/// every item between those poses, like the creative effect of the Swiper
/// web slider.
///
/// ```dart
/// CarouselEffect.creative(
///   previous: CarouselPose(offset: Offset(-0.2, 0), shade: 0.3),
///   next: CarouselPose(offset: Offset(1, 0)),
/// )
/// ```
///
/// The named constructors are ready-made looks, the same as Swiper's
/// creative effect demos: [CreativeCarouselEffect.sinkBack],
/// [CreativeCarouselEffect.driftApart], [CreativeCarouselEffect.push],
/// [CreativeCarouselEffect.tumble], [CreativeCarouselEffect.spin] and
/// [CreativeCarouselEffect.door].
class CreativeCarouselEffect extends CarouselEffect {
  /// Creates a creative effect from two poses. The defaults make a plain
  /// slide.
  const CreativeCarouselEffect({
    this.previous = const CarouselPose(offset: Offset(-1, 0)),
    this.next = const CarouselPose(offset: Offset(1, 0)),
    this.limit = 1,
    this.perspective = 1 / 1200,
    this.hideBackFace = true,
    this.viewportFraction = 1,
  });

  /// The current item sinks back into the distance, darkening, while the
  /// next one slides in over it.
  const CreativeCarouselEffect.sinkBack({this.viewportFraction = 1})
      : previous = const CarouselPose(depth: 400, shade: _presetShade),
        next = const CarouselPose(offset: Offset(1, 0)),
        limit = 1,
        perspective = 1 / 1200,
        hideBackFace = true;

  /// Items drift apart and away into the distance while they change.
  const CreativeCarouselEffect.driftApart({this.viewportFraction = 1})
      : previous = const CarouselPose(
          offset: Offset(-1.2, 0),
          depth: 500,
          shade: _presetShade,
        ),
        next = const CarouselPose(
          offset: Offset(1.2, 0),
          depth: 500,
          shade: _presetShade,
        ),
        limit = 1,
        perspective = 1 / 1200,
        hideBackFace = true;

  /// The next item slides in over the current one, which moves a little way
  /// and darkens, like pages in a mobile app.
  const CreativeCarouselEffect.push({this.viewportFraction = 1})
      : previous = const CarouselPose(
          offset: Offset(-0.2, 0),
          depth: 1,
          shade: _presetShade,
        ),
        next = const CarouselPose(offset: Offset(1, 0)),
        limit = 1,
        perspective = 1 / 1200,
        hideBackFace = true;

  /// Items tumble head over heels into the distance and back.
  const CreativeCarouselEffect.tumble({this.viewportFraction = 1})
      : previous = const CarouselPose(
          depth: 800,
          rotateX: -math.pi,
          shade: _presetShade,
        ),
        next = const CarouselPose(
          depth: 800,
          rotateX: math.pi,
          shade: _presetShade,
        ),
        limit = 1,
        perspective = 1 / 1200,
        hideBackFace = true;

  /// Items spin a quarter turn as they fly off to the side and away.
  const CreativeCarouselEffect.spin({this.viewportFraction = 1})
      : previous = const CarouselPose(
          offset: Offset(-1.25, 0),
          depth: 800,
          rotateZ: -math.pi / 2,
          shade: _presetShade,
        ),
        next = const CarouselPose(
          offset: Offset(1.25, 0),
          depth: 800,
          rotateZ: math.pi / 2,
          shade: _presetShade,
        ),
        limit = 1,
        perspective = 1 / 1200,
        hideBackFace = true;

  /// Items swing open and shut on their side edges, like doors.
  const CreativeCarouselEffect.door({this.viewportFraction = 1})
      : previous = const CarouselPose(
          origin: Alignment.centerLeft,
          offset: Offset(-0.05, 0),
          depth: 200,
          rotateY: -100 * math.pi / 180,
          shade: _presetShade,
        ),
        next = const CarouselPose(
          origin: Alignment.centerRight,
          offset: Offset(0.05, 0),
          depth: 200,
          rotateY: 100 * math.pi / 180,
        ),
        limit = 1,
        perspective = 1 / 1200,
        hideBackFace = true;

  /// The pose of the items before the current one.
  final CarouselPose previous;

  /// The pose of the items after the current one.
  final CarouselPose next;

  /// How many places away the poses keep growing. Items further away share
  /// the pose of the items at this distance and wait behind them.
  final double limit;

  /// The strength of the 3D perspective. The default matches the web's
  /// usual `perspective: 1200px`.
  final double perspective;

  /// Whether items that turn their back to the viewer are hidden, like the
  /// web's `backface-visibility: hidden`.
  final bool hideBackFace;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  double get _limit => math.max(limit, 0.0);

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  bool get shadesItems => previous.shade > 0 || next.shade > 0;

  @override
  int? itemsPerSide(CarouselLayout layout) =>
      math.min(16, math.max(1, _limit.ceil()) + 1);

  CarouselPose? _poseOf(double delta) {
    if (delta < 0) {
      return previous;
    }
    if (delta > 0) {
      return next;
    }
    return null;
  }

  /// How far an item is from the middle, after [limit].
  double _amount(double delta) => math.min(delta.abs(), _limit);

  @override
  double paintOrder(CarouselItemInfo info) {
    // Items further away from the viewer are drawn first, as the web does
    // with 3D sorting; items at the same depth stack by their distance.
    final double depth = (_poseOf(info.delta)?.depth ?? 0) * _amount(info.delta);
    return -depth - info.distance / 1000;
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final CarouselPose? pose = _poseOf(info.delta);
    if (pose == null) {
      return CarouselItemTransform.identity;
    }
    final double amount = _amount(info.delta);
    final double rotateX = pose.rotateX * amount;
    final double rotateY = pose.rotateY * amount;
    if (hideBackFace && math.cos(rotateX) * math.cos(rotateY) <= 1e-3) {
      return CarouselItemTransform.hidden;
    }
    final Size size = info.layout.itemSize;
    final Offset pivot = Offset(
      pose.origin.x * size.width / 2,
      pose.origin.y * size.height / 2,
    );
    final ItemMatrix matrix = ItemMatrix()
      ..scale(math.max(0.0, 1 - (1 - pose.scale) * amount), pivot: pivot)
      ..rotateZ(pose.rotateZ * amount, pivot: pivot)
      ..rotateY(rotateY, pivot: pivot)
      ..rotateX(rotateX, pivot: pivot)
      ..translate(
        pose.offset.dx * size.width * amount,
        pose.offset.dy * size.height * amount,
        pose.depth * amount,
      )
      ..perspective(perspective);
    return CarouselItemTransform(
      matrix: matrix.value,
      opacity: clampDouble(1 - (1 - pose.opacity) * amount, 0, 1),
      shade: clampDouble(pose.shade * math.min(amount, 1.0), 0, 1),
    );
  }
}
