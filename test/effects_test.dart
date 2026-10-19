import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_carousel/ultimate_carousel.dart';

/// Every built-in effect, with a name for test descriptions.
const List<(String, CarouselEffect)> allEffects = <(String, CarouselEffect)>[
  ('slide', CarouselEffect.slide()),
  ('fade', CarouselEffect.fade()),
  ('cross fade', CarouselEffect.fade(crossFade: true)),
  ('enlarge', CarouselEffect.enlarge()),
  (
    'enlarge zoom',
    CarouselEffect.enlarge(strategy: CarouselEnlargeStrategy.zoom),
  ),
  (
    'enlarge height',
    CarouselEffect.enlarge(strategy: CarouselEnlargeStrategy.height),
  ),
  ('zoom out', CarouselEffect.zoomOut()),
  ('zoom in', CarouselEffect.zoomIn()),
  ('depth', CarouselEffect.depth()),
  ('parallax', CarouselEffect.parallax()),
  ('stack', CarouselEffect.stack()),
  ('accordion', CarouselEffect.accordion()),
  ('zoom fade', CarouselEffect.fade(zoom: 1.15)),
  ('rotate', CarouselEffect.rotate()),
  ('rotate from top', CarouselEffect.rotate(fromTop: true)),
  ('foreground to background', CarouselEffect.foregroundToBackground()),
  ('background to foreground', CarouselEffect.backgroundToForeground()),
  ('focus', CarouselEffect.focus()),
  ('overlap', CarouselEffect.overlap()),
  ('uncover', CarouselEffect.uncover()),
  ('uncover, still', CarouselEffect.uncover(parallax: 0, shade: 0)),
  ('skew', CarouselEffect.skew()),
  ('cube', CarouselEffect.cube()),
  ('cube inside', CarouselEffect.cube(inside: true)),
  ('flip', CarouselEffect.flip()),
  ('flip vertical', CarouselEffect.flip(vertical: true)),
  ('coverflow', CarouselEffect.coverflow()),
  ('tablet', CarouselEffect.tablet()),
  ('ring', CarouselEffect.ring()),
  ('ring facing', CarouselEffect.ring(faceViewer: true, showBackItems: true)),
  ('wheel', CarouselEffect.wheel()),
  ('cylinder', CarouselEffect.cylinder()),
  ('helix', CarouselEffect.helix()),
  ('ring tilted', CarouselEffect.ring(tilt: 0.3, faceViewer: true)),
  ('page turn', CarouselEffect.pageTurn()),
  ('tunnel', CarouselEffect.tunnel()),
  ('material', CarouselEffect.material()),
  ('material hero', CarouselEffect.material(weights: <int>[1, 7, 1])),
  ('deck', CarouselEffect.deck()),
  ('tinder', CarouselEffect.tinder()),
  ('layered', CarouselEffect.layered()),
  (
    'layered, darker',
    CarouselEffect.layered(fadeColor: Color(0xFF000000), balanceEnds: false),
  ),
  ('fan', CarouselEffect.fan()),
  ('arc', CarouselEffect.arc()),
  ('arc down, upright', CarouselEffect.arc(upward: false, tilt: false)),
  ('scatter', CarouselEffect.scatter()),
  ('circular reveal', CarouselEffect.circularReveal()),
  ('wipe', CarouselEffect.wipe()),
  ('curtain', CarouselEffect.curtain()),
  ('blinds', CarouselEffect.blinds()),
  ('liquid', CarouselEffect.liquid()),
  ('concentric', CarouselEffect.concentric()),
  ('clock', CarouselEffect.clock()),
  ('blocks', CarouselEffect.blocks()),
  ('blocks in order', CarouselEffect.blocks(random: false)),
  (
    'foreground to background, sliding',
    CarouselEffect.foregroundToBackground(drift: 1, endScale: 0.4),
  ),
  (
    'background to foreground, sliding',
    CarouselEffect.backgroundToForeground(drift: 1, startScale: 0.4),
  ),
];

CarouselLayout _layout(CarouselEffect effect) {
  const Size viewport = Size(400, 300);
  return CarouselLayout(
    viewportSize: viewport,
    itemSize: Size(viewport.width * effect.defaultViewportFraction, 300),
    spacing: 0,
    itemCount: 10,
    loop: true,
    alignment: CarouselAlignment.center,
    scrollDirection: Axis.horizontal,
    reversed: false,
  );
}

CarouselItemInfo _info(CarouselEffect effect, double delta) {
  return CarouselItemInfo(
    delta: delta,
    index: 0,
    virtualIndex: 0,
    page: -delta,
    layout: _layout(effect),
  );
}

