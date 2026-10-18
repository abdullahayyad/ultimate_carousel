// Renders the animation frames for the README's GIFs.
//
// This is not part of the test suite. The GIFs workflow runs it with
// `flutter test tool/gifs/render_test.dart`, then turns the frames into GIFs
// with ffmpeg. Set ROBOTO_FONT and ICON_FONT to font files so text and icons
// render with real glyphs.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultimate_carousel/ultimate_carousel.dart';

/// The effects that get a GIF, with the file name for each.
const List<(String, CarouselEffect)> gifEffects = <(String, CarouselEffect)>[
  ('slide', CarouselEffect.slide()),
  ('fade', CarouselEffect.fade(zoom: 1.15)),
  ('enlarge', CarouselEffect.enlarge()),
  ('zoom_out', CarouselEffect.zoomOut()),
  ('depth', CarouselEffect.depth()),
  ('parallax', CarouselEffect.parallax()),
  ('stack', CarouselEffect.stack()),
  ('accordion', CarouselEffect.accordion()),
  ('rotate', CarouselEffect.rotate()),
  ('foreground_to_background', CarouselEffect.foregroundToBackground()),
  ('background_to_foreground', CarouselEffect.backgroundToForeground()),
  ('focus', CarouselEffect.focus()),
  ('overlap', CarouselEffect.overlap()),
  ('cube', CarouselEffect.cube()),
  ('cube_inside', CarouselEffect.cube(inside: true)),
  ('flip', CarouselEffect.flip()),
  ('coverflow', CarouselEffect.coverflow()),
  ('tablet', CarouselEffect.tablet()),
  ('ring', CarouselEffect.ring(itemsOnRing: 6)),
  ('ring_tilted', CarouselEffect.ring(faceViewer: true, tilt: 0.35)),
  ('wheel', CarouselEffect.wheel()),
  ('cylinder', CarouselEffect.cylinder()),
  ('helix', CarouselEffect.helix()),
  ('page_turn', CarouselEffect.pageTurn()),
  ('tunnel', CarouselEffect.tunnel()),
  ('material', CarouselEffect.material()),
  ('material_hero', CarouselEffect.material(weights: <int>[1, 7, 1])),
  ('deck', CarouselEffect.deck()),
  ('tinder', CarouselEffect.tinder()),
  ('fan', CarouselEffect.fan()),
  ('arc', CarouselEffect.arc()),
  ('scatter', CarouselEffect.scatter()),
  ('circular_reveal', CarouselEffect.circularReveal()),
  ('wipe', CarouselEffect.wipe()),
  ('curtain', CarouselEffect.curtain()),
  ('blinds', CarouselEffect.blinds()),
  ('liquid', CarouselEffect.liquid(followPointer: false)),
];

const Color _dot = Color(0x55FFFFFF);
const Color _active = Color(0xFFB794F6);

