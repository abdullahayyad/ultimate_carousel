import 'package:flutter/widgets.dart';

/// Builds an item transform step by step, in carousel space.
///
/// Each call applies one more step after the previous ones, the way you would
/// describe the motion out loud: "turn it around its left edge, then slide it
/// right, then look at it in perspective".
///
/// ```dart
/// final matrix = ItemMatrix()
///   ..rotateY(0.5, pivot: Offset(-width / 2, 0))
///   ..translate(width * delta)
///   ..perspective(0.002);
/// return CarouselItemTransform(matrix: matrix.value);
/// ```
///
/// The origin is the item's resting center. x points towards the next item,
/// y across the carousel, and positive z away from the viewer.
class ItemMatrix {
  /// Starts from the identity transform.
  ItemMatrix();

  final Matrix4 _value = Matrix4.identity();

  /// The transform built so far.
  Matrix4 get value => _value;

  void _apply(Matrix4 step) {
    _value.setFrom(Matrix4.copy(step)..multiply(_value));
  }

  void _applyAround(Matrix4 step, Offset pivot) {
    if (pivot == Offset.zero) {
      _apply(step);
      return;
    }
    _apply(
      Matrix4.translationValues(pivot.dx, pivot.dy, 0)
        ..multiply(step)
        ..multiply(Matrix4.translationValues(-pivot.dx, -pivot.dy, 0)),
    );
  }

  /// Moves the item.
  void translate(double x, [double y = 0, double z = 0]) {
    if (x == 0 && y == 0 && z == 0) {
      return;
    }
    _apply(Matrix4.translationValues(x, y, z));
  }

  /// Scales the item by [x] along the scroll direction and [y] (defaulting
  /// to [x]) across it, around [pivot].
  void scale(double x, {double? y, Offset pivot = Offset.zero}) {
    final double scaleY = y ?? x;
    if (x == 1 && scaleY == 1) {
      return;
    }
    _applyAround(Matrix4.diagonal3Values(x, scaleY, 1), pivot);
  }

  /// Turns the item around a horizontal line through [pivot] (tilting it
  /// forwards or backwards).
  void rotateX(double radians, {Offset pivot = Offset.zero}) {
    if (radians == 0) {
      return;
    }
    _applyAround(Matrix4.rotationX(radians), pivot);
  }

  /// Turns the item around a vertical line through [pivot] (like a door).
  ///
  /// A positive angle swings the item's right edge towards the viewer.
  void rotateY(double radians, {Offset pivot = Offset.zero}) {
    if (radians == 0) {
      return;
    }
    _applyAround(Matrix4.rotationY(radians), pivot);
  }

  /// Turns the item in the screen's plane around [pivot] (like a clock hand).
  ///
  /// A positive angle turns it clockwise.
  void rotateZ(double radians, {Offset pivot = Offset.zero}) {
    if (radians == 0) {
      return;
    }
    _applyAround(Matrix4.rotationZ(radians), pivot);
  }

  /// Adds perspective, so things further away (positive z) look smaller.
  ///
  /// Typical values are between 0.0005 and 0.003; larger means a stronger,
  /// closer-feeling 3D look.
  void perspective(double strength) {
    if (strength == 0) {
      return;
    }
    _apply(Matrix4.identity()..setEntry(3, 2, strength));
  }
}
