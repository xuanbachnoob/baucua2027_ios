import 'package:flutter/material.dart';

import '../models/bau_cua_face.dart';

class ResultRow extends StatelessWidget {
  const ResultRow({super.key, required this.results});

  final List<BauCuaFace>? results;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < 3; index++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ResultSlot(face: results?[index]),
          ),
      ],
    );
  }
}

class ResultSlot extends StatelessWidget {
  const ResultSlot({super.key, required this.face});

  final BauCuaFace? face;

  @override
  Widget build(BuildContext context) {
    final selectedFace = face;

    return SizedBox(
      width: 122,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF083A67), width: 2),
          boxShadow: const [
            BoxShadow(
              blurRadius: 7,
              offset: Offset(0, 4),
              color: Color(0x88000000),
            ),
          ],
        ),
        child: selectedFace == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  selectedFace.symbolAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
      ),
    );
  }
}
