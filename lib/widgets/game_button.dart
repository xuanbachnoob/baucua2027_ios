import 'package:flutter/material.dart';

class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.onPressedAt,
    this.secondary = false,
    this.width = 220,
    this.height = 84,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ValueChanged<Offset>? onPressedAt;
  final bool secondary;
  final double width;
  final double height;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final asset = widget.secondary ? 'assets/btn_mo.png' : 'assets/btn_xoc.png';

    return Center(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: enabled
              ? (event) {
                  final onPressedAt = widget.onPressedAt;
                  if (onPressedAt != null) {
                    onPressedAt(event.localPosition);
                  } else {
                    widget.onPressed?.call();
                  }
                }
              : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.65,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
