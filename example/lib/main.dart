import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultimate_carousel/ultimate_carousel.dart';

import 'demo_card.dart';
import 'options.dart';

void main() => runApp(const GalleryApp());

/// The gallery app shown in the live demo.
class GalleryApp extends StatelessWidget {
  /// Creates the gallery app.
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color seed = Color(0xFF6750A4);
    return MaterialApp(
      title: 'ultimate_carousel',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const GalleryPage(),
    );
  }
}

/// Shows one carousel with every effect, indicator and option to try.
class GalleryPage extends StatefulWidget {
  /// Creates the gallery page.
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final UltimateCarouselController _controller = UltimateCarouselController();

  int _effectIndex = 0;
  int _indicatorIndex = 0;
  bool _loop = true;
  bool _autoPlay = false;
  bool _vertical = false;
  double? _fraction;

  EffectOption get _effect => effectOptions[_effectIndex];

  IndicatorOption get _indicator => indicatorOptions[_indicatorIndex];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _code {
    final StringBuffer code = StringBuffer()
      ..writeln('final controller = UltimateCarouselController();')
      ..writeln()
      ..writeln('UltimateCarousel(')
      ..writeln('  controller: controller,')
      ..writeln('  effect: const ${_effect.code},');
    if (_loop) {
      code.writeln('  loop: true,');
    }
    if (_autoPlay) {
      code.writeln('  autoPlay: const CarouselAutoPlay(),');
    }
    if (_vertical) {
      code.writeln('  scrollDirection: Axis.vertical,');
    }
    if (_fraction != null) {
      code.writeln('  viewportFraction: ${_fraction!.toStringAsFixed(2)},');
    }
    code
      ..writeln('  children: slides,')
      ..writeln(')')
      ..writeln()
      ..writeln('CarouselIndicator(')
      ..writeln('  controller: controller,');
    if (_vertical) {
      code.writeln('  axis: Axis.vertical,');
    }
    code
      ..writeln('  effect: const ${_indicator.code},')
      ..write(')');
    return code.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = constraints.maxWidth >= 920;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: _buildStage(context, wide: true),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                      child: _buildControls(context),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                _buildStage(context, wide: false),
                const SizedBox(height: 16),
                _buildControls(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStage(BuildContext context, {required bool wide}) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final IndicatorEffect indicatorEffect = _indicator.build(scheme);
    final Widget carousel = UltimateCarousel.builder(
      controller: _controller,
      itemCount: 12,
      effect: _effect.effect,
      loop: _loop,
      autoPlay: _autoPlay ? const CarouselAutoPlay() : CarouselAutoPlay.off,
      scrollDirection: _vertical ? Axis.vertical : Axis.horizontal,
      viewportFraction: _fraction,
      spacing: _effect.spacing,
      clipBehavior: Clip.none,
      animateToTappedItem: true,
      semanticLabel: 'Demo carousel',
      itemBuilder: (BuildContext context, int index) => DemoCard(index: index),
    );
    final double height = _vertical ? (wide ? 520 : 420) : (wide ? 400 : 280);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('ultimate_carousel', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          '${effectOptions.length} transitions · ${indicatorOptions.length} '
          'indicators · one widget',
          style: theme.textTheme.titleSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: height,
          child: _vertical
              ? Row(
                  children: <Widget>[
                    Expanded(child: carousel),
                    const SizedBox(width: 16),
                    CarouselIndicator(
                      controller: _controller,
                      axis: Axis.vertical,
                      effect: indicatorEffect,
                    ),
                  ],
                )
              : carousel,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Previous',
              onPressed: () => _controller.previousPage(),
              icon: const Icon(Icons.chevron_left),
            ),
            const SizedBox(width: 16),
            if (!_vertical)
              CarouselIndicator(
                controller: _controller,
                effect: indicatorEffect,
              ),
            const SizedBox(width: 16),
            IconButton.filledTonal(
              tooltip: 'Next',
              onPressed: () => _controller.nextPage(),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Scrubber(controller: _controller, count: 12),
        const SizedBox(height: 16),
        _CodeBox(code: _code),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double defaultFraction = _effect.effect.defaultViewportFraction;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Section(title: 'Transition', theme: theme),
            for (final EffectFamily family in EffectFamily.values) ...<Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Text(family.label, style: theme.textTheme.labelLarge),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (int i = 0; i < effectOptions.length; i++)
                      if (effectOptions[i].family == family)
                        ChoiceChip(
                          label: Text(effectOptions[i].name),
                          selected: i == _effectIndex,
                          onSelected: (bool _) => setState(() {
                            _effectIndex = i;
                            _fraction = null;
                          }),
                        ),
                  ],
                ),
              ),
            ],
            const Divider(height: 32),
            _Section(title: 'Indicator', theme: theme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (int i = 0; i < indicatorOptions.length; i++)
                    ChoiceChip(
                      label: Text(indicatorOptions[i].name),
                      selected: i == _indicatorIndex,
                      onSelected: (bool _) =>
                          setState(() => _indicatorIndex = i),
                    ),
                ],
              ),
            ),
            const Divider(height: 32),
            _Section(title: 'Options', theme: theme),
            SwitchListTile(
              title: const Text('Loop forever'),
              value: _loop,
              onChanged: (bool value) => setState(() => _loop = value),
            ),
            SwitchListTile(
              title: const Text('Autoplay'),
              value: _autoPlay,
              onChanged: (bool value) => setState(() => _autoPlay = value),
            ),
            SwitchListTile(
              title: const Text('Vertical'),
              value: _vertical,
              onChanged: (bool value) => setState(() => _vertical = value),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: <Widget>[
                  Text('Item size', style: theme.textTheme.bodyLarge),
                  const Spacer(),
                  Text(
                    _fraction == null
                        ? 'effect default'
                        : '${(_fraction! * 100).round()}%',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Slider(
              value: _fraction ?? clampDouble(defaultFraction, 0.2, 1),
              min: 0.2,
              max: 1,
              onChanged: (double value) => setState(() => _fraction = value),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: _fraction == null
                      ? null
                      : () => setState(() => _fraction = null),
                  child: const Text('Use the effect default'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A slider that moves the carousel by hand, to look at a transition
/// halfway through.
class _Scrubber extends StatelessWidget {
  const _Scrubber({required this.controller, required this.count});

  final UltimateCarouselController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Text('Scrub', style: text.labelLarge),
        Expanded(
          child: AnimatedBuilder(
            animation: controller,
            builder: (BuildContext context, Widget? child) {
              final double value = clampDouble(
                controller.realPage,
                0,
                (count - 1).toDouble(),
              );
              return Slider(
                value: value,
                max: (count - 1).toDouble(),
                onChanged: controller.jumpTo,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 56, 16),
            child: SelectableText(
              code,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
                color: scheme.onSurface,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
