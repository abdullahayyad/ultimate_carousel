import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../item.dart';
import 'effect.dart';

/// The Material 3 carousel layouts: items of different sizes sit side by
/// side from the leading edge, and grow or shrink into the next size as the
/// carousel moves. Items are masked, not squeezed: their content keeps its
/// size and the rounded mask around it changes.
///
/// The [weights] pick the layout, the same way as Flutter's
/// `CarouselView.weighted`:
///
/// * `[3, 2, 1]` (the default): multi-browse, a large item followed by a
///   medium and a small one.
/// * `[7, 1]`: hero, one large item and a peek of the next.
/// * `[1, 7, 1]`: centered hero, with peeks on both sides.
/// * `[1]`: full screen.
///
/// The current item is the first one with the largest weight. This effect
/// places items itself, so the carousel's `alignment` does not apply.
class MaterialCarouselEffect extends CarouselEffect {
  /// Creates a Material 3 carousel layout.
  const MaterialCarouselEffect({
    this.weights = const <int>[3, 2, 1],
    this.shrinkExtent = 0,
    this.gap = 8,
    this.cornerRadius = 28,
  });

  /// The relative sizes of the visible items, from the leading edge.
  final List<int> weights;

  /// The smallest size an item shrinks to while it enters or leaves, in
  /// logical pixels. It keeps a sliver of the item from looking like a thin
  /// line.
  final double shrinkExtent;

  /// The gap between items, in logical pixels.
  final double gap;

  /// The corner radius of the item masks.
  final double cornerRadius;

  List<int> get _weights {
    final List<int> positive = <int>[
      for (final int weight in weights)
        if (weight > 0) weight,
    ];
    return positive.isEmpty ? const <int>[1] : positive;
  }

  int get _total => _weights.fold(0, (int sum, int weight) => sum + weight);

  int get _largest => _weights.reduce(math.max);

  int get _leadingSlot => _weights.indexOf(_largest);

  double _unit(CarouselLayout layout) => layout.viewportMainExtent / _total;

  @override
  double get defaultViewportFraction => _largest / _total;

  @override
  int? itemsPerSide(CarouselLayout layout) => _weights.length + 1;

  @override
  double dragExtent(CarouselLayout layout) =>
      math.max(_weights.first * _unit(layout), 1.0);

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final List<int> w = _weights;
    final int count = w.length;
    final CarouselLayout layout = info.layout;
    final double unit = _unit(layout);
    final double t = info.page - info.page.floorToDouble();
    final int slot = (info.delta + t).round() + _leadingSlot;
    if (slot < 0 || slot > count) {
      return CarouselItemTransform.hidden;
    }
    final double smallest = w.reduce(math.min) * unit;
    final double shrink = clampDouble(shrinkExtent, 0, smallest);
    final double lead = w[0] * unit * (1 - t);

    double extentOf(int index) {
      if (index == 0) {
        return math.max(lead, shrink);
      }
      if (index < count) {
        return unit * (w[index] + (w[index - 1] - w[index]) * t);
      }
      return math.max(unit * w[count - 1] * t, shrink);
    }

    final double extent = extentOf(slot);
    if (extent <= 0.5) {
      return CarouselItemTransform.hidden;
    }
    double left;
    if (slot == 0) {
      left = lead >= shrink ? 0 : lead - shrink;
    } else {
      left = lead;
      for (int index = 1; index < slot; index++) {
        left += extentOf(index);
      }
    }
    final double base = layout.viewportMainExtent / 2 + layout.alignmentOffset;
    final double visible = math.max(0.0, extent - gap);
    final double radius = math.min(cornerRadius, visible / 2);
    return CarouselItemTransform(
      matrix: Matrix4.translationValues(left + extent / 2 - base, 0, 0),
      clipPath: Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: visible,
              height: layout.itemCrossExtent,
            ),
            Radius.circular(radius),
          ),
        ),
    );
  }
}
