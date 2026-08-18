import 'package:flutter/material.dart';

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.tooltip,
    required this.asset,
    required this.onPressed,
    this.dimmed = false,
  });

  final String tooltip;
  final String asset;
  final VoidCallback onPressed;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 70,
        height: 70,
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Opacity(
            opacity: dimmed ? 0.55 : 1,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
