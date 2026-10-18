import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

/// Why the current page of an `UltimateCarousel` changed.
enum CarouselPageChangeReason {
  /// The user moved the carousel: a drag or fling, the keyboard, the mouse
  /// wheel, an accessibility action or a tap on an item.
  user,

  /// Autoplay moved the carousel.
  autoPlay,

  /// A method of `UltimateCarouselController` moved the carousel.
  controller,
}

/// What autoplay does when a carousel that does not loop reaches its end.
enum CarouselAutoPlayEnd {
  /// Animate back to the first item and keep playing.
  rewind,

  /// Turn around and play back towards the first item, like a ping-pong ball.
  pingPong,

  /// Stop autoplay on the last item.
  stop,
}

/// Where the current item sits inside the carousel's viewport.
enum CarouselAlignment {
  /// The current item touches the leading edge (left in left-to-right
  /// layouts, top in vertical carousels).
  start,

  /// The current item is centered. This is the default.
  center,

  /// The current item touches the trailing edge.
  end,
}

/// How the carousel decides where to stop after the user lets go.
enum CarouselSnapping {
  /// A fling moves at most one item, like a `PageView`. This is the default.
  singlePage,

  /// A strong fling can travel several items, then snaps to the nearest one.
  multiPage,

  /// No snapping: the carousel glides and stops wherever friction ends it.
  none,
}

/// Autoplay settings for an `UltimateCarousel`.
///
/// ```dart
/// UltimateCarousel(
///   autoPlay: const CarouselAutoPlay(interval: Duration(seconds: 4)),
///   children: slides,
/// )
/// ```
@immutable
class CarouselAutoPlay {
  /// Creates autoplay settings. Autoplay is on unless [enabled] is false.
  const CarouselAutoPlay({
    this.enabled = true,
    this.interval = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 800),
    this.curve = Curves.easeInOutCubic,
    this.reverse = false,
    this.pauseOnHover = true,
    this.end = CarouselAutoPlayEnd.rewind,
  });

  /// Autoplay switched off. This is the carousel's default.
  static const CarouselAutoPlay off = CarouselAutoPlay(enabled: false);

  /// Whether autoplay starts when the carousel appears.
  ///
  /// It can be started and stopped later with the carousel's controller.
  /// Autoplay stays paused while the platform asks apps to reduce motion
  /// (`MediaQuery.disableAnimations`), and while the app is in the
  /// background.
  final bool enabled;

  /// How long each item stays before the carousel moves on.
  final Duration interval;

  /// How long the move to the next item takes.
  final Duration animationDuration;

  /// The curve of the move to the next item.
  final Curve curve;

  /// Play backwards, towards the previous item.
  final bool reverse;

  /// Pause while a mouse pointer hovers over the carousel.
  ///
  /// Autoplay always pauses while a finger or pointer is pressed on the
  /// carousel, and the interval restarts after every manual move.
  final bool pauseOnHover;

  /// What happens at the last item of a carousel that does not loop.
  final CarouselAutoPlayEnd end;

  /// Returns a copy with the given fields replaced.
  CarouselAutoPlay copyWith({
    bool? enabled,
    Duration? interval,
    Duration? animationDuration,
    Curve? curve,
    bool? reverse,
    bool? pauseOnHover,
    CarouselAutoPlayEnd? end,
  }) {
    return CarouselAutoPlay(
      enabled: enabled ?? this.enabled,
      interval: interval ?? this.interval,
      animationDuration: animationDuration ?? this.animationDuration,
      curve: curve ?? this.curve,
      reverse: reverse ?? this.reverse,
      pauseOnHover: pauseOnHover ?? this.pauseOnHover,
      end: end ?? this.end,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CarouselAutoPlay &&
        other.enabled == enabled &&
        other.interval == interval &&
        other.animationDuration == animationDuration &&
        other.curve == curve &&
        other.reverse == reverse &&
        other.pauseOnHover == pauseOnHover &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        interval,
        animationDuration,
        curve,
        reverse,
        pauseOnHover,
        end,
      );
}
