import 'package:flutter/material.dart';

import '../models/bau_cua_face.dart';

class FaceGrid extends StatefulWidget {
  const FaceGrid({
    super.key,
    required this.faces,
    required this.results,
    required this.highlightResults,
    required this.machineId,
  });

  final List<BauCuaFace> faces;
  final List<BauCuaFace> results;
  final bool highlightResults;
  final String machineId;

  @override
  State<FaceGrid> createState() => _FaceGridState();
}

class _FaceGridState extends State<FaceGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _blink = CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut);
    _syncBlinkState();
  }

  @override
  void didUpdateWidget(covariant FaceGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBlinkState();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  void _syncBlinkState() {
    final hasHighlight = widget.highlightResults && widget.results.isNotEmpty;
    if (hasHighlight && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
    } else if (!hasHighlight && _blinkController.isAnimating) {
      _blinkController.stop();
      _blinkController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blink,
      builder: (context, child) {
        final blinkColor = Color.lerp(
          const Color(0xFFFFD538),
          const Color(0xFFE62718),
          _blink.value,
        )!;
        final glowColor = Color.lerp(
          const Color(0xCCFFE66A),
          const Color(0xDDFF2E18),
          _blink.value,
        )!;

        return LayoutBuilder(
          builder: (context, constraints) {
            const crossSpacing = 8.0;
            const mainSpacing = 8.0;
            final cellWidth =
                (constraints.maxWidth - 24 - crossSpacing * 2) / 3;
            final cellHeight = (constraints.maxHeight - mainSpacing) / 2;
            final aspectRatio = cellHeight <= 0
                ? 1.0
                : (cellWidth / cellHeight).clamp(0.74, 1.28);

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.faces.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                childAspectRatio: aspectRatio,
              ),
              itemBuilder: (context, index) {
                final face = widget.faces[index];
                final highlighted =
                    widget.highlightResults && widget.results.contains(face);

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEF7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: highlighted ? blinkColor : const Color(0xFF073A67),
                      width: highlighted ? 4 : 2,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        blurRadius: 6,
                        offset: Offset(0, 3),
                        color: Color(0x77000000),
                      ),
                      if (highlighted)
                        BoxShadow(
                          blurRadius: 18 + (_blink.value * 8),
                          spreadRadius: 2,
                          color: glowColor,
                        ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          face.symbolAsset,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      if (face == BauCuaFace.bau && widget.machineId != '---')
                        IgnorePointer(
                          child: Transform.translate(
                            offset: const Offset(0, 18),
                            child: Center(
                              child: Text(
                                widget.machineId,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color.fromARGB(234, 245, 213, 7),
                                  fontSize: 20,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x55000000),
                                      blurRadius: 4,
                                      offset: Offset(1, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
