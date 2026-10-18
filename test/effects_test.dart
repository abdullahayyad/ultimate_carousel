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
  ('fan', CarouselEffect.fan()),
  ('arc', CarouselEffect.arc()),
  ('arc down, upright', CarouselEffect.arc(upward: false, tilt: false)),
  ('scatter', CarouselEffect.scatter()),
  ('circular reveal', CarouselEffect.circularReveal()),
  ('wipe', CarouselEffect.wipe()),
  ('curtain', CarouselEffect.curtain()),
  ('blinds', CarouselEffect.blinds()),
  ('liquid', CarouselEffect.liquid()),
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
