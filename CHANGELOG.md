## 0.2.0

* `CarouselEffect.builder` wraps every item on show in widgets of your own,
  with the item's `ratio` among the items on show, `itemsBefore`,
  `itemsAfter` and a `CarouselDepthOrder`. Effects builders written for
  flutter_custom_carousel work unchanged.
* `UltimateCarousel.dragSpeed` scales how far a drag moves the carousel.
* `UltimateCarousel.onSettled` reports the item the carousel comes to rest
  on.
* Three new transitions, from the flutter_custom_carousel demos, for 54 in
  all: `deal` (a pile whose top card flips off with a glint), `wallet` (a
  stack that climbs away, blurred) and `crate` (flipping through records).
* `ring` gains `blur` and `fade` for a depth of field, which makes the
  orbiting menu of the flutter_custom_carousel demos.

## 0.1.0

* First release.
* `UltimateCarousel` with looping, autoplay, vertical and right-to-left
  layouts, snapping physics, keyboard, mouse wheel and screen reader support.
* `UltimateCarouselController` to move, jump, scrub (`jumpTo`) and control
  autoplay.
* `CarouselAutoPlay.scroll` glides at a steady speed, like a marquee.
* 51 transitions:
  * Slides and fades: slide, fade (cross fade, zoom), enlarge (scale, height,
    zoom), zoom out, zoom in, depth, parallax, stack, accordion, rotate,
    foreground to background, background to foreground, focus, overlap,
    uncover, skew and expo.
  * 3D: cube (outside and inside), flip, cover flow, tablet, ring (facing
    out or at the viewer, tilted), wheel, cylinder, helix, page turn and
    tunnel.
  * Material 3: multi-browse, hero, centered hero and full screen layouts.
  * Cards: deck, tinder, layered, fan, arc, scatter and expanding cards.
  * Reveals: circular reveal, wipe, curtain, blinds, liquid, concentric,
    clock, blocks, slicer (slide, shrink or turn) and shutters.
  * Creative: `CarouselEffect.creative` with `CarouselPose`, like Swiper's
    creative effect, and its six demo looks: sink back, drift apart, push,
    tumble, spin and door.
  * Your own with `CarouselEffect.custom`, `ItemMatrix` and
    `RevealCarouselEffect`.
* `CarouselIndicator` with 15 effects: worm (four styles), expanding dots,
  jumping dot, drop, wave, radio, scrolling dots, slide, scale, swap (three
  styles), color transition, fill, story segments, line and fraction.
* `CarouselItemScope` and `CarouselParallax` to animate item content.
* Effects can shade items towards any color (`shadeColor`) and take the
  color out of them (`CarouselItemTransform.grayscale`).
