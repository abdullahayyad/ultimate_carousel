part of 'carousel.dart';

/// Controls an [UltimateCarousel] and reports where it is.
///
/// Create one in your state, pass it to the carousel, and dispose it with the
/// state:
///
/// ```dart
/// final controller = UltimateCarouselController();
///
/// UltimateCarousel(controller: controller, children: slides);
/// CarouselIndicator(controller: controller);
///
/// controller.nextPage();
/// ```
///
/// The controller is a [ChangeNotifier]: it notifies its listeners every
/// time the carousel moves, which is how [CarouselIndicator] follows it.
class UltimateCarouselController extends ChangeNotifier {
  /// Creates a controller. It does nothing until a carousel uses it.
  UltimateCarouselController();

  _UltimateCarouselState? _state;
  bool _disposed = false;

  /// Whether a carousel is currently using this controller.
  bool get hasClients => _state != null;

  /// The carousel's position on its endless strip of items, in items.
  ///
  /// For a carousel that does not loop this is the same as [realPage]. For a
  /// looping carousel it keeps growing as the user scrolls forwards.
  double get page => _state?._page ?? 0;

  /// The carousel's position between 0 and [itemCount], in items.
  ///
  /// A value of 2.5 means the carousel is halfway between the third and the
  /// fourth item. In a looping carousel, values above `itemCount - 1` mean it
  /// is moving from the last item to the first.
  double get realPage => _state?._realPage ?? 0;

  /// The index of the item closest to the center.
  int get currentIndex => _state?._currentIndex ?? 0;

  /// How many items the carousel has, or 0 when no carousel is attached.
  int get itemCount => _state?._count ?? 0;

  /// Whether the attached carousel loops forever.
  bool get isLooping => _state?._loop ?? false;

  /// Whether autoplay is switched on. It may be paused for a moment, for
  /// example while the user touches the carousel.
  bool get isAutoPlaying => _state?._autoPlayRunning ?? false;

  /// Animates to the next item.
  ///
  /// The returned future completes when the animation ends or is
  /// interrupted.
  Future<void> nextPage({Duration? duration, Curve? curve}) {
    return _state?._step(
          1,
          CarouselPageChangeReason.controller,
          duration: duration,
          curve: curve,
        ) ??
        Future<void>.value();
  }

  /// Animates to the previous item.
  Future<void> previousPage({Duration? duration, Curve? curve}) {
    return _state?._step(
          -1,
          CarouselPageChangeReason.controller,
          duration: duration,
          curve: curve,
        ) ??
        Future<void>.value();
  }

  /// Animates to the item at [index].
  ///
  /// A looping carousel takes the shorter way round.
  Future<void> animateToPage(int index, {Duration? duration, Curve? curve}) {
    final _UltimateCarouselState? state = _state;
    if (state == null) {
      return Future<void>.value();
    }
    return state._animateTo(
      state._targetForIndex(index),
      duration: duration,
      curve: curve,
      reason: CarouselPageChangeReason.controller,
    );
  }

  /// Jumps to the item at [index] without animating.
  void jumpToPage(int index) {
    _state?._jumpToIndex(index);
  }

  /// Starts autoplay, using the carousel's `autoPlay` settings.
  void startAutoPlay() {
    _state?._setAutoPlay(true);
  }

  /// Stops autoplay until [startAutoPlay] is called.
  void stopAutoPlay() {
    _state?._setAutoPlay(false);
  }

  void _attach(_UltimateCarouselState state) {
    _state = state;
    _notifyLater();
  }

  void _detach(_UltimateCarouselState state) {
    if (identical(_state, state)) {
      _state = null;
      _notifyLater();
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _notifyLater() {
    SchedulerBinding.instance.addPostFrameCallback((Duration _) => _notify());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
