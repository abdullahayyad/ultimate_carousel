import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'options.dart';

/// The size and settings of a carousel, as seen by a `CarouselEffect`.
///
/// Effects are always written for a horizontal, left-to-right carousel.
/// In that "carousel space" x runs along the scroll direction (towards the
/// next item) and y runs across it. Sizes follow the same rule: a size's
/// width is its extent along the scroll direction and its height is its
/// extent across it. The carousel mirrors and rotates every transform for
/// vertical, reversed and right-to-left carousels, so one effect works in
/// all of them.
@immutable
class CarouselLayout {
  /// Creates a layout description. The carousel creates these for you.
  const CarouselLayout({
    required this.viewportSize,
    required this.itemSize,
    required this.spacing,
    required this.itemCount,
    required this.loop,
    required this.alignment,
    required this.scrollDirection,
    required this.reversed,
  });

  /// The carousel's own size in carousel space.
  final Size viewportSize;

  /// The size of one item in carousel space.
  final Size itemSize;

  /// The gap between neighbouring items, in logical pixels.
  final double spacing;

  /// How many items the carousel has.
  final int itemCount;

  /// Whether the carousel loops forever.
  final bool loop;

  /// Where the current item sits in the viewport.
  final CarouselAlignment alignment;

  /// The real scroll direction of the carousel on screen.
  final Axis scrollDirection;

  /// Whether the next item appears on the left (horizontal) or at the top
  /// (vertical) instead of the usual side.
  final bool reversed;

  /// The viewport's extent along the scroll direction.
  double get viewportMainExtent => viewportSize.width;

  /// The viewport's extent across the scroll direction.
  double get viewportCrossExtent => viewportSize.height;

  /// One item's extent along the scroll direction.
  double get itemMainExtent => itemSize.width;

  /// One item's extent across the scroll direction.
  double get itemCrossExtent => itemSize.height;

  /// The distance between the centers of neighbouring items when they sit
  /// side by side: the item extent plus [spacing].
  double get slotExtent => itemMainExtent + spacing;

  /// How far the current item's center is from the viewport's center along
  /// the scroll direction, because of [alignment].
  double get alignmentOffset {
    switch (alignment) {
      case CarouselAlignment.start:
        return -(viewportMainExtent - itemMainExtent) / 2;
      case CarouselAlignment.center:
        return 0;
      case CarouselAlignment.end:
        return (viewportMainExtent - itemMainExtent) / 2;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is CarouselLayout &&
        other.viewportSize == viewportSize &&
        other.itemSize == itemSize &&
        other.spacing == spacing &&
        other.itemCount == itemCount &&
        other.loop == loop &&
        other.alignment == alignment &&
        other.scrollDirection == scrollDirection &&
        other.reversed == reversed;
  }

  @override
  int get hashCode => Object.hash(
        viewportSize,
        itemSize,
        spacing,
        itemCount,
        loop,
        alignment,
        scrollDirection,
        reversed,
      );
}

/// Where one item is relative to the current page, handed to effects.
@immutable
class CarouselItemInfo {
  /// Creates the description of one item. The carousel creates these for you.
  const CarouselItemInfo({
    required this.delta,
    required this.index,
    required this.virtualIndex,
    required this.page,
    required this.layout,
    this.focalPoint = const Offset(0.5, 0.5),
  });

  /// The item's position relative to the current page, in items.
  ///
  /// 0 is the current item, -1 the item before it and 1 the item after it.
  /// Values in between happen while the carousel moves: when the user has
  /// dragged a quarter of the way to the next item, the current item has a
  /// delta of -0.25 and the next item 0.75.
  final double delta;

  /// The item's index in the carousel's items.
  final int index;

  /// The item's position on the endless strip of a looping carousel.
  ///
  /// It equals [index] when the carousel does not loop.
  final int virtualIndex;

  /// The carousel's current page on the endless strip.
  final double page;

  /// The carousel's size and settings.
  final CarouselLayout layout;

  /// Where the last pointer touched the carousel, in carousel space, as
  /// fractions of the viewport (0.5, 0.5 is the center).
  ///
  /// Effects such as the liquid swipe use it to follow the finger.
  final Offset focalPoint;

  /// The distance of the item from the current page, always positive.
  double get distance => delta.abs();

  /// [delta] limited to the range -1 to 1.
  double get clampedDelta => clampDouble(delta, -1, 1);

  /// Whether this item is the one closest to the current page.
  bool get isCurrent => delta.abs() < 0.5;

  @override
  bool operator ==(Object other) {
    return other is CarouselItemInfo &&
        other.delta == delta &&
        other.index == index &&
        other.virtualIndex == virtualIndex &&
        other.page == page &&
        other.layout == layout &&
        other.focalPoint == focalPoint;
  }

