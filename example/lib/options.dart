import 'package:flutter/material.dart';
import 'package:ultimate_carousel/ultimate_carousel.dart';

/// The groups shown in the gallery's effect picker.
enum EffectFamily {
  /// Flat slides, fades and zooms.
  slides('Slides & fades'),

  /// Perspective and 3D shapes.
  threeD('3D'),

  /// The Material 3 carousel layouts.
  material('Material 3'),

  /// Decks, piles and fans of cards.
  cards('Cards'),

  /// Items uncovered in place.
  reveals('Reveals');

  const EffectFamily(this.label);

  /// The group's title.
  final String label;
}

/// One transition the gallery can show.
class EffectOption {
  /// Creates an option.
  const EffectOption(
    this.name,
    this.family,
    this.effect,
    this.code, {
    this.spacing = 0,
  });

  /// The chip label.
  final String name;

  /// The group it belongs to.
  final EffectFamily family;

  /// The effect itself.
  final CarouselEffect effect;

  /// How the effect is written in code.
  final String code;

  /// The gap between items for this effect.
  final double spacing;
}

/// Every transition in the gallery.
const List<EffectOption> effectOptions = <EffectOption>[
  EffectOption(
    'Slide',
    EffectFamily.slides,
    CarouselEffect.slide(),
    'CarouselEffect.slide()',
    spacing: 16,
  ),
  EffectOption(
    'Fade',
    EffectFamily.slides,
    CarouselEffect.fade(),
    'CarouselEffect.fade()',
  ),
  EffectOption(
    'Enlarge',
    EffectFamily.slides,
    CarouselEffect.enlarge(),
    'CarouselEffect.enlarge()',
  ),
  EffectOption(
    'Enlarge (zoom)',
    EffectFamily.slides,
    CarouselEffect.enlarge(strategy: CarouselEnlargeStrategy.zoom),
    'CarouselEffect.enlarge(strategy: CarouselEnlargeStrategy.zoom)',
  ),
  EffectOption(
    'Enlarge (height)',
    EffectFamily.slides,
    CarouselEffect.enlarge(strategy: CarouselEnlargeStrategy.height),
    'CarouselEffect.enlarge(strategy: CarouselEnlargeStrategy.height)',
    spacing: 12,
  ),
  EffectOption(
    'Zoom fade',
    EffectFamily.slides,
    CarouselEffect.fade(zoom: 1.15),
    'CarouselEffect.fade(zoom: 1.15)',
  ),
  EffectOption(
    'To background',
    EffectFamily.slides,
    CarouselEffect.foregroundToBackground(),
    'CarouselEffect.foregroundToBackground()',
  ),
  EffectOption(
    'To foreground',
    EffectFamily.slides,
    CarouselEffect.backgroundToForeground(),
    'CarouselEffect.backgroundToForeground()',
  ),
  EffectOption(
    'Focus',
    EffectFamily.slides,
    CarouselEffect.focus(),
    'CarouselEffect.focus()',
    spacing: 12,
  ),
  EffectOption(
    'Overlap',
    EffectFamily.slides,
    CarouselEffect.overlap(),
    'CarouselEffect.overlap()',
  ),
  EffectOption(
    'Zoom out',
    EffectFamily.slides,
    CarouselEffect.zoomOut(),
    'CarouselEffect.zoomOut()',
  ),
  EffectOption(
    'Zoom in',
    EffectFamily.slides,
    CarouselEffect.zoomIn(),
    'CarouselEffect.zoomIn()',
  ),
  EffectOption(
    'Depth',
    EffectFamily.slides,
    CarouselEffect.depth(),
    'CarouselEffect.depth()',
  ),
  EffectOption(
    'Parallax',
    EffectFamily.slides,
    CarouselEffect.parallax(),
    'CarouselEffect.parallax()',
  ),
  EffectOption(
    'Stack',
    EffectFamily.slides,
    CarouselEffect.stack(),
    'CarouselEffect.stack()',
  ),
  EffectOption(
    'Accordion',
    EffectFamily.slides,
    CarouselEffect.accordion(),
    'CarouselEffect.accordion()',
  ),
  EffectOption(
    'Rotate down',
    EffectFamily.slides,
    CarouselEffect.rotate(),
    'CarouselEffect.rotate()',
  ),
  EffectOption(
    'Rotate up',
    EffectFamily.slides,
    CarouselEffect.rotate(fromTop: true),
    'CarouselEffect.rotate(fromTop: true)',
  ),
  EffectOption(
    'Cube',
    EffectFamily.threeD,
    CarouselEffect.cube(),
    'CarouselEffect.cube()',
  ),
  EffectOption(
    'Cube inside',
    EffectFamily.threeD,
    CarouselEffect.cube(inside: true),
    'CarouselEffect.cube(inside: true)',
  ),
  EffectOption(
    'Flip',
    EffectFamily.threeD,
    CarouselEffect.flip(),
    'CarouselEffect.flip()',
  ),
  EffectOption(
    'Flip vertical',
    EffectFamily.threeD,
    CarouselEffect.flip(vertical: true),
    'CarouselEffect.flip(vertical: true)',
  ),
  EffectOption(
    'Coverflow',
    EffectFamily.threeD,
    CarouselEffect.coverflow(),
    'CarouselEffect.coverflow()',
  ),
  EffectOption(
    'Tablet',
    EffectFamily.threeD,
    CarouselEffect.tablet(),
    'CarouselEffect.tablet()',
  ),
  EffectOption(
    'Ring',
    EffectFamily.threeD,
    CarouselEffect.ring(),
    'CarouselEffect.ring()',
  ),
  EffectOption(
    'Ring (facing)',
    EffectFamily.threeD,
    CarouselEffect.ring(faceViewer: true),
    'CarouselEffect.ring(faceViewer: true)',
  ),
  EffectOption(
    'Ring (tilted)',
    EffectFamily.threeD,
    CarouselEffect.ring(faceViewer: true, tilt: 0.35),
    'CarouselEffect.ring(faceViewer: true, tilt: 0.35)',
  ),
  EffectOption(
    'Wheel',
    EffectFamily.threeD,
    CarouselEffect.wheel(),
    'CarouselEffect.wheel()',
  ),
  EffectOption(
    'Cylinder',
    EffectFamily.threeD,
    CarouselEffect.cylinder(),
    'CarouselEffect.cylinder()',
  ),
  EffectOption(
    'Helix',
    EffectFamily.threeD,
    CarouselEffect.helix(),
    'CarouselEffect.helix()',
  ),
  EffectOption(
    'Page turn',
    EffectFamily.threeD,
    CarouselEffect.pageTurn(),
    'CarouselEffect.pageTurn()',
  ),
  EffectOption(
    'Tunnel',
    EffectFamily.threeD,
    CarouselEffect.tunnel(),
    'CarouselEffect.tunnel()',
  ),
  EffectOption(
    'Multi-browse',
    EffectFamily.material,
    CarouselEffect.material(),
    'CarouselEffect.material()',
  ),
  EffectOption(
    'Hero',
    EffectFamily.material,
    CarouselEffect.material(weights: <int>[7, 1]),
    'CarouselEffect.material(weights: [7, 1])',
  ),
  EffectOption(
    'Centered hero',
    EffectFamily.material,
    CarouselEffect.material(weights: <int>[1, 7, 1]),
    'CarouselEffect.material(weights: [1, 7, 1])',
  ),
  EffectOption(
    'Deck',
    EffectFamily.cards,
    CarouselEffect.deck(),
    'CarouselEffect.deck()',
  ),
  EffectOption(
    'Tinder',
    EffectFamily.cards,
    CarouselEffect.tinder(),
    'CarouselEffect.tinder()',
  ),
  EffectOption(
    'Fan',
    EffectFamily.cards,
    CarouselEffect.fan(),
    'CarouselEffect.fan()',
  ),
  EffectOption(
    'Arc',
    EffectFamily.cards,
    CarouselEffect.arc(),
    'CarouselEffect.arc()',
  ),
  EffectOption(
    'Rainbow',
    EffectFamily.cards,
    CarouselEffect.arc(upward: false),
    'CarouselEffect.arc(upward: false)',
  ),
  EffectOption(
    'Photo pile',
    EffectFamily.cards,
    CarouselEffect.scatter(),
    'CarouselEffect.scatter()',
  ),
  EffectOption(
    'Circle',
    EffectFamily.reveals,
    CarouselEffect.circularReveal(),
    'CarouselEffect.circularReveal()',
  ),
  EffectOption(
    'Wipe',
    EffectFamily.reveals,
    CarouselEffect.wipe(),
    'CarouselEffect.wipe()',
  ),
  EffectOption(
    'Curtain',
    EffectFamily.reveals,
    CarouselEffect.curtain(),
    'CarouselEffect.curtain()',
  ),
  EffectOption(
    'Blinds',
    EffectFamily.reveals,
    CarouselEffect.blinds(),
    'CarouselEffect.blinds()',
  ),
  EffectOption(
    'Liquid',
    EffectFamily.reveals,
    CarouselEffect.liquid(),
    'CarouselEffect.liquid()',
  ),
  EffectOption(
    'Concentric',
    EffectFamily.reveals,
    CarouselEffect.concentric(),
    'CarouselEffect.concentric()',
  ),
  EffectOption(
    'Clock',
    EffectFamily.reveals,
    CarouselEffect.clock(),
    'CarouselEffect.clock()',
  ),
  EffectOption(
    'Blocks',
    EffectFamily.reveals,
    CarouselEffect.blocks(),
    'CarouselEffect.blocks()',
  ),
];

