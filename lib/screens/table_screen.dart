import 'package:flutter/material.dart';

import '../models/bau_cua_face.dart';
import '../models/cup_state.dart';
import '../models/rule_config.dart';
import '../widgets/control_row.dart';
import '../widgets/corner_glow_animation.dart';
import '../widgets/cup_area.dart';
import '../widgets/face_grid.dart';
import '../widgets/game_background.dart';
import '../widgets/game_button.dart';
import '../widgets/result_row.dart';
import '../widgets/scaled_game_frame.dart';

const openButtonSize = Size(220, 84);

CupOpenZone cupOpenZoneForPosition(Offset position) {
  if (position.dy >= openButtonSize.height * 0.6) {
    return CupOpenZone.bottom;
  }
  return position.dx < openButtonSize.width / 2
      ? CupOpenZone.left
      : CupOpenZone.right;
}

class TableScreen extends StatelessWidget {
  const TableScreen({
    super.key,
    required this.results,
    required this.shownResults,
    required this.faces,
    required this.cupState,
    required this.soundEnabled,
    required this.shakeAnimation,
    required this.onBack,
    required this.onToggleSound,
    required this.onShake,
    required this.onOpen,
    required this.machineStatusText,
    required this.machineId,
    required this.remoteControlled,
  });

  final List<BauCuaFace> results;
  final List<BauCuaFace>? shownResults;
  final List<BauCuaFace> faces;
  final CupState cupState;
  final bool soundEnabled;
  final Animation<double> shakeAnimation;
  final VoidCallback onBack;
  final VoidCallback onToggleSound;
  final VoidCallback onShake;
  final ValueChanged<CupOpenZone> onOpen;
  final String machineStatusText;
  final String machineId;
  final bool remoteControlled;

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      child: SafeArea(
        top: false,
        child: ScaledGameFrame(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: 128,
                      child: ResultRow(results: shownResults),
                    ),
                    const SizedBox(height: 52),
                    SizedBox(
                      height: 292,
                      child: CupArea(
                        results: results,
                        cupState: cupState,
                        shakeAnimation: shakeAnimation,
                        machineId: machineId,
                      ),
                    ),
                    const SizedBox(height: 62),
                    SizedBox(
                      height: 220,
                      child: Transform.translate(
                        offset: const Offset(0, -30),
                        child: FaceGrid(
                          faces: faces,
                          results: results,
                          highlightResults: cupState == CupState.opened,
                          machineId: machineId,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -25),
                      child: SizedBox(
                        height: openButtonSize.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            const Positioned(
                              left: 10,
                              bottom: -2,
                              child: CornerGlowAnimation(size: 88),
                            ),
                            const Positioned(
                              right: 10,
                              bottom: -2,
                              child: CornerGlowAnimation(
                                size: 88,
                                mirror: true,
                              ),
                            ),
                            GameButton(
                              label: cupState == CupState.opened ? 'XOC' : 'MO',
                              icon: cupState == CupState.opened
                                  ? Icons.casino_rounded
                                  : null,
                              onPressed: cupState == CupState.shaking
                                  ? null
                                  : cupState == CupState.opened
                                  ? onShake
                                  : () => onOpen(CupOpenZone.bottom),
                              onPressedAt: cupState == CupState.opened
                                  ? null
                                  : (position) => onOpen(
                                      cupOpenZoneForPosition(position),
                                    ),
                              secondary: cupState != CupState.opened,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 432,
                  left: 0,
                  right: 0,
                  child: ControlRow(
                    soundEnabled: soundEnabled,
                    onBack: onBack,
                    onToggleSound: onToggleSound,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Text(
                    machineStatusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFFF2F),
                      fontSize: 30,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      shadows: [
                        Shadow(
                          color: Color(0xFF001B38),
                          blurRadius: 3,
                          offset: Offset(2, 3),
                        ),
                        Shadow(
                          color: Color(0xFFFFFFFF),
                          blurRadius: 0,
                          offset: Offset(-1, -1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
