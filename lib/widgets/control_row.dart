import 'package:flutter/material.dart';

import 'round_icon_button.dart';

class ControlRow extends StatelessWidget {
  const ControlRow({
    super.key,
    required this.soundEnabled,
    required this.onBack,
    required this.onToggleSound,
  });

  final bool soundEnabled;
  final VoidCallback onBack;
  final VoidCallback onToggleSound;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          RoundIconButton(
            tooltip: 'Menu',
            asset: 'assets/undo.png',
            onPressed: onBack,
          ),
          const Spacer(),
          RoundIconButton(
            tooltip: soundEnabled ? 'Tat nhac' : 'Bat nhac',
            asset: soundEnabled
                ? 'assets/volume-level.png'
                : 'assets/volume-level-mute.png',
            onPressed: onToggleSound,
          ),
        ],
      ),
    );
  }
}
