import 'dart:math';
import 'package:flutter/material.dart';

enum WeatherSceneMode { dawn, day, dusk, night, rain }

class WeatherScene extends StatefulWidget {
  final WeatherSceneMode mode;
  final String temperature;
  final String description;

  const WeatherScene({
    Key? key,
    required this.mode,
    required this.temperature,
    required this.description,
  }) : super(key: key);

  @override
  State<WeatherScene> createState() => _WeatherSceneState();
}

class _WeatherSceneState extends State<WeatherScene> with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _birdController;
  
  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    _birdController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _birdController.dispose();
    super.dispose();
  }

  // Define gradients for each mode
  LinearGradient _getSkyGradient(WeatherSceneMode mode) {
    switch (mode) {
      case WeatherSceneMode.dawn:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7B6BA8), Color(0xFFF08F6A), Color(0xFFFFD08A)],
          stops: [0.0, 0.55, 1.0],
        );
      case WeatherSceneMode.day:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3F98DC), Color(0xFFA9DCF5), Color(0xFFE8F6FF)],
          stops: [0.0, 0.7, 1.0],
        );
      case WeatherSceneMode.dusk:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B3068), Color(0xFFC8553D), Color(0xFFF9A825)],
          stops: [0.0, 0.6, 1.0],
        );
      case WeatherSceneMode.night:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1230), Color(0xFF1B2A5C), Color(0xFF2E3F78)],
          stops: [0.0, 0.7, 1.0],
        );
      case WeatherSceneMode.rain:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4D585E), Color(0xFF8A979C), Color(0xFFB0BBBD)],
          stops: [0.0, 0.7, 1.0],
        );
    }
  }

  // Define sun/moon properties
  Alignment _getOrbAlignment(WeatherSceneMode mode) {
    switch (mode) {
      case WeatherSceneMode.dawn: return const Alignment(-0.6, 0.0);
      case WeatherSceneMode.day: return const Alignment(0.0, -0.8);
      case WeatherSceneMode.dusk: return const Alignment(0.6, 0.0);
      case WeatherSceneMode.night: return const Alignment(0.5, -0.7);
      case WeatherSceneMode.rain: return const Alignment(0.0, -0.8);
    }
  }

  Color _getOrbColor(WeatherSceneMode mode) {
    switch (mode) {
      case WeatherSceneMode.dawn: return const Color(0xFFFFD36B);
      case WeatherSceneMode.day: return const Color(0xFFFFE27A);
      case WeatherSceneMode.dusk: return const Color(0xFFFF9A4D);
      case WeatherSceneMode.night: return const Color(0xFFF4EFD8); // Moon
      case WeatherSceneMode.rain: return Colors.transparent;
    }
  }

  BoxShadow _getOrbShadow(WeatherSceneMode mode) {
    if (mode == WeatherSceneMode.rain) return const BoxShadow(color: Colors.transparent);
    Color shadowColor;
    switch (mode) {
      case WeatherSceneMode.dawn: shadowColor = const Color(0xAAFFB347); break;
      case WeatherSceneMode.day: shadowColor = const Color(0x88FFD24D); break;
      case WeatherSceneMode.dusk: shadowColor = const Color(0xAAFF7A3D); break;
      case WeatherSceneMode.night: shadowColor = const Color(0x55F4EFD8); break;
      default: shadowColor = Colors.transparent;
    }
    return BoxShadow(color: shadowColor, blurRadius: mode == WeatherSceneMode.night ? 34 : 50, spreadRadius: mode == WeatherSceneMode.night ? 10 : 22);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF231A14), width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0xFF231A14), offset: Offset(5, 5))],
      ),
      child: Stack(
        children: [
          // Background Sky Gradient
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(gradient: _getSkyGradient(widget.mode)),
          ),
          
          // Stars (visible only at night)
          AnimatedOpacity(
            duration: const Duration(seconds: 1),
            opacity: widget.mode == WeatherSceneMode.night ? 1.0 : 0.0,
            child: const _Stars(),
          ),
          
          // Sun / Moon Orb
          AnimatedAlign(
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            alignment: _getOrbAlignment(widget.mode),
            child: AnimatedContainer(
              duration: const Duration(seconds: 1),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getOrbColor(widget.mode),
                boxShadow: [_getOrbShadow(widget.mode)],
              ),
            ),
          ),
          
          // Clouds
          AnimatedBuilder(
            animation: _cloudController,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: 50,
                    left: -100 + (_cloudController.value * 500),
                    child: _Cloud(mode: widget.mode, scale: 1.0),
                  ),
                  Positioned(
                    top: 90,
                    left: -200 + ((_cloudController.value + 0.3) % 1.0 * 600),
                    child: _Cloud(mode: widget.mode, scale: 0.7),
                  ),
                  Positioned(
                    top: 30,
                    left: -50 + ((_cloudController.value + 0.7) % 1.0 * 500),
                    child: _Cloud(mode: widget.mode, scale: 1.2),
                  ),
                ],
              );
            }
          ),
          
          // Birds (visible only in day/dawn)
          if (widget.mode == WeatherSceneMode.day || widget.mode == WeatherSceneMode.dawn)
            AnimatedBuilder(
              animation: _birdController,
              builder: (context, child) {
                return Positioned(
                  top: 80,
                  left: -50 + (_birdController.value * 500),
                  child: const Icon(Icons.flight, color: Color(0xFF231A14), size: 16), // Simplified bird placeholder
                );
              }
            ),

          // Rain overlay
          if (widget.mode == WeatherSceneMode.rain)
             const Positioned.fill(
               child: _Rain(),
             ),

          // Farm SVG / Landscape (Simplified with CustomPaint)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: CustomPaint(painter: _FarmPainter()),
          ),
          
          // Temperature Badge
          Positioned(
            top: 12,
            left: 12,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF5E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF231A14), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0xFF231A14), offset: Offset(3, 3))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.temperature, 
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF231A14), height: 1.0)
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.description, 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF231A14))
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Overall shade
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            color: _getShade(widget.mode),
          )
        ],
      ),
    );
  }

  Color _getShade(WeatherSceneMode mode) {
    switch (mode) {
      case WeatherSceneMode.dawn: return const Color.fromRGBO(255, 150, 90, 0.16);
      case WeatherSceneMode.dusk: return const Color.fromRGBO(220, 90, 40, 0.22);
      case WeatherSceneMode.night: return const Color.fromRGBO(8, 16, 50, 0.5);
      case WeatherSceneMode.rain: return const Color.fromRGBO(30, 50, 60, 0.28);
      case WeatherSceneMode.day: return Colors.transparent;
    }
  }
}

