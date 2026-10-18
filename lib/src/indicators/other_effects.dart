import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'indicator_effect.dart';

/// A thin track with a bar that slides along it, or fills it up.
class LineIndicatorEffect extends IndicatorEffect {
  /// Creates a line indicator.
  const LineIndicatorEffect({
    this.length,
    this.thickness = 4,
    this.trackColor = const Color(0x33808080),
    this.activeColor = const Color(0xFF3F51B5),
    this.fill = false,
  });

  /// The length of the track. `null` gives every item 24 logical pixels.
  final double? length;

  /// The thickness of the track and the bar.
  final double thickness;

  /// The color of the track.
  final Color trackColor;

  /// The color of the bar.
  final Color activeColor;

  /// Whether the bar fills the track from the start up to the current item,
  /// instead of being one item long and sliding.
  final bool fill;

  double _length(int count) => length ?? 24.0 * math.max(count, 1);

  @override
  Size calculateSize(int count) => Size(_length(count), thickness);

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    final Radius corner = Radius.circular(thickness / 2);
    final double top = (size.height - thickness) / 2;
    canvas.drawRRect(
      RRect.fromLTRBR(0, top, size.width, top + thickness, corner),
      Paint()..color = trackColor,
    );
    final Paint bar = Paint()..color = activeColor;
    final double unit = size.width / math.max(count, 1);
    final IndicatorSegment segment = IndicatorSegment.of(page, count);
    if (fill) {
      final double filled = segment.wraps
          ? unit * (1 + (count - 1) * (1 - segment.t))
          : unit * (segment.from + 1 + segment.t);
      canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          top,
          clampDouble(filled, 0, size.width),
          top + thickness,
          corner,
        ),
        bar,
      );
      return;
    }
    void drawAt(double position) {
      final double left = position * unit;
      canvas.drawRRect(
        RRect.fromLTRBR(left, top, left + unit, top + thickness, corner),
        bar,
      );
    }

    if (segment.wraps) {
      paintWithOpacity(
          canvas, size, 1 - segment.t, () => drawAt(segment.from.toDouble()));
      paintWithOpacity(
          canvas, size, segment.t, () => drawAt(segment.to.toDouble()));
    } else {
      drawAt(segment.from + segment.t);
    }
  }

  @override
  int? hitTest(Offset position, Size size, double page, int count) {
    final double unit = size.width / math.max(count, 1);
    final int index = (position.dx / unit).floor();
    return index >= 0 && index < count ? index : null;
  }
}

/// The position as text, such as "3 / 10".
class FractionIndicatorEffect extends IndicatorEffect {
  /// Creates a text indicator.
  const FractionIndicatorEffect({
    this.style = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF424242),
    ),
    this.separator = ' / ',
  });

  /// The text style.
  final TextStyle style;

  /// The text between the current position and the total.
  final String separator;

  TextPainter _painter(String text) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool get followsAxis => false;

  @override
  Size calculateSize(int count) {
    final TextPainter painter = _painter('$count$separator$count');
    final Size size = painter.size;
    painter.dispose();
    return Size(size.width.ceilToDouble(), size.height.ceilToDouble());
  }

  @override
  void paint(Canvas canvas, Size size, double page, int count) {
    if (count <= 0) {
      return;
    }
    final int current = page.round() % count;
    final TextPainter painter = _painter('${current + 1}$separator$count');
    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
    painter.dispose();
  }
}
