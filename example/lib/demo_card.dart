import 'package:flutter/material.dart';
import 'package:ultimate_carousel/ultimate_carousel.dart';

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
  Icons.palette_rounded,
  Icons.rocket_launch_rounded,
  Icons.camera_alt_rounded,
  Icons.sports_esports_rounded,
  Icons.headphones_rounded,
  Icons.auto_awesome_rounded,
];

const List<String> _titles = <String>[
  'Mountains',
  'Coffee',
  'Music',
  'Travel',
  'Friends',
  'Summer',
  'Art',
  'Launch',
  'Photos',
  'Games',
  'Podcasts',
  'Magic',
];

/// A colorful card used as a carousel item in the gallery.
class DemoCard extends StatelessWidget {
  /// Creates the card for item [index].
  const DemoCard({super.key, required this.index});

  /// The item's position in the carousel.
  final int index;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = _palettes[index % _palettes.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const CarouselParallax(factor: 0.6, child: _Bubbles()),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Icon(
                    _icons[index % _icons.length],
                    color: Colors.white,
                    size: 34,
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _titles[index % _titles.length],
                          style: const TextStyle(
                            color: Color(0xDDFFFFFF),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _Bubbles extends StatelessWidget {
  const _Bubbles();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BubblePainter());
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = const Color(0x22FFFFFF);
    canvas
      ..drawCircle(
        Offset(size.width * 0.85, size.height * 0.12),
        size.shortestSide * 0.38,
        paint,
      )
      ..drawCircle(
        Offset(size.width * 0.1, size.height * 0.95),
        size.shortestSide * 0.3,
        paint,
      )
      ..drawCircle(
        Offset(size.width * 0.62, size.height * 0.7),
        size.shortestSide * 0.12,
        paint,
      );
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) => false;
}
