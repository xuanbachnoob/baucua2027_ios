import 'dart:async';

import 'package:flutter/widgets.dart';

class AssetPreloader {
  AssetPreloader._();

  static bool _started = false;
  static Future<void>? _future;

  static const List<String> imageAssets = [
    'assets/hinh_cho.png',
    'assets/btn_choi.png',
    'assets/btn_thoat.png',
    'assets/btn_xoc.png',
    'assets/btn_mo.png',
    'assets/undo.png',
    'assets/volume-level.png',
    'assets/volume-level-mute.png',
    'assets/background.png',
    'assets/background-vang-cam.png',
    'assets/prop_plate.png',
    'assets/prop_bowl.png',
    'assets/symbol_bau.png',
    'assets/symbol_cua.png',
    'assets/symbol_tom.png',
    'assets/symbol_ca.png',
    'assets/symbol_ga.png',
    'assets/symbol_nai.png',
    'assets/dice_bau.png',
    'assets/dice_cua.png',
    'assets/dice_tom.png',
    'assets/dice_ca.png',
    'assets/dice_ga.png',
    'assets/dice_nai.png',
    'assets/corner_glow_1.png',
    'assets/corner_glow_2.png',
    'assets/corner_glow_3.png',
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

  static Future<void> start(BuildContext context) {
    if (_started) return _future ?? Future.value();
    _started = true;
    _future = _precache(context);
    return _future!;
  }

  static Future<void> _precache(BuildContext context) async {
    final futures = <Future<void>>[];
    for (final asset in imageAssets) {
      futures.add(precacheImage(AssetImage(asset), context).catchError((_) {}));
    }
    await Future.wait(futures);
  }
}
