# ultimate_carousel

[![pub package](https://img.shields.io/pub/v/ultimate_carousel.svg)](https://pub.dev/packages/ultimate_carousel)
[![CI](https://github.com/abdullahayyad/ultimate_carousel/actions/workflows/ci.yml/badge.svg)](https://github.com/abdullahayyad/ultimate_carousel/actions/workflows/ci.yml)
[![Live demo](https://img.shields.io/badge/demo-try%20it%20live-7F5AF0)](https://abdullahayyad.github.io/ultimate_carousel/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/abdullahayyad/ultimate_carousel/blob/main/LICENSE)

**Every Flutter carousel transition in one package.** 38 transitions and 15
animated page indicators behind a single widget, with no dependencies besides
Flutter.

![Six carousels showing the cover flow, cube, ring, deck, page turn and liquid transitions](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/hero.gif)

**[▶ Try every effect in your browser](https://abdullahayyad.github.io/ultimate_carousel/)**

## Why ultimate_carousel?

It started with a survey of 352 carousel, slider, swiper, card stack, page
transformer and page indicator packages on pub.dev. Every distinct transition
they offer was collected and written again from scratch behind one API:

- **One widget, every look.** Go from a plain slide to a cube, cover flow, 3D
  ring, card deck or liquid reveal by changing one line.
- **Every feature works with every effect:** infinite looping, autoplay,
  vertical and right-to-left layouts, snapping physics, keyboard, mouse wheel,
  trackpad and screen readers.
- **Animated indicators** that follow the carousel: worm, expanding dots,
  jumping dot, drop, scrolling dots and more.
- **Your own effects** in a few lines with `CarouselEffect.custom`.
- **Pure Flutter**: no dependencies; works on Android, iOS, web, Windows,
  macOS and Linux.

## Install

```yaml
dependencies:
  ultimate_carousel: ^0.1.0
```

## Quick start

```dart
import 'package:ultimate_carousel/ultimate_carousel.dart';

final controller = UltimateCarouselController();

Column(
  children: [
    UltimateCarousel(
      controller: controller,
      effect: const CarouselEffect.coverflow(),
      loop: true,
      autoPlay: const CarouselAutoPlay(),
      height: 240,
      children: [
        for (final url in imageUrls) Image.network(url, fit: BoxFit.cover),
      ],
    ),
    const SizedBox(height: 16),
    CarouselIndicator(
      controller: controller,
      effect: const IndicatorEffect.expandingDots(),
    ),
  ],
)
```

For long lists use `UltimateCarousel.builder(itemCount: …, itemBuilder: …)`:
only the items on screen are built.

## Transitions

Pass any of these as `effect:`. Each one has options; the API docs list them.

### Slides and fades

| | | |
|:-:|:-:|:-:|
| ![slide](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/slide.gif)<br>`CarouselEffect.slide()` | ![fade](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/fade.gif)<br>`CarouselEffect.fade(zoom: 1.15)` | ![enlarge](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/enlarge.gif)<br>`CarouselEffect.enlarge()` |
| ![zoom out](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/zoom_out.gif)<br>`CarouselEffect.zoomOut()` | ![depth](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/depth.gif)<br>`CarouselEffect.depth()` | ![parallax](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/parallax.gif)<br>`CarouselEffect.parallax()` |
| ![stack](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/stack.gif)<br>`CarouselEffect.stack()` | ![accordion](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/accordion.gif)<br>`CarouselEffect.accordion()` | ![rotate](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/rotate.gif)<br>`CarouselEffect.rotate()` |
| ![foreground to background](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/foreground_to_background.gif)<br>`CarouselEffect.foregroundToBackground()` | ![background to foreground](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/background_to_foreground.gif)<br>`CarouselEffect.backgroundToForeground()` | ![focus](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/focus.gif)<br>`CarouselEffect.focus()` |
| ![overlap](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/overlap.gif)<br>`CarouselEffect.overlap()` | | |

Also: `fade(crossFade: true)`, `enlarge(strategy: CarouselEnlargeStrategy.height)`
and `.zoom`, `zoomIn()` and `rotate(fromTop: true)`.

### 3D

| | | |
|:-:|:-:|:-:|
| ![cube](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/cube.gif)<br>`CarouselEffect.cube()` | ![cube inside](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/cube_inside.gif)<br>`CarouselEffect.cube(inside: true)` | ![flip](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/flip.gif)<br>`CarouselEffect.flip()` |
| ![coverflow](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/coverflow.gif)<br>`CarouselEffect.coverflow()` | ![tablet](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/tablet.gif)<br>`CarouselEffect.tablet()` | ![ring](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/ring.gif)<br>`CarouselEffect.ring(itemsOnRing: 6)` |
| ![tilted ring](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/ring_tilted.gif)<br>`CarouselEffect.ring(faceViewer: true, tilt: 0.45)` | ![wheel](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/wheel.gif)<br>`CarouselEffect.wheel()` | ![cylinder](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/cylinder.gif)<br>`CarouselEffect.cylinder()` |
| ![helix](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/helix.gif)<br>`CarouselEffect.helix()` | ![page turn](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/page_turn.gif)<br>`CarouselEffect.pageTurn()` | ![tunnel](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/tunnel.gif)<br>`CarouselEffect.tunnel()` |

Also: `flip(vertical: true)` and `ring(showBackItems: true)`. A tilted ring
rises above its items, so give it room: the animation above uses
`viewportFraction: 0.42`, `clipBehavior: Clip.none` and space above the
carousel.

### Material 3

| | |
|:-:|:-:|
| ![multi-browse](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/material.gif)<br>`CarouselEffect.material()` | ![centered hero](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/material_hero.gif)<br>`CarouselEffect.material(weights: [1, 7, 1])` |

The `weights` pick the layout, as in Flutter's `CarouselView.weighted`:
`[3, 2, 1]` multi-browse, `[7, 1]` hero, `[1, 7, 1]` centered hero and `[1]`
full screen. Items are masked, not squeezed: their content keeps its size and
the rounded mask around it changes. For the uncontained layout, use the plain
slide with `alignment: CarouselAlignment.start` and a `viewportFraction` below
1.

### Cards

| | | |
|:-:|:-:|:-:|
| ![deck](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/deck.gif)<br>`CarouselEffect.deck()` | ![tinder](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/tinder.gif)<br>`CarouselEffect.tinder()` | ![fan](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/fan.gif)<br>`CarouselEffect.fan()` |
| ![arc](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/arc.gif)<br>`CarouselEffect.arc()` | ![scatter](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/scatter.gif)<br>`CarouselEffect.scatter()` | |

Also: `arc(upward: false)` for a rainbow and `arc(tilt: false)` to keep the
cards upright.

### Reveals

| | | |
|:-:|:-:|:-:|
| ![circular reveal](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/circular_reveal.gif)<br>`CarouselEffect.circularReveal()` | ![liquid](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/liquid.gif)<br>`CarouselEffect.liquid()` | ![concentric](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/concentric.gif)<br>`CarouselEffect.concentric()` |
| ![wipe](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/wipe.gif)<br>`CarouselEffect.wipe()` | ![curtain](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/curtain.gif)<br>`CarouselEffect.curtain()` | ![blinds](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/blinds.gif)<br>`CarouselEffect.blinds()` |
| ![clock](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/clock.gif)<br>`CarouselEffect.clock()` | ![blocks](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/blocks.gif)<br>`CarouselEffect.blocks()` | |

`circularReveal(followPointer: true)` and `liquid()` follow the finger, and
`blocks(random: false)` sweeps the blocks in diagonally.

## Indicators

![The page indicators, animating](https://raw.githubusercontent.com/abdullahayyad/ultimate_carousel/readme-assets/indicators.gif)

```dart
CarouselIndicator(
  controller: controller,
  effect: const IndicatorEffect.worm(
    dotColor: Colors.white24,
    activeDotColor: Colors.white,
  ),
)
```

Effects: `worm` (styles `normal`, `thin`, `underground`, `thinUnderground`),
`expandingDots`, `jumpingDot`, `drop`, `wave`, `radio`, `scrollingDots`,
`slide`, `scale`, `swap` (styles `normal`, `yRotation`, `zRotation`),
`colorTransition`, `fill`, `segments` (story bars), `line` and `fraction`
("3 / 10").

Tapping a dot moves the carousel; set `axis: Axis.vertical` for a vertical
carousel. To drive an indicator yourself, for example from a `PageView`, use
`CarouselIndicator.value(page: …, count: …)`.

## Options

| Option | Default | What it does |
|---|---|---|
| `effect` | `slide()` | The transition. |
| `loop` | `false` | Wrap around from the last item to the first. |
| `autoPlay` | off | `CarouselAutoPlay(interval:, animationDuration:, curve:, reverse:, pauseOnHover:, end:)`. |
| `scrollDirection` | horizontal | `Axis.vertical` for vertical carousels. |
| `reverse` | `false` | The next item comes from the other side. Right-to-left text reverses horizontal carousels on its own. |
| `viewportFraction` | effect's choice | How much of the carousel one item takes. |
| `spacing` | `0` | The gap between items. |
| `alignment` | center | Where the current item sits: `start`, `center` or `end`. |
| `height`, `aspectRatio` | none, 16:9 | The size when the parent does not set one. |
| `initialPage` | `0` | The first item shown. |
| `snapping` | single page | `multiPage` for long flings, `none` for free gliding. |
| `bounce` | platform | Stretch past the ends of a carousel that does not loop. |
| `onPageChanged` | | `(index, reason)` with `user`, `autoPlay` or `controller`. |
| `onScrolled` | | The position every frame, for custom animations. |
| `onItemTap`, `animateToTappedItem` | | Tap callbacks; tapping a side item can bring it to the center. |
| `enableDrag`, `dragDevices` | on, all | Who can drag the carousel, mouse included. |
| `enableKeyboard`, `focusNode`, `autofocus` | on | Arrow keys, Page Up/Down, Home and End. |
| `enableMouseWheel` | on | The mouse wheel and trackpad. |
| `animationDuration`, `animationCurve` | 450 ms, ease out | Moves started by code, keys and taps. |
| `clipBehavior` | hard edge | `Clip.none` lets 3D effects spill over the edges. |
| `semanticLabel` | | A label for screen readers. |

## Controller

```dart
final controller = UltimateCarouselController();

controller.nextPage();
controller.previousPage();
controller.animateToPage(3); // A looping carousel takes the short way round.
controller.jumpToPage(0);
controller.jumpTo(2.5); // Halfway between items, for scrubbing or syncing.
controller.startAutoPlay();
controller.stopAutoPlay();

controller.currentIndex; // The item in the center.
controller.realPage; // The position between 0 and itemCount, every frame.
```

The controller is a `ChangeNotifier`, so you can listen to it or rebuild with
`ListenableBuilder`.

## Animate item content

Every item can read its position with `CarouselItemScope.of(context)`, for
example to fade a caption as its slide leaves:

```dart
Builder(
  builder: (context) {
    final info = CarouselItemScope.of(context);
    return Opacity(
      opacity: 1 - info.distance.clamp(0.0, 1.0),
      child: const Text('Caption'),
    );
  },
)
```

`CarouselParallax` moves its child more slowly than the item around it, which
looks great on background images:

```dart
CarouselParallax(child: Image.network(url, fit: BoxFit.cover))
```

## Make your own effect

An effect says how to draw an item for its distance from the current page,
`info.delta` (0 is the current item, -1 the previous one, 1 the next one).
Write it for a horizontal, left-to-right carousel; the carousel turns and
mirrors it for vertical and right-to-left layouts.

```dart
final swing = CarouselEffect.custom(
  transform: (info) {
    final matrix = ItemMatrix()
      ..rotateZ(info.delta * 0.3, pivot: const Offset(0, 400))
      ..translate(info.delta * info.layout.slotExtent * 0.8);
    return CarouselItemTransform(
      matrix: matrix.value,
      opacity: 1 - info.distance.clamp(0.0, 1.0) * 0.4,
    );
  },
);
```

`CarouselItemTransform` can also clip, shade, blur and move the content
inside an item. For full control, subclass `CarouselEffect` and override
`paintOrder`, `itemsPerSide` or `decorate`. To make a new reveal, subclass
`RevealCarouselEffect` and return the visible shape from `revealPath`.

## Accessibility

- Screen readers hear "3 / 10" and can swipe through items; only the current
  item is read out.
- The arrow keys and Page Up/Down work while the carousel has focus, and so do
  Home and End when it does not loop.
- Autoplay pauses while a pointer is down or hovering, while the app is in the
  background, and while the system asks apps to reduce motion.

## Credits

The transitions were collected from the packages below and written again from
scratch here, without copying their code. Thanks to their authors for the
ideas.

| Package | Ideas | License |
|---|---|---|
| [carousel_slider](https://pub.dev/packages/carousel_slider) | enlarge strategies, autoplay, looping | MIT |
| [flutter_carousel_slider](https://pub.dev/packages/flutter_carousel_slider) | cube, accordion, depth, stack, tablet, rotate, zoom, flip, parallax, foreground and background transforms | BSD-3-Clause, now MIT |
| [flutter_carousel_widget](https://pub.dev/packages/flutter_carousel_widget) | composable effects, wave and fill indicators, autoplay pausing | MIT |
| [card_swiper](https://pub.dev/packages/card_swiper), [flutter_swiper](https://pub.dev/packages/flutter_swiper) | stack and tinder layouts, drop indicator | MIT |
| [transformer_page_view](https://pub.dev/packages/transformer_page_view) | page transformers | none stated (ideas only) |
| [smooth_page_indicator](https://pub.dev/packages/smooth_page_indicator) | worm, expanding, jumping, scrolling, slide, scale, swap and color indicators | MIT |
| [dots_indicator](https://pub.dev/packages/dots_indicator), [page_view_indicators](https://pub.dev/packages/page_view_indicators) | dot sizing, radio rings | MIT, BSD-2-Clause |
| [liquid_swipe](https://pub.dev/packages/liquid_swipe) | liquid reveal | Apache-2.0 |
| [concentric_transition](https://pub.dev/packages/concentric_transition) | concentric reveal | MIT |
| [cube_transition](https://pub.dev/packages/cube_transition) | shaded cube | Apache-2.0 |
| [flutter_3d_carousel](https://pub.dev/packages/flutter_3d_carousel), [flutter_gallery_3d](https://pub.dev/packages/flutter_gallery_3d) | 3D ring | MIT |
| [coverflow_carousel](https://pub.dev/packages/coverflow_carousel), [overlapped_carousel](https://pub.dev/packages/overlapped_carousel) | cover flow, overlap | BSD-3-Clause, MIT |
| [stacked_card_carousel](https://pub.dev/packages/stacked_card_carousel), [flutter_card_swiper](https://pub.dev/packages/flutter_card_swiper), [appinio_swiper](https://pub.dev/packages/appinio_swiper) | card decks | BSD-3-Clause, MIT |
| [fan_carousel_image_slider](https://pub.dev/packages/fan_carousel_image_slider), [curved_carousel](https://pub.dev/packages/curved_carousel), [flywheel_carousel](https://pub.dev/packages/flywheel_carousel) | fan and arc | MIT, BSD-3-Clause |
| [turn_page_transition](https://pub.dev/packages/turn_page_transition), [page_turn](https://pub.dev/packages/page_turn) | page turn | BSD-3-Clause, MIT |
| [shader_transitions](https://pub.dev/packages/shader_transitions), [intro_views_flutter](https://pub.dev/packages/intro_views_flutter) | clock, blocks and circle reveals | MIT |
| Flutter's `CarouselView` and `ListWheelScrollView` | Material 3 layouts, wheel | BSD-3-Clause |

## License

MIT. See [LICENSE](LICENSE).