/// One indicator the gallery can show.
class IndicatorOption {
  /// Creates an option.
  const IndicatorOption(this.name, this.code, this.build);

  /// The chip label.
  final String name;

  /// How the indicator effect is written in code.
  final String code;

  /// Builds the effect in the app's colors.
  final IndicatorEffect Function(ColorScheme scheme) build;
}

/// Every indicator in the gallery.
final List<IndicatorOption> indicatorOptions = <IndicatorOption>[
  IndicatorOption(
    'Worm',
    'IndicatorEffect.worm()',
    (ColorScheme s) => IndicatorEffect.worm(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Thin worm',
    'IndicatorEffect.worm(style: WormStyle.thin)',
    (ColorScheme s) => IndicatorEffect.worm(
      style: WormStyle.thin,
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Underground worm',
    'IndicatorEffect.worm(style: WormStyle.underground)',
    (ColorScheme s) => IndicatorEffect.worm(
      style: WormStyle.underground,
      paintStyle: PaintingStyle.stroke,
      dotColor: s.outline,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Expanding dots',
    'IndicatorEffect.expandingDots()',
    (ColorScheme s) => IndicatorEffect.expandingDots(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Jumping dot',
    'IndicatorEffect.jumpingDot()',
    (ColorScheme s) => IndicatorEffect.jumpingDot(
      verticalOffset: 8,
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Drop',
    'IndicatorEffect.drop()',
    (ColorScheme s) => IndicatorEffect.drop(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Wave',
    'IndicatorEffect.wave()',
    (ColorScheme s) => IndicatorEffect.wave(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Radio',
    'IndicatorEffect.radio()',
    (ColorScheme s) => IndicatorEffect.radio(
      dotColor: s.outline,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Scrolling dots',
    'IndicatorEffect.scrollingDots()',
    (ColorScheme s) => IndicatorEffect.scrollingDots(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Slide',
    'IndicatorEffect.slide()',
    (ColorScheme s) => IndicatorEffect.slide(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Scale',
    'IndicatorEffect.scale()',
    (ColorScheme s) => IndicatorEffect.scale(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Swap',
    'IndicatorEffect.swap()',
    (ColorScheme s) => IndicatorEffect.swap(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Swap (orbit)',
    'IndicatorEffect.swap(style: SwapStyle.zRotation)',
    (ColorScheme s) => IndicatorEffect.swap(
      style: SwapStyle.zRotation,
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Color',
    'IndicatorEffect.colorTransition()',
    (ColorScheme s) => IndicatorEffect.colorTransition(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Fill',
    'IndicatorEffect.fill()',
    (ColorScheme s) => IndicatorEffect.fill(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Story bars',
    'IndicatorEffect.segments()',
    (ColorScheme s) => IndicatorEffect.segments(
      dotColor: s.outlineVariant,
      activeDotColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Line',
    'IndicatorEffect.line()',
    (ColorScheme s) => IndicatorEffect.line(
      trackColor: s.outlineVariant,
      activeColor: s.primary,
    ),
  ),
  IndicatorOption(
    'Fraction',
    'IndicatorEffect.fraction()',
    (ColorScheme s) => IndicatorEffect.fraction(
      style: TextStyle(
        color: s.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
];
