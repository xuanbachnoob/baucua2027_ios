import 'dart:math';

import 'package:flutter/material.dart';

import '../models/bau_cua_face.dart';
import '../models/cup_state.dart';

class CupArea extends StatelessWidget {
  const CupArea({
    super.key,
    required this.results,
    required this.cupState,
    required this.shakeAnimation,
    required this.machineId,
  });

  final List<BauCuaFace> results;
  final CupState cupState;
  final Animation<double> shakeAnimation;
  final String machineId;

  @override
  Widget build(BuildContext context) {
    final covered = cupState != CupState.opened;

    return AnimatedBuilder(
      animation: shakeAnimation,
      builder: (context, child) {
        final shake = cupState == CupState.shaking
            ? sin(shakeAnimation.value * pi * 4) * 8
            : 0.0;
        return Transform.translate(offset: Offset(shake, 0), child: child);
      },
      child: Transform.translate(
        offset: const Offset(0, 0),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.scale(
                  scale: 1.04,
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/prop_plate.png',
                    width: 400,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: 1.1,
              child: SizedBox(
                width: 400,
                height: 270,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -20,
                      child: Image.asset(results[1].diceAsset, width: 140),
                    ),
                    Positioned(
                      left: 50,
                      bottom: 40,
                      child: Image.asset(results[0].diceAsset, width: 140),
                    ),
                    Positioned(
                      right: 50,
                      bottom: 40,
                      child: Image.asset(results[2].diceAsset, width: 140),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 620),
              reverseDuration: const Duration(milliseconds: 520),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.72, -1.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: covered
                  ? Transform.translate(
                      key: const ValueKey('bowl'),
                      offset: const Offset(0, -30),
                      child: Transform.scale(
                        scale: 1.18,
                        child: SizedBox(
                          width: 400,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Image.asset(
                                'assets/prop_bowl.png',
                                width: 400,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('empty-bowl'),
                      width: 400,
                      height: 270,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