class _Cloud extends StatelessWidget {
  final WeatherSceneMode mode;
  final double scale;

  const _Cloud({required this.mode, required this.scale});

  @override
  Widget build(BuildContext context) {
    Color filterColor = Colors.white.withOpacity(0.92);
    if (mode == WeatherSceneMode.night) {
      filterColor = Colors.white.withOpacity(0.3);
    } else if (mode == WeatherSceneMode.dawn || mode == WeatherSceneMode.dusk) {
      filterColor = const Color(0xFFFFE0B2).withOpacity(0.9);
    } else if (mode == WeatherSceneMode.rain) {
      filterColor = Colors.white.withOpacity(0.5);
    }

    return Transform.scale(
      scale: scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 92,
            height: 26,
            decoration: BoxDecoration(color: filterColor, borderRadius: BorderRadius.circular(30)),
          ),
          Positioned(
            left: 12, top: -20,
            child: Container(width: 42, height: 42, decoration: BoxDecoration(color: filterColor, shape: BoxShape.circle)),
          ),
          Positioned(
            left: 44, top: -13,
            child: Container(width: 32, height: 32, decoration: BoxDecoration(color: filterColor, shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars();
  @override
  Widget build(BuildContext context) {
    final rand = Random(42);
    return Stack(
      children: List.generate(30, (index) {
        return Positioned(
          left: rand.nextDouble() * 400,
          top: rand.nextDouble() * 150,
          child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
        );
      }),
    );
  }
}

class _Rain extends StatelessWidget {
  const _Rain();
  @override
  Widget build(BuildContext context) {
    final rand = Random(123);
    return Stack(
      children: List.generate(40, (index) {
        return Positioned(
          left: rand.nextDouble() * 400,
          top: rand.nextDouble() * 320,
          child: Transform.rotate(
            angle: 0.2, // 12 degrees approx
            child: Container(
              width: 2,
              height: 18,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, Color(0xFFE3F1FA)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FarmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Back hill
    final path1 = Path();
    path1.moveTo(0, size.height * 0.3);
    path1.quadraticBezierTo(size.width * 0.25, size.height * -0.2, size.width * 0.5, size.height * 0.2);
    path1.quadraticBezierTo(size.width * 0.75, size.height * 0.1, size.width, size.height * 0.0);
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, Paint()..color = const Color(0xFF6F9A5A));

    // Front hill
    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.3, size.height * 0.2, size.width * 0.65, size.height * 0.5);
    path2.quadraticBezierTo(size.width * 0.85, size.height * 0.4, size.width, size.height * 0.3);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, Paint()..color = const Color(0xFF4F8A3F));

    // Base strip
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3), Paint()..color = const Color(0xFF3F7D3A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
