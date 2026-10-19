import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_carousel/ultimate_carousel.dart';

const List<(String, IndicatorEffect)> allIndicators =
    <(String, IndicatorEffect)>[
  ('worm', IndicatorEffect.worm()),
  ('thin worm', IndicatorEffect.worm(style: WormStyle.thin)),
  ('underground worm', IndicatorEffect.worm(style: WormStyle.underground)),
  (
    'thin underground worm',
    IndicatorEffect.worm(style: WormStyle.thinUnderground),
  ),
  ('expanding dots', IndicatorEffect.expandingDots()),
  ('jumping dot', IndicatorEffect.jumpingDot(verticalOffset: 6)),
  ('scrolling dots', IndicatorEffect.scrollingDots()),
  (
    'scrolling dots, fixed center',
    IndicatorEffect.scrollingDots(fixedCenter: true),
  ),
  ('slide', IndicatorEffect.slide()),
  ('slide underneath', IndicatorEffect.slide(underneath: true)),
  ('scale', IndicatorEffect.scale()),
  ('swap', IndicatorEffect.swap()),
  ('swap y', IndicatorEffect.swap(style: SwapStyle.yRotation)),
  ('swap z', IndicatorEffect.swap(style: SwapStyle.zRotation)),
  ('color transition', IndicatorEffect.colorTransition()),
  ('fill', IndicatorEffect.fill()),
  ('segments', IndicatorEffect.segments()),
  ('line', IndicatorEffect.line()),
  ('line fill', IndicatorEffect.line(fill: true)),
  ('fraction', IndicatorEffect.fraction()),
  ('drop', IndicatorEffect.drop()),
  ('growing drop', IndicatorEffect.drop(dropScale: 1.3)),
  ('wave', IndicatorEffect.wave()),
  ('radio', IndicatorEffect.radio()),
  ('filled radio', IndicatorEffect.radio(paintStyle: PaintingStyle.fill)),
];

void main() {
  for (final (String name, IndicatorEffect effect) in allIndicators) {
    test('$name paints every position', () {
      for (int count = 1; count <= 12; count++) {
        final Size size = effect.calculateSize(count);
        expect(size.width, greaterThan(0));
        expect(size.height, greaterThan(0));
        for (double page = 0; page <= count; page += 0.05) {
          final ui.PictureRecorder recorder = ui.PictureRecorder();
          effect.paint(Canvas(recorder), size, page, count);
          recorder.endRecording().dispose();
        }
      }
    });
  }

  testWidgets('follows the carousel and moves it on tap', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 400,
              height: 200,
              child: UltimateCarousel(
                controller: controller,
                children: <Widget>[
                  for (int i = 0; i < 5; i++) Text('$i'),
                ],
              ),
            ),
            CarouselIndicator(
              key: const ValueKey<String>('dots'),
              controller: controller,
              effect: const IndicatorEffect.slide(
                dotWidth: 10,
                spacing: 10,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    final Finder dots = find.byKey(const ValueKey<String>('dots'));
    expect(tester.getSize(dots), const Size(90, 10));

    final Offset topLeft = tester.getTopLeft(dots);
    await tester.tapAt(topLeft + const Offset(65, 5));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 3);
  });

  testWidgets('works with a fixed page', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: CarouselIndicator.value(
            page: 2.5,
            count: 6,
            axis: Axis.vertical,
            effect: IndicatorEffect.expandingDots(),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(CarouselIndicator), findsOneWidget);
  });
}
