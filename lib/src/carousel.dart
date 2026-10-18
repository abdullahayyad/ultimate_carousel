import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'effects/effect.dart';
import 'item.dart';
import 'options.dart';

part 'carousel_controller.dart';

/// Signature for [UltimateCarousel.onPageChanged].
typedef CarouselPageChangedCallback = void Function(
  int index,
  CarouselPageChangeReason reason,
);

/// A carousel that can show its items with any transition.
///
/// Pick the look with [effect]; everything else (looping, autoplay,
/// vertical scrolling, indicators) works the same with every effect.
///
/// ```dart
/// UltimateCarousel(
///   effect: const CarouselEffect.coverflow(),
///   loop: true,
///   autoPlay: const CarouselAutoPlay(),
///   children: [
///     for (final color in Colors.primaries) ColoredBox(color: color),
///   ],
/// )
/// ```
///
/// When the carousel has no height from its parent (for example inside a
/// [Column]), it uses [height], or else its width divided by [aspectRatio].
class UltimateCarousel extends StatefulWidget {
  /// Creates a carousel from a list of widgets.
  UltimateCarousel({
    super.key,
    required List<Widget> children,
    this.effect = const CarouselEffect.slide(),
    this.controller,
    this.initialPage = 0,
    this.loop = false,
    this.autoPlay = CarouselAutoPlay.off,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.viewportFraction,
    this.spacing = 0,
    this.alignment = CarouselAlignment.center,
    this.height,
    this.aspectRatio = 16 / 9,
    this.onPageChanged,
    this.onScrolled,
    this.onItemTap,
    this.animateToTappedItem = false,
    this.enableDrag = true,
    this.snapping = CarouselSnapping.singlePage,
    this.bounce,
    this.dragDevices,
    this.enableKeyboard = true,
    this.focusNode,
    this.autofocus = false,
    this.enableMouseWheel = true,
    this.animationDuration = const Duration(milliseconds: 450),
    this.animationCurve = Curves.easeOutCubic,
    this.clipBehavior = Clip.hardEdge,
    this.semanticLabel,
  })  : itemCount = children.length,
        itemBuilder = _builderFor(children);

  /// Creates a carousel that builds its items on demand.
  ///
  /// Only the items that are on screen are built, so this suits long or
  /// expensive lists.
  const UltimateCarousel.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.effect = const CarouselEffect.slide(),
    this.controller,
    this.initialPage = 0,
    this.loop = false,
    this.autoPlay = CarouselAutoPlay.off,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.viewportFraction,
    this.spacing = 0,
    this.alignment = CarouselAlignment.center,
    this.height,
    this.aspectRatio = 16 / 9,
    this.onPageChanged,
    this.onScrolled,
    this.onItemTap,
    this.animateToTappedItem = false,
    this.enableDrag = true,
    this.snapping = CarouselSnapping.singlePage,
    this.bounce,
    this.dragDevices,
    this.enableKeyboard = true,
    this.focusNode,
    this.autofocus = false,
    this.enableMouseWheel = true,
    this.animationDuration = const Duration(milliseconds: 450),
    this.animationCurve = Curves.easeOutCubic,
    this.clipBehavior = Clip.hardEdge,
    this.semanticLabel,
  }) : assert(itemCount >= 0);

  static IndexedWidgetBuilder _builderFor(List<Widget> children) {
    return (BuildContext context, int index) => children[index];
  }

  /// How many items the carousel has.
  final int itemCount;

  /// Builds the item at an index.
  final IndexedWidgetBuilder itemBuilder;

  /// The transition between items. Defaults to a plain slide.
  ///
  /// See `CarouselEffect` for the full list.
  final CarouselEffect effect;

  /// Moves the carousel and reports its position. Optional.
  final UltimateCarouselController? controller;

  /// The item shown first.
  final int initialPage;

  /// Whether the carousel wraps around from the last item to the first.
  final bool loop;

  /// Autoplay settings. Autoplay is off by default.
  final CarouselAutoPlay autoPlay;

  /// The direction the items move in.
  final Axis scrollDirection;

  /// Whether the next item comes from the left (or top) instead of the right
  /// (or bottom). Right-to-left text direction reverses horizontal carousels
  /// on its own.
  final bool reverse;

  /// The fraction of the carousel's length that one item takes up.
  ///
  /// `null` uses the effect's own default, which is 1 for most transitions
  /// and smaller for effects that show neighbours, such as coverflow.
  final double? viewportFraction;

  /// The gap between neighbouring items, in logical pixels.
  final double spacing;

  /// Where the current item sits in the carousel.
  final CarouselAlignment alignment;

  /// The carousel's height. When `null` the carousel fills the height its
  /// parent allows, or uses [aspectRatio] if the parent sets no limit.
  final double? height;

  /// The width-to-height ratio used when neither the parent nor [height]
  /// sets the carousel's height.
  final double aspectRatio;

  /// Called when the item closest to the center changes.
  final CarouselPageChangedCallback? onPageChanged;

  /// Called every frame while the carousel moves, with the position between
  /// 0 and the item count (see `UltimateCarouselController.realPage`).
  final ValueChanged<double>? onScrolled;

  /// Called when the user taps an item, with the item's index.
  final ValueChanged<int>? onItemTap;

  /// Whether tapping an item that is not the current one moves to it.
  final bool animateToTappedItem;

  /// Whether the user can drag the carousel.
  final bool enableDrag;

  /// How the carousel decides where to stop after a drag.
  final CarouselSnapping snapping;

  /// Whether a carousel that does not loop stretches past its first and last
  /// item. `null` uses the platform's habit: on for iOS and macOS, off
  /// elsewhere.
  final bool? bounce;

  /// The pointer kinds that can drag the carousel. `null` allows all of them,
  /// including the mouse.
  final Set<PointerDeviceKind>? dragDevices;

  /// Whether the arrow, Page Up/Down, Home and End keys move the carousel
  /// while it has focus.
  final bool enableKeyboard;

  /// The focus node for keyboard control. Optional; the carousel makes its
  /// own when this is `null`.
  final FocusNode? focusNode;

  /// Whether the carousel takes the keyboard focus when it first appears.
  final bool autofocus;

  /// Whether the mouse wheel and trackpad move the carousel.
  ///
  /// Only scrolling along the carousel's direction is used; other scrolling
  /// passes through to the page around it.
  final bool enableMouseWheel;

  /// The duration of moves started by the keyboard, the mouse wheel, item
  /// taps and the controller.
  final Duration animationDuration;

  /// The curve of moves started by the keyboard, the mouse wheel, item taps
  /// and the controller.
  final Curve animationCurve;

  /// How to clip items that reach outside the carousel.
  ///
  /// Use [Clip.none] to let 3D effects spill over the edges.
  final Clip clipBehavior;

  /// A label for screen readers, such as "Featured products".
  final String? semanticLabel;

  @override
  State<UltimateCarousel> createState() => _UltimateCarouselState();
}

