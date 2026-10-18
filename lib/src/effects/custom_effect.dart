import '../item.dart';
import 'effect.dart';

/// Builds the transform of one item. See `CarouselEffect.custom`.
typedef CarouselTransformBuilder = CarouselItemTransform Function(
  CarouselItemInfo info,
);

/// Returns the paint order of one item: larger values are drawn on top.
typedef CarouselPaintOrderBuilder = double Function(CarouselItemInfo info);

/// An effect made from functions. Create it with `CarouselEffect.custom`.
class CustomCarouselEffect extends CarouselEffect {
  /// Creates an effect from a [transform] function.
  const CustomCarouselEffect({
    required CarouselTransformBuilder transform,
    CarouselPaintOrderBuilder? paintOrder,
    this.viewportFraction = 1,
    int? itemsPerSide,
    this.shadesItems = false,
  })  : _transform = transform,
        _paintOrder = paintOrder,
        _itemsPerSide = itemsPerSide;

  final CarouselTransformBuilder _transform;
  final CarouselPaintOrderBuilder? _paintOrder;
  final int? _itemsPerSide;

  /// The default fraction of the carousel one item takes.
  final double viewportFraction;

  @override
  final bool shadesItems;

  @override
  double get defaultViewportFraction => viewportFraction;

  @override
  int? itemsPerSide(CarouselLayout layout) => _itemsPerSide;

  @override
  double paintOrder(CarouselItemInfo info) {
    final CarouselPaintOrderBuilder? order = _paintOrder;
    return order == null ? super.paintOrder(info) : order(info);
  }

  @override
  CarouselItemTransform transform(CarouselItemInfo info) => _transform(info);
}
