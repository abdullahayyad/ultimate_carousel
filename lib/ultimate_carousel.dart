/// Every carousel transition in one package.
///
/// Start with [UltimateCarousel] and pick a look with [CarouselEffect]:
///
/// ```dart
/// UltimateCarousel(
///   effect: const CarouselEffect.cube(),
///   loop: true,
///   autoPlay: const CarouselAutoPlay(),
///   children: slides,
/// )
/// ```
///
/// Add a [CarouselIndicator] with an [IndicatorEffect] to show the position.
library;

export 'src/carousel.dart';
export 'src/effects/basic_effects.dart';
export 'src/effects/card_effects.dart';
export 'src/effects/custom_effect.dart';
export 'src/effects/effect.dart';
export 'src/effects/item_matrix.dart';
export 'src/effects/reveal_effects.dart';
export 'src/effects/three_d_effects.dart';
export 'src/indicators/dot_effects.dart';
export 'src/indicators/indicator.dart';
export 'src/indicators/indicator_effect.dart';
export 'src/indicators/other_effects.dart';
export 'src/item.dart';
export 'src/options.dart';