/// Where the corners of the item end up on screen.
List<Offset> _corners(CarouselItemTransform transform, Size size) {
  final Matrix4 matrix = transform.matrix ?? Matrix4.identity();
  final List<Offset> corners = <Offset>[
    Offset(-size.width / 2, -size.height / 2),
    Offset(size.width / 2, -size.height / 2),
    Offset(size.width / 2, size.height / 2),
    Offset(-size.width / 2, size.height / 2),
  ];
  return <Offset>[
    for (final Offset corner in corners)
      MatrixUtils.transformPoint(matrix, corner),
  ];
}

bool _shown(CarouselItemTransform transform) =>
    transform.visible && transform.opacity > 0;

void main() {
  test('material layout sizes and places items by weight', () {
    const MaterialCarouselEffect effect = MaterialCarouselEffect(gap: 0);
    const CarouselLayout layout = CarouselLayout(
      viewportSize: Size(600, 300),
      itemSize: Size(300, 300),
      spacing: 0,
      itemCount: 6,
      loop: false,
      alignment: CarouselAlignment.center,
      scrollDirection: Axis.horizontal,
      reversed: false,
    );
    (double, double) placement(double delta, double page) {
      final CarouselItemTransform transform = effect.transform(
        CarouselItemInfo(
          delta: delta,
          index: 0,
          virtualIndex: 0,
          page: page,
          layout: layout,
        ),
      );
      final double center =
          MatrixUtils.transformPoint(transform.matrix!, Offset.zero).dx + 300;
      return (center, transform.clipPath!.getBounds().width);
    }

    // At rest: 300, 200 and 100 pixels wide, side by side from the left.
    expect(placement(0, 0).$1, closeTo(150, 1e-6));
    expect(placement(0, 0).$2, closeTo(300, 1e-6));
    expect(placement(1, 0).$1, closeTo(400, 1e-6));
    expect(placement(1, 0).$2, closeTo(200, 1e-6));
    expect(placement(2, 0).$1, closeTo(550, 1e-6));
    expect(placement(2, 0).$2, closeTo(100, 1e-6));

    // Halfway to the next item, the first one has shrunk to half its size
    // and the others have grown halfway to the next size.
    expect(placement(-0.5, 0.5).$2, closeTo(150, 1e-6));
    expect(placement(0.5, 0.5).$2, closeTo(250, 1e-6));
    expect(placement(1.5, 0.5).$2, closeTo(150, 1e-6));
    expect(placement(2.5, 0.5).$2, closeTo(50, 1e-6));
  });

  test('reveal shapes grow from nothing to the whole item', () {
    const Size size = Size(400, 300);
    final CarouselItemInfo info = _info(const CarouselEffect.wipe(), 0.5);
    // A grid of points inside the item, away from block and slat edges.
    final List<Offset> samples = <Offset>[
      for (int i = 0; i < 10; i++)
        for (int j = 0; j < 8; j++)
          Offset(-200 + 400 * (i + 0.53) / 10, -150 + 300 * (j + 0.47) / 8),
    ];
    double covered(Path path) =>
        samples.where(path.contains).length / samples.length;
    const List<RevealCarouselEffect> reveals = <RevealCarouselEffect>[
      CircularRevealCarouselEffect(),
      WipeCarouselEffect(),
      CurtainCarouselEffect(),
      BlindsCarouselEffect(),
      LiquidCarouselEffect(followPointer: false),
      ConcentricCarouselEffect(),
      ClockCarouselEffect(),
      BlocksCarouselEffect(),
      BlocksCarouselEffect(random: false),
    ];
    for (final RevealCarouselEffect effect in reveals) {
      final String name = '$effect';
      expect(covered(effect.revealPath(info, size, 0)), 0, reason: name);
      expect(covered(effect.revealPath(info, size, 1)), 1, reason: name);
      double last = 0;
      for (int step = 1; step < 20; step++) {
        final double now = covered(effect.revealPath(info, size, step / 20));
        expect(now, greaterThanOrEqualTo(last - 0.03), reason: '$name $step');
        last = now;
      }
    }
  });

  test('the concentric reveal covers half the item halfway through', () {
    const Size size = Size(400, 300);
    final CarouselItemInfo info = _info(const CarouselEffect.wipe(), 0.5);
    const ConcentricCarouselEffect effect =
        ConcentricCarouselEffect(origin: Offset(0.5, 0.5));
    for (final double progress in <double>[0.499, 0.501]) {
      final Path path = effect.revealPath(info, size, progress);
      expect(path.contains(const Offset(60, 100)), isTrue);
      expect(path.contains(const Offset(60, -100)), isTrue);
      expect(path.contains(const Offset(-60, 100)), isFalse);
      expect(path.contains(const Offset(-60, -100)), isFalse);
    }
  });

  test('the layered stack keeps neighbours behind the current item', () {
    const LayeredCarouselEffect effect = LayeredCarouselEffect();
    const CarouselLayout layout = CarouselLayout(
      viewportSize: Size(375, 300),
      itemSize: Size(315, 300),
      spacing: 0,
      itemCount: 6,
      loop: true,
      alignment: CarouselAlignment.center,
      scrollDirection: Axis.horizontal,
      reversed: false,
    );
    CarouselItemTransform at(double delta) => effect.transform(
          CarouselItemInfo(
            delta: delta,
            index: 0,
            virtualIndex: 0,
            page: -delta,
            layout: layout,
          ),
        );
    double centerX(CarouselItemTransform transform) =>
        MatrixUtils.transformPoint(transform.matrix!, Offset.zero).dx;
    double scaleOf(CarouselItemTransform transform) =>
        (MatrixUtils.transformPoint(transform.matrix!, const Offset(100, 0))
                .dx -
            centerX(transform)) /
        100;

    expect(centerX(at(1)), closeTo(0.19 * 315, 1e-6));
    expect(centerX(at(-1)), closeTo(-0.19 * 315, 1e-6));
    expect(centerX(at(2)), closeTo(0.32 * 315, 1e-6));
    // Items further away wait hidden behind the ones two places away.
    expect(centerX(at(2.6)), closeTo(0.32 * 315, 1e-6));
    expect(scaleOf(at(1)), closeTo(0.7, 1e-6));
    expect(scaleOf(at(2)), closeTo(0.5, 1e-6));
    expect(scaleOf(at(2.6)), closeTo(0.5, 1e-6));
    expect(at(1).shade, closeTo(0.5, 1e-9));
    expect(at(2).shade, closeTo(0.8, 1e-9));
    expect(at(3.2).visible, isFalse);
  });

  test('the layered stack stays centered at the ends of a carousel', () {
    const LayeredCarouselEffect effect = LayeredCarouselEffect();
    const CarouselLayout layout = CarouselLayout(
      viewportSize: Size(375, 300),
      itemSize: Size(315, 300),
      spacing: 0,
      itemCount: 7,
      loop: false,
      alignment: CarouselAlignment.center,
      scrollDirection: Axis.horizontal,
      reversed: false,
    );
    double shiftAt(double page) {
      final CarouselItemTransform transform = effect.transform(
        CarouselItemInfo(
          delta: 0,
          index: 0,
          virtualIndex: 0,
          page: page,
          layout: layout,
        ),
      );
      return MatrixUtils.transformPoint(transform.matrix!, Offset.zero).dx;
    }

    // With two items on each side, nothing moves.
    expect(shiftAt(3), closeTo(0, 1e-9));
    // At the first item the stack only reaches right, so it moves left; the
    // last item mirrors it.
    expect(shiftAt(0), lessThan(-5));
    expect(shiftAt(6), closeTo(-shiftAt(0), 1e-9));
    double previous = shiftAt(0);
    for (int step = 1; step <= 60; step++) {
      final double now = shiftAt(step / 20);
      expect((now - previous).abs(), lessThan(1), reason: 'page ${step / 20}');
      previous = now;
    }
  });

  test('uncover slides the current item off over the next one', () {
    const UncoverCarouselEffect effect = UncoverCarouselEffect();
    double x(double delta) => MatrixUtils.transformPoint(
          effect.transform(_info(effect, delta)).matrix!,
          Offset.zero,
        ).dx;

    // Halfway through, the leaving item has gone half a slot and the waiting
    // one moves at 0.3 of that speed, still a little dark.
    expect(x(-0.5), closeTo(-200, 1e-9));
    expect(x(0.5), closeTo(0.5 * 400 * 0.3, 1e-9));
    expect(effect.transform(_info(effect, 0.5)).shade, closeTo(0.15, 1e-9));
    expect(
      effect.paintOrder(_info(effect, -0.5)),
      greaterThan(effect.paintOrder(_info(effect, 0.5))),
    );
  });

  test('skew leans neighbours away from the middle', () {
    const SkewCarouselEffect effect = SkewCarouselEffect();
    double lean(double delta) {
      final Matrix4 matrix = effect.transform(_info(effect, delta)).matrix!;
      final Offset top = MatrixUtils.transformPoint(matrix, const Offset(0, -100));
      final Offset bottom =
          MatrixUtils.transformPoint(matrix, const Offset(0, 100));
      return top.dx - bottom.dx;
    }

    expect(lean(1), greaterThan(10));
    expect(lean(-1), lessThan(-10));
    expect(lean(0), closeTo(0, 1e-9));
  });

  testWidgets('the layered stack fades neighbours towards its color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 375,
            height: 200,
            child: UltimateCarousel(
              effect: const CarouselEffect.layered(),
              initialPage: 2,
              children: <Widget>[
                for (int i = 0; i < 5; i++)
                  const ColoredBox(color: Color(0xFF2196F3)),
              ],
            ),
          ),
        ),
      ),
    );
    final List<ColorFilter> filters = <ColorFilter>[
      for (final ColorFiltered widget
          in tester.widgetList<ColorFiltered>(find.byType(ColorFiltered)))
        widget.colorFilter,
    ];
    expect(
      filters,
      contains(
        ColorFilter.mode(
          const Color(0xFFFFFFFF).withAlpha(128),
          BlendMode.srcATop,
        ),
      ),
    );
  });

  for (final (String name, CarouselEffect effect) in allEffects) {
    group(name, () {
      test('draws the current item untouched', () {
        if (effect is MaterialCarouselEffect) {
          // Material layouts place items from the leading edge themselves;
          // see the dedicated test below.
          return;
        }
        final CarouselItemInfo info = _info(effect, 0);
        final CarouselItemTransform transform = effect.transform(info);
        expect(transform.visible, isTrue);
        expect(transform.opacity, closeTo(1, 1e-9));
        expect(transform.shade, closeTo(0, 1e-9));
        final List<Offset> corners = _corners(transform, info.layout.itemSize);
        final List<Offset> expected = _corners(
          CarouselItemTransform.identity,
          info.layout.itemSize,
        );
        for (int i = 0; i < 4; i++) {
          expect((corners[i] - expected[i]).distance, lessThan(0.5));
        }
      });

      test('moves smoothly', () {
        CarouselItemTransform? previous;
        List<Offset>? previousCorners;
        for (double d = -3; d <= 3; d += 0.005) {
          final CarouselItemInfo info = _info(effect, d);
          final CarouselItemTransform transform = effect.transform(info);
          expect(transform.opacity, inInclusiveRange(0, 1), reason: 'd=$d');
          expect(transform.shade, inInclusiveRange(0, 1), reason: 'd=$d');
          final List<Offset> corners = _corners(
            transform,
            info.layout.itemSize,
          );
          for (final Offset corner in corners) {
            expect(corner.dx.isFinite && corner.dy.isFinite, isTrue);
          }
          if (previous != null &&
              _shown(previous) &&
              _shown(transform) &&
              previousCorners != null) {
            for (int i = 0; i < 4; i++) {
              expect(
                (corners[i] - previousCorners[i]).distance,
                lessThan(40),
                reason: 'corner $i jumps near d=$d',
              );
            }
            expect(
              (transform.opacity - previous.opacity).abs(),
              lessThan(0.05),
              reason: 'opacity jumps near d=$d',
            );
          }
          previous = transform;
          previousCorners = corners;
        }
      });

      testWidgets('runs in every direction', (WidgetTester tester) async {
        for (final Axis axis in Axis.values) {
          for (final TextDirection direction in TextDirection.values) {
            final UltimateCarouselController controller =
                UltimateCarouselController();
            await tester.pumpWidget(
              Directionality(
                textDirection: direction,
                child: Center(
                  child: SizedBox(
                    width: 400,
                    height: 300,
                    child: UltimateCarousel.builder(
                      controller: controller,
                      effect: effect,
                      loop: true,
                      scrollDirection: axis,
                      itemCount: 6,
                      itemBuilder: (BuildContext context, int index) =>
                          ColoredBox(
                        color: Colors.primaries[index],
                        child: Center(child: Text('$index')),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final Offset drag = axis == Axis.horizontal
                ? const Offset(-12, 0)
                : const Offset(0, -12);
            final TestGesture gesture = await tester.startGesture(
              tester.getCenter(find.byType(UltimateCarousel)),
            );
            for (int i = 0; i < 20; i++) {
              await gesture.moveBy(drag);
              await tester.pump(const Duration(milliseconds: 16));
            }
            await gesture.up();
            await tester.pumpAndSettle();
            controller.animateToPage(4);
            await tester.pumpAndSettle();
            expect(controller.currentIndex, 4);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            controller.dispose();
          }
        }
      });
    });
  }
}
