import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../item.dart';
import 'effect.dart';

/// Wraps one item in the widgets that draw its look. See
/// `CarouselEffect.builder`.
///
/// [index] is the item's index in the carousel's items and [child] is the
/// item itself. [ratio] is where the item is among the items on show: 0 for
/// the current item, -1 for the furthest item shown before it and 1 for the
/// furthest item shown after it. It changes smoothly while the carousel
/// moves.
typedef CarouselEffectsBuilder = Widget Function(
  int index,
  double ratio,
  Widget child,
);

/// Which items a `CarouselEffect.builder` draws on top of the others.
enum CarouselDepthOrder {
  /// Items later in the list are drawn over earlier ones.
  forward,

  /// Items earlier in the list are drawn over later ones.
  reverse,

  /// The current item is on top, and items closer to it are drawn over
  /// items further away.
  selectedInFront,
}

/// An effect that hands every item to a function that wraps it in widgets,
/// so a transition can use any widget: `Transform`, `Opacity`,
/// `ImageFiltered`, `ShaderMask` or the effects of an animation package.
/// Create it with `CarouselEffect.builder`.
///
/// Every item starts at the current item's place, and the builder moves it
/// from there. The builder works in screen space: it decides where items
/// go, so a vertical or right-to-left carousel only changes which way the
/// user swipes.
///
/// It mirrors the `effectsBuilder` of the flutter_custom_carousel package,
/// so builders written for it work here unchanged.
class BuilderCarouselEffect extends CarouselEffect {
  /// Creates an effect from a [builder].
  const BuilderCarouselEffect({
    required this.builder,
    this.itemsBefore = 2,
    this.itemsAfter = 2,
    this.depthOrder = CarouselDepthOrder.selectedInFront,
    this.viewportFraction = 1,
  });

  /// Wraps each item on show in the widgets that draw its look.
  final CarouselEffectsBuilder builder;

  /// How many items show before the current one.
  final int itemsBefore;

  /// How many items show after the current one.
  final int itemsAfter;

  /// Which items are drawn on top.
  final CarouselDepthOrder depthOrder;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  double get defaultViewportFraction => viewportFraction;

  // A looping carousel with only a few items would otherwise show some of
  // them twice.
  @override
  bool get uniqueItems => true;

  int get _before => math.max(0, itemsBefore);

  int get _after => math.max(0, itemsAfter);

  @override
  int? itemsPerSide(CarouselLayout layout) => math.max(_before, _after) + 1;

  /// The ratio [builder] receives for an item: its position among the items
  /// on show, from -1 (the furthest before the current one) through 0 (the
  /// current one) to 1 (the furthest after it).
  ///
  /// Items further away than that are not drawn.
  double ratioOf(CarouselItemInfo info) {
    final double delta = info.delta;
    return delta < 0 ? delta / (_before + 0.5) : delta / (_after + 0.5);
  }

  @override
  double paintOrder(CarouselItemInfo info) {
    switch (depthOrder) {
      case CarouselDepthOrder.forward:
        return info.delta;
      case CarouselDepthOrder.reverse:
        return -info.delta;
      case CarouselDepthOrder.selectedInFront:
        return -info.distance;
    }
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    return ratioOf(info).abs() <= 1 + 1e-9
        ? CarouselItemTransform.identity
        : CarouselItemTransform.hidden;
  }

  @override
  Widget decorate(BuildContext context, Widget child, CarouselItemInfo info) {
    // Hidden items still go through the builder, so every item keeps the
    // same widgets (and its state) as it comes and goes. Their ratio is
    // kept in range, so builders never see values they were not written for.
    return builder(info.index, clampDouble(ratioOf(info), -1, 1), child);
  }
}
