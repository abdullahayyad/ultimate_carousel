import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../item.dart';
import 'effect.dart';

/// The shared behaviour of effects that uncover the next item in place.
///
/// Items do not move. The next item lies on top of the current one and is
/// clipped to a shape that grows as the carousel moves forwards.
abstract class RevealCarouselEffect extends CarouselEffect {
  /// Lets subclasses be const.
  const RevealCarouselEffect();

  @override
  int? itemsPerSide(CarouselLayout layout) => 1;

  @override
  double dragExtent(CarouselLayout layout) =>
      math.max(layout.itemMainExtent, 1.0);

  @override
  double paintOrder(CarouselItemInfo info) => info.delta;

  /// The part of the incoming item that is visible, for a reveal [progress]
  /// from 0 (nothing) to 1 (everything).
  ///
  /// The path is in carousel space around the item's center; [size] is the
  /// item's size in carousel space.
  Path revealPath(CarouselItemInfo info, Size size, double progress);

  @override
  CarouselItemTransform transform(CarouselItemInfo info) {
    final double d = info.delta;
    if (d.abs() >= 1) {
      return CarouselItemTransform.hidden;
    }
    if (d <= 0) {
      return CarouselItemTransform.identity;
    }
    return CarouselItemTransform(
      clipPath: revealPath(info, info.layout.itemSize, 1 - d),
    );
  }
}

/// The next item appears inside a growing circle.
class CircularRevealCarouselEffect extends RevealCarouselEffect {
  /// Creates a circular reveal.
  const CircularRevealCarouselEffect({
    this.origin = const Offset(0.5, 0.5),
    this.followPointer = false,
  });

  /// Where the circle grows from, as fractions of the item (0.5, 0.5 is the
  /// center), in carousel space: x runs along the scroll direction.
  final Offset origin;

  /// Whether the circle grows from where the user touched instead of
  /// [origin].
  final bool followPointer;

  @override
  Path revealPath(CarouselItemInfo info, Size size, double progress) {
    final Offset start = followPointer ? info.focalPoint : origin;
    final Offset center = Offset(
      (start.dx - 0.5) * size.width,
      (start.dy - 0.5) * size.height,
    );
    final double reach = <double>[
      (center - Offset(-size.width / 2, -size.height / 2)).distance,
      (center - Offset(size.width / 2, -size.height / 2)).distance,
      (center - Offset(-size.width / 2, size.height / 2)).distance,
      (center - Offset(size.width / 2, size.height / 2)).distance,
    ].reduce(math.max);
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: reach * progress));
  }
}

/// The next item is wiped in from the trailing edge.
class WipeCarouselEffect extends RevealCarouselEffect {
  /// Creates a wipe.
  const WipeCarouselEffect();

  @override
  Path revealPath(CarouselItemInfo info, Size size, double progress) {
    final double right = size.width / 2;
    return Path()
      ..addRect(
        Rect.fromLTRB(
          right - size.width * progress,
          -size.height / 2,
          right,
          size.height / 2,
        ),
      );
  }
}

/// The next item appears through a gap that opens from the middle, like
/// curtains parting.
class CurtainCarouselEffect extends RevealCarouselEffect {
  /// Creates a curtain reveal.
  const CurtainCarouselEffect();

  @override
  Path revealPath(CarouselItemInfo info, Size size, double progress) {
    final double half = size.width * progress / 2;
    return Path()
      ..addRect(
        Rect.fromLTRB(-half, -size.height / 2, half, size.height / 2),
      );
  }
}

/// The next item appears through opening slats, like venetian blinds.
class BlindsCarouselEffect extends RevealCarouselEffect {
  /// Creates a blinds effect.
  const BlindsCarouselEffect({this.count = 6});

  /// How many slats there are.
  final int count;

  @override
  Path revealPath(CarouselItemInfo info, Size size, double progress) {
    final int slats = math.max(1, count);
    final double slat = size.width / slats;
    final Path path = Path();
    for (int i = 0; i < slats; i++) {
      final double right = -size.width / 2 + (i + 1) * slat;
      path.addRect(
        Rect.fromLTRB(
          right - slat * progress,
          -size.height / 2,
          right,
          size.height / 2,
        ),
      );
    }
    return path;
  }
}

/// The next item pours in from the trailing edge in a liquid wave that
/// follows the finger.
class LiquidCarouselEffect extends RevealCarouselEffect {
  /// Creates a liquid swipe.
  const LiquidCarouselEffect(
      {this.waveHeight = 0.32, this.followPointer = true});

  /// The height of the wave at the start of the swipe, as a fraction of the
  /// item's height.
  final double waveHeight;

  /// Whether the wave follows the finger up and down.
  final bool followPointer;

  @override
  Path revealPath(CarouselItemInfo info, Size size, double progress) {
    final double width = size.width;
    final double height = size.height;
    final double top = -height / 2;
    final double bottom = height / 2;
    final double right = width / 2;
    final double p = clampDouble(progress, 0, 1);
    final double centerY = followPointer
        ? (clampDouble(info.focalPoint.dy, 0.15, 0.85) - 0.5) * height
        : 0;
    // The flat band that has already filled in grows slowly at first and
    // fast at the end, while the bulge in front of it grows and widens.
    final double band = width * p * p;
    final double bulge =
        width * math.sin(p * math.pi / 2) * 0.55 + 12 * (1 - p);
    final double halfHeight =
        height * (waveHeight + (1.2 - waveHeight) * p * p) / 2 + 24 * (1 - p);
    final double base = right - band;
    final double tip = base - bulge;
    final double upper = centerY - halfHeight;
    final double lower = centerY + halfHeight;
    final double reach = halfHeight * 0.55;

    final Path path = Path()
      ..moveTo(right, top)
      ..lineTo(base, top)
      ..lineTo(base, math.max(top, upper));
    path
      ..cubicTo(base, upper + reach, tip, centerY - reach, tip, centerY)
      ..cubicTo(tip, centerY + reach, base, lower - reach, base, lower)
      ..lineTo(base, bottom)
      ..lineTo(right, bottom)
      ..close();
    return path;
  }
}
