import 'dart:math';

import 'package:flutter/material.dart';

const double designWidth = 430;
const double designHeight = 860;

class ScaledGameFrame extends StatelessWidget {
  const ScaledGameFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = min(
          constraints.maxWidth / designWidth,
          constraints.maxHeight / designHeight,
        );

        return Center(
          child: SizedBox(
            width: designWidth * scale,
            height: designHeight * scale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: designWidth,
                height: designHeight,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