class _StageEntry {
  _StageEntry(this.info);

  final CarouselItemInfo info;
  CarouselItemTransform transform = CarouselItemTransform.identity;
  double order = 0;
}

class _UltimateCarouselState extends State<UltimateCarousel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 100,
    ratio: 1.1,
  );

  late final AnimationController _position;
  UltimateCarouselController? _ownController;
  final FocusNode _ownFocusNode = FocusNode(debugLabel: 'UltimateCarousel');
  final Map<int, Widget> _childCache = <int, Widget>{};

  CarouselLayout? _layout;
  double _dragExtent = 1;
  bool _reversed = false;
  Matrix4 _toScreen = Matrix4.identity();
  Matrix4 _toCarousel = Matrix4.identity();
  bool _identityMapping = true;

  bool _dragging = false;
  double _rawDragPage = 0;
  Offset _focalPoint = const Offset(0.5, 0.5);

  Timer? _autoPlayTimer;
  bool _autoPlayRunning = false;
  int _pointersDown = 0;
  bool _hovered = false;
  bool _foreground = true;
  bool _reduceMotion = false;
  int _pingPong = 1;

  double? _animationTarget;
  CarouselPageChangeReason _reason = CarouselPageChangeReason.user;
  int _reportedIndex = 0;

  double _wheelDelta = 0;
  bool _wheelLocked = false;
  Timer? _wheelTimer;

  UltimateCarouselController get _controller =>
      widget.controller ?? _ownController!;

  int get _count => widget.itemCount;

  bool get _loop => widget.loop && widget.itemCount > 1;

  double get _page => _position.value;

  double get _lastPage => math.max(0, _count - 1).toDouble();

  int _realIndexOf(int virtualIndex) {
    if (_count == 0) {
      return 0;
    }
    if (_loop) {
      return virtualIndex % _count;
    }
    return math.min(math.max(virtualIndex, 0), _count - 1);
  }

  int get _currentIndex => _count == 0 ? 0 : _realIndexOf(_page.round());

  double get _realPage {
    if (_count == 0) {
      return 0;
    }
    if (_loop) {
      return _page % _count;
    }
    return clampDouble(_page, 0, _lastPage);
  }

  bool get _bounces {
    final bool? bounce = widget.bounce;
    if (bounce != null) {
      return bounce;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle

  @override
  void initState() {
    super.initState();
    final int initial = _count == 0
        ? 0
        : _loop
            ? widget.initialPage
            : math.min(math.max(widget.initialPage, 0), _count - 1);
    _position = AnimationController.unbounded(
      vsync: this,
      value: initial.toDouble(),
    )..addListener(_handlePositionChanged);
    if (widget.controller == null) {
      _ownController = UltimateCarouselController();
    }
    _controller._attach(this);
    _reportedIndex = _currentIndex;
    _autoPlayRunning = widget.autoPlay.enabled;
    WidgetsBinding.instance.addObserver(this);
    final AppLifecycleState? lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion != _reduceMotion || _autoPlayTimer == null) {
      _reduceMotion = reduceMotion;
      _scheduleAutoPlay();
    }
  }

  @override
  void didUpdateWidget(UltimateCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _childCache.clear();
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?._detach(this);
      if (widget.controller == null) {
        _ownController ??= UltimateCarouselController();
      } else {
        _ownController?.dispose();
        _ownController = null;
      }
      _controller._attach(this);
    }
    final bool wasLooping = oldWidget.loop && oldWidget.itemCount > 1;
    if (_count > 0 && !_loop) {
      double target = _page;
      if (wasLooping) {
        target = _realIndexOf(_page.round()).toDouble();
      }
      target = clampDouble(target, 0, _lastPage);
      if (target != _page) {
        _position.stop();
        _animationTarget = null;
        _position.value = target;
      }
    }
    if (oldWidget.itemCount != widget.itemCount) {
      _controller._notifyLater();
    }
    if (oldWidget.autoPlay.enabled != widget.autoPlay.enabled) {
      _autoPlayRunning = widget.autoPlay.enabled;
    }
    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.itemCount != widget.itemCount ||
        oldWidget.loop != widget.loop) {
      _scheduleAutoPlay();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool foreground = state == AppLifecycleState.resumed;
    if (foreground != _foreground) {
      _foreground = foreground;
      _scheduleAutoPlay();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoPlayTimer?.cancel();
    _wheelTimer?.cancel();
    _controller._detach(this);
    _ownController?.dispose();
    _position.dispose();
    _ownFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Position reporting

  void _handlePositionChanged() {
    final int index = _currentIndex;
    final bool changed = index != _reportedIndex;
    if (changed) {
      _reportedIndex = index;
    }
    final CarouselPageChangeReason reason = _reason;
    final double realPage = _realPage;
    _runOutsideBuild(() {
      if (changed) {
        setState(() {});
        widget.onPageChanged?.call(index, reason);
      }
      widget.onScrolled?.call(realPage);
      _controller._notify();
    });
  }

  void _runOutsideBuild(VoidCallback callback) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) {
          callback();
        }
      });
    } else if (mounted) {
      callback();
    }
  }

  // ---------------------------------------------------------------------------
  // Autoplay

  bool get _canAutoPlay =>
      _autoPlayRunning &&
      _count > 1 &&
      _pointersDown == 0 &&
      !_dragging &&
      !(widget.autoPlay.pauseOnHover && _hovered) &&
      _foreground &&
      !_reduceMotion;

  void _cancelAutoPlayTimer() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _scheduleAutoPlay() {
    _cancelAutoPlayTimer();
    if (!mounted || !_canAutoPlay || _position.isAnimating) {
      return;
    }
    _autoPlayTimer = Timer(widget.autoPlay.interval, _autoPlayStep);
  }

  void _autoPlayStep() {
    _autoPlayTimer = null;
    if (!mounted || !_canAutoPlay || _position.isAnimating) {
      return;
    }
    final CarouselAutoPlay settings = widget.autoPlay;
    final double current = _page.roundToDouble();
    final int direction = (settings.reverse ? -1 : 1) * _pingPong;
    double target = current + direction;
    if (!_loop && (target < 0 || target > _lastPage)) {
      switch (settings.end) {
        case CarouselAutoPlayEnd.rewind:
          target = direction > 0 ? 0 : _lastPage;
        case CarouselAutoPlayEnd.pingPong:
          _pingPong = -_pingPong;
          target = current - direction;
        case CarouselAutoPlayEnd.stop:
          _autoPlayRunning = false;
          return;
      }
    }
    _animateTo(
      target,
      duration: settings.animationDuration,
      curve: settings.curve,
      reason: CarouselPageChangeReason.autoPlay,
    );
  }

  void _setAutoPlay(bool running) {
    _autoPlayRunning = running;
    if (running) {
      _pingPong = 1;
    }
    _scheduleAutoPlay();
  }

  // ---------------------------------------------------------------------------
  // Moving

  void _handleSettled() {
    if (!mounted) {
      return;
    }
    _animationTarget = null;
    _scheduleAutoPlay();
  }

  Future<void> _animateTo(
    double target, {
    Duration? duration,
    Curve? curve,
    required CarouselPageChangeReason reason,
  }) {
    if (_count == 0) {
      return Future<void>.value();
    }
    _cancelAutoPlayTimer();
    _reason = reason;
    double destination = target;
    if (!_loop) {
      destination = clampDouble(destination, 0, _lastPage);
    }
    final Duration effectiveDuration =
        _reduceMotion ? Duration.zero : duration ?? widget.animationDuration;
    if (effectiveDuration == Duration.zero || destination == _page) {
      _position.stop();
      _position.value = destination;
      _handleSettled();
      return Future<void>.value();
    }
    _animationTarget = destination;
    final Completer<void> completer = Completer<void>();
    final TickerFuture ticker = _position.animateTo(
      destination,
      duration: effectiveDuration,
      curve: curve ?? widget.animationCurve,
    );
    ticker.then((void _) => _handleSettled());
    ticker.whenCompleteOrCancel(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  Future<void> _step(
    int direction,
    CarouselPageChangeReason reason, {
    Duration? duration,
    Curve? curve,
  }) {
    final double from = (_animationTarget ?? _page).roundToDouble();
    return _animateTo(
      from + direction,
      duration: duration,
      curve: curve,
      reason: reason,
    );
  }

  double _targetForIndex(int index) {
    if (_count == 0) {
      return 0;
    }
    if (!_loop) {
      return math.min(math.max(index, 0), _count - 1).toDouble();
    }
    final double base = (_animationTarget ?? _page).roundToDouble();
    final int current = _realIndexOf(base.toInt());
    int difference = index % _count - current;
    if (difference > _count / 2) {
      difference -= _count;
    } else if (difference < -_count / 2) {
      difference += _count;
    }
    return base + difference;
  }

  void _jumpToIndex(int index) {
    if (_count == 0) {
      return;
    }
    _cancelAutoPlayTimer();
    _reason = CarouselPageChangeReason.controller;
    final double target = _targetForIndex(index);
    _position.stop();
    _position.value = target;
    _handleSettled();
  }

  void _jumpToPosition(double page) {
    if (_count == 0 || !page.isFinite) {
      return;
    }
    _cancelAutoPlayTimer();
    _reason = CarouselPageChangeReason.controller;
    _position.stop();
    _animationTarget = null;
    _position.value = _loop ? page : clampDouble(page, 0, _lastPage);
    _scheduleAutoPlay();
  }

  void _springTo(double target, double velocity) {
    if ((target - _page).abs() < 1e-6 && velocity.abs() < 1e-6) {
      if (_page != target) {
        _position.value = target;
      }
      _handleSettled();
      return;
    }
    _animationTarget = target;
    final SpringSimulation simulation = SpringSimulation(
      _spring,
      _page,
      target,
      velocity,
    );
    _position.animateWith(simulation).then((void _) {
      if (!mounted) {
        return;
      }
      if (_page != target) {
        _position.value = target;
      }
      _handleSettled();
    });
  }

  void _settle(double velocity) {
    if (_count == 0) {
      return;
    }
    final double page = _page;
    double target;
    switch (widget.snapping) {
      case CarouselSnapping.singlePage:
        if (velocity > 0) {
          target = page.floorToDouble() + 1;
        } else if (velocity < 0) {
          target = page.ceilToDouble() - 1;
        } else {
          target = page.roundToDouble();
        }
      case CarouselSnapping.multiPage:
        final double projected =
            FrictionSimulation(0.135, page, velocity).finalX;
        if (velocity > 0) {
          target =
              math.max(projected.roundToDouble(), page.floorToDouble() + 1);
        } else if (velocity < 0) {
          target = math.min(projected.roundToDouble(), page.ceilToDouble() - 1);
        } else {
          target = page.roundToDouble();
        }
      case CarouselSnapping.none:
        _glide(velocity);
        return;
    }
    if (!_loop) {
      target = clampDouble(target, 0, _lastPage);
    }
    _springTo(target, velocity);
  }

  void _glide(double velocity) {
    final double page = _page;
    if (!_loop && (page < 0 || page > _lastPage)) {
      _springTo(clampDouble(page, 0, _lastPage), velocity);
      return;
    }
    if (velocity.abs() < 1e-6) {
      _handleSettled();
      return;
    }
    final FrictionSimulation simulation =
        FrictionSimulation(0.135, page, velocity);
    final double end = simulation.finalX;
    if (!_loop && (end < 0 || end > _lastPage)) {
      _springTo(clampDouble(end, 0, _lastPage), velocity);
      return;
    }
    _animationTarget = end;
    _position.animateWith(simulation).then((void _) => _handleSettled());
  }

  double _applyBounds(double raw) {
    if (_loop || _count == 0) {
      return raw;
    }
    if (raw >= 0 && raw <= _lastPage) {
      return raw;
    }
    if (!_bounces) {
      return clampDouble(raw, 0, _lastPage);
    }
    final double overscroll = raw < 0 ? -raw : raw - _lastPage;
    const double limit = 0.6;
    final double damped = (1 - 1 / (overscroll * 0.55 / limit + 1)) * limit;
    return raw < 0 ? -damped : _lastPage + damped;
  }

  // ---------------------------------------------------------------------------
  // Gestures

  Map<Type, GestureRecognizerFactory> _buildGestures() {
    if (!widget.enableDrag || _count == 0) {
      return const <Type, GestureRecognizerFactory>{};
    }
    if (widget.scrollDirection == Axis.horizontal) {
      return <Type, GestureRecognizerFactory>{
        HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
            HorizontalDragGestureRecognizer>(
          () => HorizontalDragGestureRecognizer(
            debugOwner: this,
            supportedDevices: widget.dragDevices,
          ),
          _configureDrag,
        ),
      };
    }
    return <Type, GestureRecognizerFactory>{
      VerticalDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(
          debugOwner: this,
          supportedDevices: widget.dragDevices,
        ),
        _configureDrag,
      ),
    };
  }

  void _configureDrag(DragGestureRecognizer recognizer) {
    recognizer
      ..onDown = _handleDragDown
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel
      ..dragStartBehavior = DragStartBehavior.start;
  }

  void _handleDragDown(DragDownDetails details) {
    _cancelAutoPlayTimer();
    if (_position.isAnimating) {
      _position.stop();
      _animationTarget = null;
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _dragging = true;
    _reason = CarouselPageChangeReason.user;
    _rawDragPage = _page;
    _updateFocalPoint(details.localPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double delta = details.primaryDelta ?? 0;
    final double sign = _reversed ? -1 : 1;
    _rawDragPage -= delta / _dragExtent * sign;
    if (!_loop && !_bounces && _count > 0) {
      _rawDragPage = clampDouble(_rawDragPage, 0, _lastPage);
    }
    _updateFocalPoint(details.localPosition);
    _position.value = _applyBounds(_rawDragPage);
  }

  void _handleDragEnd(DragEndDetails details) {
    _dragging = false;
    final double sign = _reversed ? -1 : 1;
    final double velocity =
        -(details.primaryVelocity ?? 0) / _dragExtent * sign;
    _settle(velocity);
  }

  void _handleDragCancel() {
    if (!mounted) {
      return;
    }
    _dragging = false;
    _settle(0);
  }

  void _updateFocalPoint(Offset localPosition) {
    final CarouselLayout? layout = _layout;
    if (layout == null ||
        layout.viewportMainExtent <= 0 ||
        layout.viewportCrossExtent <= 0) {
      return;
    }
    final bool horizontal = widget.scrollDirection == Axis.horizontal;
    final Size screenSize = horizontal
        ? layout.viewportSize
        : Size(layout.viewportCrossExtent, layout.viewportMainExtent);
    final Offset fromCenter =
        localPosition - Offset(screenSize.width / 2, screenSize.height / 2);
    final Offset inCarousel =
        MatrixUtils.transformPoint(_toCarousel, fromCenter);
    _focalPoint = Offset(
      clampDouble(inCarousel.dx / layout.viewportMainExtent + 0.5, 0, 1),
      clampDouble(inCarousel.dy / layout.viewportCrossExtent + 0.5, 0, 1),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointersDown++;
    _cancelAutoPlayTimer();
  }

  void _handlePointerUp(PointerEvent event) {
    _pointersDown = math.max(0, _pointersDown - 1);
    if (_pointersDown == 0 && !_dragging && !_position.isAnimating) {
      _scheduleAutoPlay();
    }
  }

  void _handleEnter(PointerEnterEvent event) {
    _hovered = true;
    if (widget.autoPlay.pauseOnHover) {
      _cancelAutoPlayTimer();
    }
  }

  void _handleExit(PointerExitEvent event) {
    _hovered = false;
    if (!_position.isAnimating) {
      _scheduleAutoPlay();
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!widget.enableMouseWheel ||
        event is! PointerScrollEvent ||
        _count < 2) {
      return;
    }
    double delta;
    if (widget.scrollDirection == Axis.horizontal) {
      delta = event.scrollDelta.dx;
      if (delta == 0 && _shiftPressed) {
        delta = event.scrollDelta.dy;
      }
    } else {
      delta = event.scrollDelta.dy;
    }
    if (delta == 0) {
      return;
    }
    final int direction = (delta > 0 ? 1 : -1) * (_reversed ? -1 : 1);
    if (!_loop) {
      final int target = _currentIndex + direction;
      if (target < 0 || target >= _count) {
        return;
      }
    }
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (PointerSignalEvent resolved) => _handleWheel(direction, delta.abs()),
    );
  }

  bool get _shiftPressed {
    final Set<LogicalKeyboardKey> pressed =
        HardwareKeyboard.instance.logicalKeysPressed;
    return pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
  }

  void _handleWheel(int direction, double amount) {
    if (_wheelLocked) {
      return;
    }
    _wheelDelta += amount;
    if (_wheelDelta < 20) {
      return;
    }
    _wheelDelta = 0;
    _wheelLocked = true;
    _wheelTimer?.cancel();
    _wheelTimer = Timer(
      Duration(
        milliseconds: math.max(200, widget.animationDuration.inMilliseconds),
      ),
      () {
        _wheelLocked = false;
        _wheelDelta = 0;
      },
    );
    _step(direction, CarouselPageChangeReason.user);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enableKeyboard ||
        _count < 2 ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    final bool horizontal = widget.scrollDirection == Axis.horizontal;
    int? direction;
    if (horizontal && key == LogicalKeyboardKey.arrowRight) {
      direction = 1;
    } else if (horizontal && key == LogicalKeyboardKey.arrowLeft) {
      direction = -1;
    } else if (!horizontal && key == LogicalKeyboardKey.arrowDown) {
      direction = 1;
    } else if (!horizontal && key == LogicalKeyboardKey.arrowUp) {
      direction = -1;
    }
    if (direction != null && _reversed) {
      direction = -direction;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      direction = 1;
    } else if (key == LogicalKeyboardKey.pageUp) {
      direction = -1;
    }
    if (direction != null) {
      _step(direction, CarouselPageChangeReason.user);
      return KeyEventResult.handled;
    }
    if (!_loop && key == LogicalKeyboardKey.home) {
      _animateTo(0, reason: CarouselPageChangeReason.user);
      return KeyEventResult.handled;
    }
    if (!_loop && key == LogicalKeyboardKey.end) {
      _animateTo(_lastPage, reason: CarouselPageChangeReason.user);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleItemTap(int virtualIndex, int index) {
    widget.onItemTap?.call(index);
    if (widget.animateToTappedItem && (virtualIndex - _page).abs() > 0.01) {
      _animateTo(
        virtualIndex.toDouble(),
        reason: CarouselPageChangeReason.user,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Building

  void _updateMapping() {
    final bool horizontal = widget.scrollDirection == Axis.horizontal;
    // Each mapping is a 2x2 matrix [a b; c d] acting on (x, y), written into
    // a 4x4 matrix in column-major order.
    Matrix4 mapping(double a, double b, double c, double d) {
      return Matrix4(a, c, 0, 0, b, d, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    }

    if (horizontal && !_reversed) {
      _identityMapping = true;
      _toScreen = Matrix4.identity();
      _toCarousel = Matrix4.identity();
    } else if (horizontal) {
      _identityMapping = false;
      _toScreen = mapping(-1, 0, 0, 1);
      _toCarousel = mapping(-1, 0, 0, 1);
    } else if (!_reversed) {
      _identityMapping = false;
      _toScreen = mapping(0, 1, 1, 0);
      _toCarousel = mapping(0, 1, 1, 0);
    } else {
      _identityMapping = false;
      _toScreen = mapping(0, 1, -1, 0);
      _toCarousel = mapping(0, -1, 1, 0);
    }
  }

  Matrix4 _matrixOnScreen(Matrix4 matrix) {
    if (_identityMapping) {
      return matrix;
    }
    return Matrix4.copy(_toScreen)
      ..multiply(matrix)
      ..multiply(_toCarousel);
  }

  Path _pathOnScreen(Path path, Size itemSize) {
    final Path mapped =
        _identityMapping ? path : path.transform(_toScreen.storage);
    return mapped.shift(Offset(itemSize.width / 2, itemSize.height / 2));
  }

  Size _resolveSize(BoxConstraints constraints) {
    double width = constraints.maxWidth;
    double height = widget.height ?? constraints.maxHeight;
    final double ratio = widget.aspectRatio > 0 ? widget.aspectRatio : 16 / 9;
    if (!width.isFinite) {
      width = height.isFinite ? height * ratio : 0;
    }
    if (!height.isFinite) {
      height = width / ratio;
    }
    assert(
      width.isFinite && height.isFinite,
      'UltimateCarousel needs a bounded width or height.',
    );
    return constraints.constrain(Size(width, height));
  }

  CarouselLayout _computeLayout(Size size) {
    final bool horizontal = widget.scrollDirection == Axis.horizontal;
    final Size viewport = horizontal ? size : Size(size.height, size.width);
    final double fraction = math.max(
      0.0,
      widget.viewportFraction ?? widget.effect.defaultViewportFraction,
    );
    return CarouselLayout(
      viewportSize: viewport,
      itemSize: Size(viewport.width * fraction, viewport.height),
      spacing: widget.spacing,
      itemCount: _count,
      loop: _loop,
      alignment: widget.alignment,
      scrollDirection: widget.scrollDirection,
      reversed: _reversed,
    );
  }

  int _defaultItemsPerSide(CarouselLayout layout) {
    final double reach = layout.viewportMainExtent / 2 +
        layout.alignmentOffset.abs() +
        layout.itemMainExtent / 2;
    final double slot = math.max(layout.slotExtent, 1.0);
    return math.max(1, (reach / slot).ceil());
  }

  Widget _childFor(int virtualIndex, int index) {
    return _childCache.putIfAbsent(
      virtualIndex,
      () => RepaintBoundary(
        child: Builder(
          builder: (BuildContext context) => widget.itemBuilder(context, index),
        ),
      ),
    );
  }

  List<_StageEntry> _uniqueEntries(List<_StageEntry> entries) {
    final Map<int, _StageEntry> byIndex = <int, _StageEntry>{};
    for (final _StageEntry entry in entries) {
      final _StageEntry? existing = byIndex[entry.info.index];
      if (existing == null ||
          entry.info.distance < existing.info.distance - 1e-9) {
        byIndex[entry.info.index] = entry;
      }
    }
    return byIndex.values.toList()
      ..sort(
        (_StageEntry a, _StageEntry b) =>
            a.info.virtualIndex.compareTo(b.info.virtualIndex),
      );
  }

  Widget _buildStage(BuildContext context, CarouselLayout layout) {
    if (_count == 0 ||
        layout.viewportMainExtent <= 0 ||
        layout.viewportCrossExtent <= 0) {
      return const SizedBox.shrink();
    }
    final CarouselEffect effect = widget.effect;
    final double page = _page;
    final int perSide = math.min(
      64,
      math.max(0, effect.itemsPerSide(layout) ?? _defaultItemsPerSide(layout)),
    );
    final int first = page.floor() - perSide;
    final int last = page.ceil() + perSide;
    List<_StageEntry> entries = <_StageEntry>[];
    for (int virtualIndex = first; virtualIndex <= last; virtualIndex++) {
      if (!_loop && (virtualIndex < 0 || virtualIndex >= _count)) {
        continue;
      }
      entries.add(
        _StageEntry(
          CarouselItemInfo(
            delta: virtualIndex - page,
            index: _realIndexOf(virtualIndex),
            virtualIndex: virtualIndex,
            page: page,
            layout: layout,
            focalPoint: _focalPoint,
          ),
        ),
      );
    }
    if (_loop && effect.uniqueItems) {
      entries = _uniqueEntries(entries);
    }
    for (final _StageEntry entry in entries) {
      entry
        ..transform = effect.transform(entry.info)
        ..order = effect.paintOrder(entry.info);
    }
    mergeSort<_StageEntry>(
      entries,
      compare: (_StageEntry a, _StageEntry b) => a.order.compareTo(b.order),
    );
    final Set<int> shown = <int>{};
    final List<Widget> children = <Widget>[];
    for (final _StageEntry entry in entries) {
      shown.add(entry.info.virtualIndex);
      children.add(_buildItem(context, entry, layout));
    }
    _childCache.removeWhere((int key, Widget _) => !shown.contains(key));
    return Stack(clipBehavior: Clip.none, children: children);
  }

  Widget _buildItem(
    BuildContext context,
    _StageEntry entry,
    CarouselLayout layout,
  ) {
    final CarouselItemInfo info = entry.info;
    final CarouselItemTransform transform = entry.transform;
    final bool horizontal = widget.scrollDirection == Axis.horizontal;
    final Size itemSize = horizontal
        ? layout.itemSize
        : Size(layout.itemCrossExtent, layout.itemMainExtent);
    final Size screenSize = horizontal
        ? layout.viewportSize
        : Size(layout.viewportCrossExtent, layout.viewportMainExtent);
    final Offset anchor = MatrixUtils.transformPoint(
      _toScreen,
      Offset(layout.alignmentOffset, 0),
    );
    final Offset center =
        Offset(screenSize.width / 2, screenSize.height / 2) + anchor;
    final double opacity =
        transform.visible ? clampDouble(transform.opacity, 0, 1) : 0;
    final bool tappable =
        widget.onItemTap != null || widget.animateToTappedItem;

    Widget child = CarouselItemScope(
      info: info,
      child: _childFor(info.virtualIndex, info.index),
    );
    final Matrix4? contentMatrix = transform.contentMatrix;
    child = Transform(
      alignment: Alignment.center,
      transform: contentMatrix == null
          ? Matrix4.identity()
          : _matrixOnScreen(contentMatrix),
      child: child,
    );
    child = ClipRect(
      clipBehavior: transform.clipContent ? Clip.hardEdge : Clip.none,
      child: child,
    );
    child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          tappable ? () => _handleItemTap(info.virtualIndex, info.index) : null,
      child: child,
    );
    if (widget.effect.shadesItems) {
      final int alpha = (clampDouble(transform.shade, 0, 1) * 255).round();
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(
          Color.fromARGB(alpha, 0, 0, 0),
          BlendMode.srcATop,
        ),
        child: child,
      );
    }
    if (widget.effect.blursItems) {
      final double sigma = math.max(0.0, transform.blur);
      child = ImageFiltered(
        enabled: sigma > 0.05,
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      );
    }
    final Path? clipPath = transform.clipPath;
    child = ClipPath(
      clipper: clipPath == null
          ? null
          : _ItemClipper(_pathOnScreen(clipPath, itemSize)),
      clipBehavior: clipPath == null ? Clip.none : Clip.antiAlias,
      child: child,
    );
    child = widget.effect.decorate(context, child, info);
    child = Opacity(opacity: opacity, child: child);
    child = IgnorePointer(
      ignoring: opacity <= 0 || !transform.interactive,
      child: child,
    );
    child = ExcludeSemantics(
      excluding: opacity <= 0 || !info.isCurrent,
      child: child,
    );
    // The transform is the outermost layer: a transform does not check its
    // own bounds when hit testing, so items moved away from their resting
    // place still receive taps.
    final Matrix4? matrix = transform.matrix;
    child = Transform(
      alignment: Alignment.center,
      transform: matrix == null ? Matrix4.identity() : _matrixOnScreen(matrix),
      child: child,
    );
    return Positioned(
      key: _SlotKey(info.virtualIndex),
      left: center.dx - itemSize.width / 2,
      top: center.dy - itemSize.height / 2,
      width: itemSize.width,
      height: itemSize.height,
      child: child,
    );
  }

  Widget _buildWithConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final Size size = _resolveSize(constraints);
    final CarouselLayout layout = _computeLayout(size);
    _layout = layout;
    _dragExtent = math.max(1.0, widget.effect.dragExtent(layout));
    Widget stage = AnimatedBuilder(
      animation: _position,
      builder: (BuildContext context, Widget? child) =>
          _buildStage(context, layout),
    );
    if (widget.clipBehavior != Clip.none) {
      stage = ClipRect(clipBehavior: widget.clipBehavior, child: stage);
    }
    return SizedBox.fromSize(
      size: size,
      child: RawGestureDetector(
        gestures: _buildGestures(),
        behavior: HitTestBehavior.opaque,
        child: stage,
      ),
    );
  }

  bool _computeReversed(BuildContext context) {
    if (widget.scrollDirection == Axis.horizontal) {
      final bool rtl = Directionality.maybeOf(context) == TextDirection.rtl;
      return widget.reverse != rtl;
    }
    return widget.reverse;
  }

  @override
  Widget build(BuildContext context) {
    _reversed = _computeReversed(context);
    _updateMapping();
    final bool horizontal = widget.scrollDirection == Axis.horizontal;
    final int index = _currentIndex;
    final bool canGoNext = _count > 1 && (_loop || index < _count - 1);
    final bool canGoBack = _count > 1 && (_loop || index > 0);
    final VoidCallback? next =
        canGoNext ? () => _step(1, CarouselPageChangeReason.user) : null;
    final VoidCallback? previous =
        canGoBack ? () => _step(-1, CarouselPageChangeReason.user) : null;
    // Swiping content towards the left shows the item on the right.
    final VoidCallback? towardsStart = _reversed ? previous : next;
    final VoidCallback? towardsEnd = _reversed ? next : previous;

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: _count == 0 ? null : '${index + 1} / $_count',
      onScrollLeft: horizontal ? towardsStart : null,
      onScrollRight: horizontal ? towardsEnd : null,
      onScrollUp: horizontal ? null : towardsStart,
      onScrollDown: horizontal ? null : towardsEnd,
      child: Focus(
        focusNode: widget.focusNode ?? _ownFocusNode,
        autofocus: widget.autofocus,
        canRequestFocus: widget.enableKeyboard,
        skipTraversal: !widget.enableKeyboard,
        onKeyEvent: _handleKeyEvent,
        child: MouseRegion(
          onEnter: _handleEnter,
          onExit: _handleExit,
          child: Listener(
            onPointerDown: _handlePointerDown,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerUp,
            onPointerSignal: _handlePointerSignal,
            child: LayoutBuilder(builder: _buildWithConstraints),
          ),
        ),
      ),
    );
  }
}

/// Identifies an item's slot in the stage. It is a type of its own so it
/// never matches keys that apps give their items.
class _SlotKey extends ValueKey<int> {
  const _SlotKey(super.value);
}

class _ItemClipper extends CustomClipper<Path> {
  _ItemClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_ItemClipper oldClipper) => oldClipper.path != path;
}
