import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_carousel/ultimate_carousel.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double width = 400,
  double height = 300,
}) {
  return Directionality(
    textDirection: direction,
    child: Center(
      child: SizedBox(width: width, height: height, child: child),
    ),
  );
}

List<Widget> _slides(int count) {
  return <Widget>[
    for (int i = 0; i < count; i++)
      ColoredBox(
        color: Colors.primaries[i % Colors.primaries.length],
        child: Center(child: Text('$i')),
      ),
  ];
}

void main() {
  testWidgets('shows the first item', (WidgetTester tester) async {
    await tester.pumpWidget(_host(UltimateCarousel(children: _slides(5))));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('3'), findsNothing);
  });

  testWidgets('a long drag moves to the next item',
      (WidgetTester tester) async {
    final List<(int, CarouselPageChangeReason)> changes =
        <(int, CarouselPageChangeReason)>[];
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          onPageChanged: (int index, CarouselPageChangeReason reason) =>
              changes.add((index, reason)),
          children: _slides(5),
        ),
      ),
    );
    await tester.drag(find.byType(UltimateCarousel), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
    expect(controller.page, 1);
    expect(changes, <(int, CarouselPageChangeReason)>[
      (1, CarouselPageChangeReason.user),
    ]);
  });

  testWidgets('a short slow drag springs back', (WidgetTester tester) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(UltimateCarousel(controller: controller, children: _slides(5))),
    );
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(UltimateCarousel)),
    );
    for (int i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-6, 0));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.page, 0);
  });

  testWidgets('a quick fling moves one item', (WidgetTester tester) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(UltimateCarousel(controller: controller, children: _slides(5))),
    );
    await tester.fling(
      find.byType(UltimateCarousel),
      const Offset(-80, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(controller.page, 1);
  });

  testWidgets('does not go before the first item', (WidgetTester tester) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(UltimateCarousel(controller: controller, children: _slides(5))),
    );
    await tester.drag(find.byType(UltimateCarousel), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(controller.page, 0);
  });

  testWidgets('loops from the first item to the last', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          loop: true,
          children: _slides(5),
        ),
      ),
    );
    await tester.drag(find.byType(UltimateCarousel), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 4);
    expect(controller.realPage, 4);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('controller methods move the carousel', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    final List<CarouselPageChangeReason> reasons = <CarouselPageChangeReason>[];
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          onPageChanged: (int index, CarouselPageChangeReason reason) =>
              reasons.add(reason),
          children: _slides(6),
        ),
      ),
    );
    controller.nextPage();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);

    controller.animateToPage(4);
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 4);

    controller.previousPage();
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 3);

    controller.jumpToPage(0);
    await tester.pump();
    expect(controller.currentIndex, 0);
    expect(find.text('0'), findsOneWidget);

    expect(
      reasons,
      everyElement(CarouselPageChangeReason.controller),
    );
  });

  testWidgets('a looping carousel takes the short way round', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          loop: true,
          children: _slides(10),
        ),
      ),
    );
    controller.animateToPage(9);
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 9);
    expect(controller.page, -1);
  });

  testWidgets('autoplay moves on after the interval', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    final List<(int, CarouselPageChangeReason)> changes =
        <(int, CarouselPageChangeReason)>[];
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          loop: true,
          autoPlay: const CarouselAutoPlay(
            interval: Duration(seconds: 2),
            animationDuration: Duration(milliseconds: 300),
          ),
          onPageChanged: (int index, CarouselPageChangeReason reason) =>
              changes.add((index, reason)),
          children: _slides(3),
        ),
      ),
    );
    expect(controller.isAutoPlaying, isTrue);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 2);
    expect(changes.map(((int, CarouselPageChangeReason) c) => c.$2),
        everyElement(CarouselPageChangeReason.autoPlay));

    controller.stopAutoPlay();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 2);
  });

  testWidgets('autoplay pauses while the carousel is pressed', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          autoPlay: const CarouselAutoPlay(interval: Duration(seconds: 1)),
          children: _slides(3),
        ),
      ),
    );
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(UltimateCarousel)),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(controller.currentIndex, 0);
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
  });

  testWidgets('autoplay rewinds at the end of a finite carousel', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          initialPage: 2,
          autoPlay: const CarouselAutoPlay(interval: Duration(seconds: 1)),
          children: _slides(3),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 0);
  });

  testWidgets('scroll autoplay glides at a steady speed', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    final List<CarouselPageChangeReason> reasons = <CarouselPageChangeReason>[];
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          loop: true,
          viewportFraction: 0.5,
          snapping: CarouselSnapping.none,
          autoPlay: const CarouselAutoPlay.scroll(speed: 100),
          onPageChanged: (int index, CarouselPageChangeReason reason) =>
              reasons.add(reason),
          children: _slides(6),
        ),
      ),
    );
    // Items are 200 pixels wide, so 100 pixels a second is half an item.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(controller.realPage, closeTo(1, 0.05));
    expect(reasons, isNotEmpty);
    expect(reasons, everyElement(CarouselPageChangeReason.autoPlay));

    // Pressing stops it where it is, and letting go glides on.
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(UltimateCarousel)),
    );
    await tester.pump(const Duration(seconds: 1));
    final double paused = controller.realPage;
    await tester.pump(const Duration(seconds: 1));
    expect(controller.realPage, paused);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.realPage, closeTo(paused + 0.5, 0.05));
  });

  testWidgets('scroll autoplay can stop at the end of a finite carousel', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          autoPlay: const CarouselAutoPlay.scroll(
            speed: 400,
            end: CarouselAutoPlayEnd.stop,
          ),
          children: _slides(3),
        ),
      ),
    );
    // Items are 400 pixels wide, so the glide takes a second per item.
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(controller.realPage, 2);
    expect(controller.isAutoPlaying, isFalse);
  });

  test('scroll autoplay settings keep their speed', () {
    const CarouselAutoPlay scroll = CarouselAutoPlay.scroll(speed: 30);
    expect(scroll.speed, 30);
    expect(const CarouselAutoPlay().speed, isNull);
    expect(scroll, isNot(const CarouselAutoPlay()));
    expect(scroll.copyWith(reverse: true).speed, 30);
    expect(scroll.copyWith(reverse: true).reverse, isTrue);
  });

  testWidgets('vertical carousels move with vertical drags', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          scrollDirection: Axis.vertical,
          children: _slides(4),
        ),
      ),
    );
    await tester.drag(find.byType(UltimateCarousel), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 0);
    await tester.drag(find.byType(UltimateCarousel), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
  });

  testWidgets('right-to-left carousels move the other way', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(controller: controller, children: _slides(4)),
        direction: TextDirection.rtl,
      ),
    );
    await tester.drag(find.byType(UltimateCarousel), const Offset(250, 0));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
  });

  testWidgets('arrow keys move a focused carousel', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          focusNode: focusNode,
          children: _slides(4),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 2);
  });

  testWidgets('tapping an item reports it and can move to it', (
    WidgetTester tester,
  ) async {
    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    final List<int> taps = <int>[];
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          viewportFraction: 0.4,
          animateToTappedItem: true,
          onItemTap: taps.add,
          children: _slides(4),
        ),
      ),
    );
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    expect(taps, <int>[1]);
    expect(controller.currentIndex, 1);
  });

  testWidgets('handles zero and one item', (WidgetTester tester) async {
    await tester
        .pumpWidget(_host(UltimateCarousel(children: const <Widget>[])));
    expect(tester.takeException(), isNull);

    final UltimateCarouselController controller = UltimateCarouselController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        UltimateCarousel(
          controller: controller,
          loop: true,
          autoPlay: const CarouselAutoPlay(),
          children: _slides(1),
        ),
      ),
    );
    await tester.drag(find.byType(UltimateCarousel), const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(controller.currentIndex, 0);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('keeps item state while items stay on screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        UltimateCarousel.builder(
          itemCount: 3,
          viewportFraction: 0.6,
          effect: const CarouselEffect.coverflow(),
          itemBuilder: (BuildContext context, int index) =>
              _Counter(key: ValueKey<int>(index)),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey<int>(0)));
    await tester.pump();
    expect(find.text('taps: 1'), findsOneWidget);
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(UltimateCarousel)),
    );
    for (int i = 0; i < 8; i++) {
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('taps: 1'), findsOneWidget);
  });

  testWidgets('sizes itself with aspectRatio when unconstrained', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: UltimateCarousel(aspectRatio: 2, children: _slides(3)),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(UltimateCarousel)), const Size(320, 160));
  });
}

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _taps++),
      child: ColoredBox(
        color: const Color(0xFF2196F3),
        child: Center(child: Text('taps: $_taps')),
      ),
    );
  }
}
