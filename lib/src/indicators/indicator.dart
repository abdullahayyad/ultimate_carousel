import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../carousel.dart';
import 'indicator_effect.dart';

/// An animated page indicator that follows an [UltimateCarousel].
///
/// ```dart
/// final controller = UltimateCarouselController();
///
/// Column(children: [
///   UltimateCarousel(controller: controller, children: slides),
///   CarouselIndicator(
///     controller: controller,
///     effect: const IndicatorEffect.expandingDots(),
///   ),
/// ])
/// ```
///
/// Tapping a dot moves the carousel to that item. Use
/// [CarouselIndicator.value] to drive the indicator yourself, for example
/// from a `PageController`.
class CarouselIndicator extends StatelessWidget {
  /// Creates an indicator that follows [controller].
  const CarouselIndicator({
    super.key,
    required UltimateCarouselController this.controller,
    this.effect = const IndicatorEffect.worm(),
    this.count,
    this.axis = Axis.horizontal,
    this.onDotTap,
    this.semanticLabel,
  }) : page = null;

  /// Creates an indicator that shows a fixed [page] out of [count] items.
  ///
  /// Rebuild it with a new page to animate it.
  const CarouselIndicator.value({
    super.key,
    required double this.page,
    required int this.count,
    this.effect = const IndicatorEffect.worm(),
    this.axis = Axis.horizontal,
    this.onDotTap,
    this.semanticLabel,
  }) : controller = null;

  /// The carousel controller to follow.
  final UltimateCarouselController? controller;

  /// The page to show when there is no [controller], from 0 to [count].
  final double? page;

  /// The number of dots. Defaults to the controller's item count.
  final int? count;

  /// How the indicator looks and moves.
  final IndicatorEffect effect;

  /// Whether the dots run left to right or top to bottom.
  final Axis axis;

  /// Called with a dot's index when it is tapped.
  ///
  /// Defaults to moving the carousel to that item when a [controller] is set.
  final ValueChanged<int>? onDotTap;

  /// A label for screen readers. Defaults to none; the current position is
  /// always announced as "3 / 10".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final UltimateCarouselController? controller = this.controller;
    if (controller == null) {
      return _buildIndicator(context, page ?? 0, count ?? 0);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) => _buildIndicator(
        context,
        controller.realPage,
        count ?? controller.itemCount,
      ),
    );
  }

  Widget _buildIndicator(BuildContext context, double page, int count) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    final bool rtl = axis == Axis.horizontal &&
        Directionality.maybeOf(context) == TextDirection.rtl;
    final double safePage =
        page.isFinite ? clampDouble(page, 0, count.toDouble()) : 0;
    final Size natural = effect.calculateSize(count);
    final bool turned = axis == Axis.vertical && effect.followsAxis;
    final Size size = turned ? Size(natural.height, natural.width) : natural;
    final ValueChanged<int>? onTap = onDotTap ??
        (controller == null ? null : (int i) => controller!.animateToPage(i));
    final int current = safePage.round() % count;
    Widget result = CustomPaint(
      size: size,
      painter: _IndicatorPainter(
        effect: effect,
        page: safePage,
        count: count,
        axis: axis,
        rtl: rtl,
      ),
    );
    if (onTap != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          final Offset local =
              _toEffectSpace(details.localPosition, size, turned, rtl);
          final int? index = effect.hitTest(local, natural, safePage, count);
          if (index != null) {
            onTap(index);
          }
        },
        child: result,
      );
    }
    return Semantics(
      label: semanticLabel,
      value: '${current + 1} / $count',
      child: result,
    );
  }
}

Offset _toEffectSpace(Offset position, Size size, bool turned, bool rtl) {
  if (turned) {
    return Offset(position.dy, position.dx);
  }
  return Offset(rtl ? size.width - position.dx : position.dx, position.dy);
}

class _IndicatorPainter extends CustomPainter {
  _IndicatorPainter({
    required this.effect,
    required this.page,
    required this.count,
    required this.axis,
    required this.rtl,
  });

  final IndicatorEffect effect;
  final double page;
  final int count;
  final Axis axis;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    Size natural = size;
    if (axis == Axis.vertical && effect.followsAxis) {
      // Paint in horizontal space, then mirror across the diagonal so the
      // first dot ends up at the top.
      canvas.transform(
        Matrix4(0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1).storage,
      );
      natural = Size(size.height, size.width);
    }
    if (rtl) {
      canvas
        ..translate(natural.width, 0)
        ..scale(-1, 1);
    }
    effect.paint(canvas, natural, page, count);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IndicatorPainter oldDelegate) {
    return oldDelegate.page != page ||
        oldDelegate.count != count ||
        oldDelegate.effect != effect ||
        oldDelegate.axis != axis ||
        oldDelegate.rtl != rtl;
  }
}
