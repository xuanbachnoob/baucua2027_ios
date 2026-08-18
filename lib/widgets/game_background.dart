import 'package:flutter/material.dart';

class GameBackground extends StatefulWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _effectController;

  @override
  void initState() {
    super.initState();
    _effectController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 34),
    )..repeat();
  }

  @override
  void dispose() {
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            _FireworkLayer(controller: _effectController),
          ],
        ),
      ),
    );
  }
}

class _FireworkLayer extends StatelessWidget {
  const _FireworkLayer({required this.controller});

  static const _frames = [
    'assets/firework_01.png',
    'assets/firework_02.png',
    'assets/firework_03.png',
    'assets/firework_04.png',
    'assets/firework_05.png',
    'assets/firework_06.png',
    'assets/firework_07.png',
    'assets/firework_08.png',
    'assets/firework_09.png',
    'assets/firework_10.png',
    'assets/firework_11.png',
    'assets/firework_12.png',
  ];

  static const _cycleMs = 34000.0;
  static const _durationMs = 960.0;
  static const _bursts = [
    _FireworkBurst(startMs: 1200, x: 0.22, y: 0.18, size: 0.48),
    _FireworkBurst(startMs: 4100, x: 0.78, y: 0.26, size: 0.48),
    _FireworkBurst(startMs: 6900, x: 0.48, y: 0.14, size: 0.48),
    _FireworkBurst(startMs: 9800, x: 0.16, y: 0.54, size: 0.48),
    _FireworkBurst(startMs: 12900, x: 0.84, y: 0.50, size: 0.48),
    _FireworkBurst(startMs: 16500, x: 0.34, y: 0.74, size: 0.48),
    _FireworkBurst(startMs: 20600, x: 0.68, y: 0.70, size: 0.48),
    _FireworkBurst(startMs: 25100, x: 0.52, y: 0.42, size: 0.48),
    _FireworkBurst(startMs: 29600, x: 0.12, y: 0.32, size: 0.48),
    _FireworkBurst(startMs: 32100, x: 0.88, y: 0.15, size: 0.48),
  ];

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final nowMs = controller.value * _cycleMs;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final burst in _bursts)
                      if (_age(nowMs, burst.startMs) < _durationMs)
                        _FireworkSprite(
                          ageMs: _age(nowMs, burst.startMs),
                          left: width * burst.x,
                          top: height * burst.y,
                          size: width * burst.size,
                          frames: _frames,
                        ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static double _age(double nowMs, double startMs) {
    final age = nowMs - startMs;
    return age >= 0 ? age : age + _cycleMs;
  }
}

class _FireworkBurst {
  const _FireworkBurst({
    required this.startMs,
    required this.x,
    required this.y,
    required this.size,
  });

  final double startMs;
  final double x;
  final double y;
  final double size;
}

class _FireworkSprite extends StatelessWidget {
  const _FireworkSprite({
    required this.ageMs,
    required this.left,
    required this.top,
    required this.size,
    required this.frames,
  });

  final double ageMs;
  final double left;
  final double top;
  final double size;
  final List<String> frames;

  @override
  Widget build(BuildContext context) {
    final progress = (ageMs / _FireworkLayer._durationMs).clamp(0.0, 0.999);
    final frameIndex = (progress * frames.length).floor();
    final opacity = progress < 0.72 ? 0.95 : (1.0 - progress) / 0.28;
    return Positioned(
      left: left - size / 2,
      top: top - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity.clamp(0.0, 0.95),
        child: Image.asset(
          frames[frameIndex],
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