  @override
  int get hashCode =>
      Object.hash(delta, index, virtualIndex, page, layout, focalPoint);
}

/// How an effect wants one item drawn.
///
/// All geometry is in carousel space (see [CarouselLayout]) with the origin
/// at the item's resting center: x points towards the next item, y points
/// across the carousel, and positive z points away from the viewer.
@immutable
class CarouselItemTransform {
  /// Creates an item transform. Every argument is optional; the defaults
  /// draw the item untouched.
  const CarouselItemTransform({
    this.matrix,
    this.opacity = 1,
    this.shade = 0,
    this.blur = 0,
    this.clipPath,
    this.contentMatrix,
    this.clipContent = false,
    this.visible = true,
    this.interactive = true,
  });

  /// Draws the item untouched.
  static const CarouselItemTransform identity = CarouselItemTransform();

  /// Hides the item. It stays mounted, so its state is kept.
  static const CarouselItemTransform hidden = CarouselItemTransform(
    visible: false,
  );

  /// Moves, scales and rotates the whole item. `null` leaves it in place.
  final Matrix4? matrix;

  /// The item's opacity, from 0 (invisible) to 1.
  final double opacity;

  /// Tints the item with the effect's `shadeColor`, from 0 (not at all) to 1
  /// (fully). The default color is black, so the item darkens.
  ///
  /// Only effects whose `shadesItems` is true can shade items.
  final double shade;

  /// Blurs the item, as a blur radius in logical pixels.
  ///
  /// Only effects whose `blursItems` is true can blur items.
  final double blur;

  /// Clips the item to this path. `null` means no clipping.
  final Path? clipPath;

  /// Moves the item's content inside the item, for example for parallax.
  final Matrix4? contentMatrix;

  /// Clips the content to the item's box, so a moved [contentMatrix] does not
  /// spill outside.
  final bool clipContent;

  /// Whether the item is drawn at all.
  final bool visible;

  /// Whether the item can receive taps and other pointer events.
  final bool interactive;
}

/// Gives the widgets inside a carousel item access to the item's position.
///
/// Use it to animate content with the carousel, for example fading a caption
/// as its slide leaves:
///
/// ```dart
/// Builder(builder: (context) {
///   final info = CarouselItemScope.of(context);
///   return Opacity(opacity: 1 - info.distance.clamp(0.0, 1.0), child: caption);
/// })
/// ```
class CarouselItemScope extends InheritedWidget {
  /// Creates the scope. The carousel inserts it above every item.
  const CarouselItemScope({
    super.key,
    required this.info,
    required super.child,
  });

  /// The item's position, updated every frame while the carousel moves.
  final CarouselItemInfo info;

  /// The position of the closest enclosing carousel item, or `null` when the
  /// context is not inside one.
  static CarouselItemInfo? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CarouselItemScope>()
        ?.info;
  }

  /// The position of the closest enclosing carousel item.
  static CarouselItemInfo of(BuildContext context) {
    final CarouselItemInfo? info = maybeOf(context);
    assert(
      info != null,
      'CarouselItemScope.of() was called outside an UltimateCarousel item.',
    );
    return info!;
  }

  @override
  bool updateShouldNotify(CarouselItemScope oldWidget) =>
      oldWidget.info != info;
}

/// Moves its child more slowly than the item around it, for a parallax look.
///
/// Put it inside an item, usually around a background image:
///
/// ```dart
/// UltimateCarousel(
///   children: [
///     for (final url in urls)
///       CarouselParallax(child: Image.network(url, fit: BoxFit.cover)),
///   ],
/// )
/// ```
class CarouselParallax extends StatelessWidget {
  /// Creates a parallax layer.
  const CarouselParallax({
    super.key,
    this.factor = 0.4,
    required this.child,
  });

  /// How much the content lags behind, from 0 (no parallax) to 1.
  ///
  /// The content is enlarged by the same fraction so its edges never show.
  final double factor;

  /// The content to move.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarouselItemInfo? info = CarouselItemScope.maybeOf(context);
    final double amount = clampDouble(factor, 0, 1);
    if (info == null || amount == 0) {
      return child;
    }
    final CarouselLayout layout = info.layout;
    final double shift =
        -info.clampedDelta * layout.itemMainExtent * amount / 2;
    final bool horizontal = layout.scrollDirection == Axis.horizontal;
    final double signed = layout.reversed ? -shift : shift;
    final Offset offset = horizontal ? Offset(signed, 0) : Offset(0, signed);
    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(offset.dx, offset.dy, 0)
          ..multiply(Matrix4.diagonal3Values(1 + amount, 1 + amount, 1)),
        child: child,
      ),
    );
  }
}