/// The indicators shown in the indicators animation.
const List<(String, IndicatorEffect)> gifIndicators =
    <(String, IndicatorEffect)>[
  ('worm', IndicatorEffect.worm(dotColor: _dot, activeDotColor: _active)),
  (
    'worm(style: WormStyle.thin)',
    IndicatorEffect.worm(
      style: WormStyle.thin,
      dotColor: _dot,
      activeDotColor: _active,
    ),
  ),
  (
    'expandingDots',
    IndicatorEffect.expandingDots(dotColor: _dot, activeDotColor: _active),
  ),
  (
    'jumpingDot',
    IndicatorEffect.jumpingDot(
      verticalOffset: 8,
      dotColor: _dot,
      activeDotColor: _active,
    ),
  ),
  (
    'scrollingDots',
    IndicatorEffect.scrollingDots(dotColor: _dot, activeDotColor: _active),
  ),
  ('slide', IndicatorEffect.slide(dotColor: _dot, activeDotColor: _active)),
  ('scale', IndicatorEffect.scale(dotColor: _dot, activeDotColor: _active)),
  ('swap', IndicatorEffect.swap(dotColor: _dot, activeDotColor: _active)),
  (
    'swap(style: SwapStyle.zRotation)',
    IndicatorEffect.swap(
      style: SwapStyle.zRotation,
      dotColor: _dot,
      activeDotColor: _active,
    ),
  ),
  (
    'colorTransition',
    IndicatorEffect.colorTransition(dotColor: _dot, activeDotColor: _active),
  ),
  ('fill', IndicatorEffect.fill(dotColor: _dot, activeDotColor: _active)),
  (
    'segments',
    IndicatorEffect.segments(dotColor: _dot, activeDotColor: _active),
  ),
  ('line', IndicatorEffect.line(trackColor: _dot, activeColor: _active)),
  (
    'fraction',
    IndicatorEffect.fraction(
      style: TextStyle(
        fontFamily: 'Roboto',
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
];

/// The effects in the big animation at the top of the README.
const List<String> heroEffects = <String>[
  'coverflow',
  'cube',
  'ring_tilted',
  'deck',
  'page_turn',
  'liquid',
];

const Size _tileSize = Size(360, 220);
const Color _background = Color(0xFF14111F);

const List<List<Color>> _palettes = <List<Color>>[
  <Color>[Color(0xFF7F5AF0), Color(0xFF2CB1BC)],
  <Color>[Color(0xFFFF8906), Color(0xFFE53170)],
  <Color>[Color(0xFF2CB67D), Color(0xFF0F766E)],
  <Color>[Color(0xFF3DA9FC), Color(0xFF5A4FCF)],
  <Color>[Color(0xFFF25F4C), Color(0xFF7A1F5C)],
  <Color>[Color(0xFFFFC107), Color(0xFFFF6D00)],
];

const List<IconData> _icons = <IconData>[
  Icons.landscape_rounded,
  Icons.local_cafe_rounded,
  Icons.music_note_rounded,
  Icons.flight_takeoff_rounded,
  Icons.favorite_rounded,
  Icons.wb_sunny_rounded,
];

const int _hold = 6;
const int _move = 18;

/// Frames per GIF: four moves, each after a short rest.
const int _frameCount = 4 * (_hold + _move);

/// The page of the carousel at [frame]: it rests, moves forward twice, then
/// back twice, so the animation loops without a jump.
double _pageAt(int frame) {
  const List<double> stops = <double>[0, 1, 2, 1, 0];
  const int segment = _hold + _move;
  final int step = frame ~/ segment;
  final int within = frame % segment;
  final double from = stops[step];
  final double to = stops[step + 1];
  if (within < _hold) {
    return from;
  }
  final double t = Curves.easeInOutCubic.transform((within - _hold) / _move);
  return from + (to - from) * t;
}

Future<void> _loadFonts(WidgetTester tester) async {
  Future<void> load(String family, String? path) async {
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return;
    }
    final List<int> bytes = await File(path).readAsBytes();
    final FontLoader loader = FontLoader(family)
      ..addFont(
        Future<ByteData>.value(
          ByteData.view(Uint8List.fromList(bytes).buffer),
        ),
      );
    await loader.load();
  }

  await tester.runAsync(() async {
    await load('Roboto', Platform.environment['ROBOTO_FONT']);
    await load('MaterialIcons', Platform.environment['ICON_FONT']);
  });
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  File file,
) async {
  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage();
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await file.writeAsBytes(data!.buffer.asUint8List());
  });
}

class _Card extends StatelessWidget {
  const _Card(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = _palettes[index % _palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0x22FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Icon(
                    _icons[index % _icons.length],
                    color: Colors.white,
                    size: 26,
                  ),
                  Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontSize: 40,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _tile(CarouselEffect effect, UltimateCarouselController controller) {
  return ColoredBox(
    color: _background,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: UltimateCarousel.builder(
        controller: controller,
        effect: effect,
        loop: true,
        itemCount: 6,
        enableKeyboard: false,
        clipBehavior: Clip.none,
        itemBuilder: (BuildContext context, int index) => _Card(index),
      ),
    ),
  );
}

Widget _frame(GlobalKey key, Size size, Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: key,
        child: ClipRect(
          child: SizedBox.fromSize(size: size, child: child),
        ),
      ),
    ),
  );
}

