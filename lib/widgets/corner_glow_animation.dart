import 'package:flutter/material.dart';

class CornerGlowAnimation extends StatefulWidget {
  const CornerGlowAnimation({
    super.key,
    this.size = 88,
    this.mirror = false,
  });

  final double size;
  final bool mirror;

  @override
  State<CornerGlowAnimation> createState() => _CornerGlowAnimationState();
}

class _CornerGlowAnimationState extends State<CornerGlowAnimation>
    with SingleTickerProviderStateMixin {
  static const _frames = [
    'assets/corner_glow_1.png',
    'assets/corner_glow_2.png',
    'assets/corner_glow_3.png',
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 390),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final frameIndex = (_controller.value * _frames.length).floor().clamp(
            0,
            _frames.length - 1,
          );
          final image = Image.asset(
            _frames[frameIndex],
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
          );

          if (!widget.mirror) return image;
          return Transform.scale(scaleX: -1, child: image);
        },
      ),
    );
  }
}