void main() {
  final Directory output = Directory('build/gif_frames');

  setUpAll(() {
    if (output.existsSync()) {
      output.deleteSync(recursive: true);
    }
  });

  for (final (String name, CarouselEffect effect) in gifEffects) {
    testWidgets('frames for $name', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _loadFonts(tester);
      final Directory folder = Directory('${output.path}/$name')
        ..createSync(recursive: true);
      final UltimateCarouselController controller =
          UltimateCarouselController();
      addTearDown(controller.dispose);
      final GlobalKey key = GlobalKey();
      await tester.pumpWidget(_frame(key, _tileSize, _tile(effect, controller)));
      await tester.pump();
      for (int frame = 0; frame < _frameCount; frame++) {
        controller.jumpTo(_pageAt(frame));
        await tester.pump();
        await _capture(
          tester,
          key,
          File('${folder.path}/${frame.toString().padLeft(4, '0')}.png'),
        );
      }
    });
  }

  testWidgets('frames for the indicators', (WidgetTester tester) async {
    const double rowHeight = 34;
    final Size size = Size(520, rowHeight * gifIndicators.length + 24);
    tester.view.physicalSize = Size(800, math.max(size.height, 600));
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _loadFonts(tester);
    final Directory folder = Directory('${output.path}/indicators')
      ..createSync(recursive: true);
    final GlobalKey key = GlobalKey();
    final ValueNotifier<double> page = ValueNotifier<double>(0);
    addTearDown(page.dispose);
    await tester.pumpWidget(
      _frame(
        key,
        size,
        ColoredBox(
          color: _background,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: ValueListenableBuilder<double>(
              valueListenable: page,
              builder: (BuildContext context, double value, Widget? child) {
                return Column(
                  children: <Widget>[
                    for (final (String name, IndicatorEffect effect)
                        in gifIndicators)
                      SizedBox(
                        height: rowHeight,
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 270,
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xB3FFFFFF),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            CarouselIndicator.value(
                              page: value,
                              count: 6,
                              effect: effect,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    for (int frame = 0; frame < _frameCount; frame++) {
      page.value = _pageAt(frame);
      await tester.pump();
      await _capture(
        tester,
        key,
        File('${folder.path}/${frame.toString().padLeft(4, '0')}.png'),
      );
    }
  });

  testWidgets('frames for the hero', (WidgetTester tester) async {
    const int columns = 3;
    final int rows = (heroEffects.length / columns).ceil();
    final Size size = Size(
      _tileSize.width * columns,
      _tileSize.height * rows,
    );
    tester.view.physicalSize = Size(
      math.max(size.width, 800),
      math.max(size.height, 600),
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _loadFonts(tester);
    final Directory folder = Directory('${output.path}/hero')
      ..createSync(recursive: true);
    final List<UltimateCarouselController> controllers =
        <UltimateCarouselController>[
      for (int i = 0; i < heroEffects.length; i++)
        UltimateCarouselController(),
    ];
    addTearDown(() {
      for (final UltimateCarouselController controller in controllers) {
        controller.dispose();
      }
    });
    final Map<String, CarouselEffect> byName = <String, CarouselEffect>{
      for (final (String name, CarouselEffect effect) in gifEffects)
        name: effect,
    };
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key,
        size,
        Wrap(
          children: <Widget>[
            for (int i = 0; i < heroEffects.length; i++)
              SizedBox.fromSize(
                size: _tileSize,
                child: _tile(byName[heroEffects[i]]!, controllers[i]),
              ),
          ],
        ),
      ),
    );
    await tester.pump();
    for (int frame = 0; frame < _frameCount; frame++) {
      for (int i = 0; i < controllers.length; i++) {
        // Stagger the tiles so they do not all move at once.
        final int shifted = (frame + i * 9) % _frameCount;
        controllers[i].jumpTo(_pageAt(shifted));
      }
      await tester.pump();
      await _capture(
        tester,
        key,
        File('${folder.path}/${frame.toString().padLeft(4, '0')}.png'),
      );
    }
  });
}
