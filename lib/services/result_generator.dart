import 'dart:math';

import '../models/bau_cua_face.dart';
import '../models/rule_config.dart';
import 'offline_law_generator.dart';

class ResultGenerator {
  ResultGenerator(this._random);

  final Random _random;

  List<BauCuaFace> roll({
    required List<BauCuaFace> faces,
    required RemoteRuleConfig remoteConfig,
    required bool online,
    required String machineId,
    required DateTime now,
    CupOpenZone? openZone,
    List<BauCuaFace>? previousResults,
  }) {
    final luatCai = remoteConfig.luatCai;
    final blocked = online && luatCai.enabled && openZone != null
        ? luatCai.blockedFor(openZone)
        : const <BauCuaFace>[];

    if (online) {
      if (remoteConfig.luatCon.enabled) {
        return _rollByLuatCon(
          remoteConfig.luatCon,
          blocked,
          faces,
          previousResults,
        );
      }
      return _rollCandidate(faces, blocked);
    }

    final offlineLaw = OfflineLawGenerator.generate(
      machineCode: machineId,
      date: now,
      hour: now.hour,
    );
    return _rollByOfflineLaw(offlineLaw, blocked, faces, previousResults);
  }

  List<BauCuaFace> randomRoll(List<BauCuaFace> faces) {
    return List<BauCuaFace>.generate(
      3,
      (_) => faces[_random.nextInt(faces.length)],
    );
  }

  List<BauCuaFace> _rollByLuatCon(
    LuatConRule rule,
    List<BauCuaFace> blocked,
    List<BauCuaFace> fallbackFaces,
    List<BauCuaFace>? previousResults,
  ) {
    final target = previousResults == null || previousResults.length < 3
        ? null
        : rule.diceOrder[_formulaValue(
                rule.formula,
                previousResults,
                rule.n,
                rule.diceOrder,
              ) %
              6];

    for (var attempt = 0; attempt < 200; attempt++) {
      final candidate = _rollCandidate(fallbackFaces, blocked);
      if (_passesAvoid(candidate, rule.selectedCons)) {
        if (target == null) {
          return candidate;
        }
        if (!blocked.contains(target) && candidate.contains(target)) {
          return candidate;
        }
      }
    }

    return _rollCandidate(fallbackFaces, blocked);
  }

  List<BauCuaFace> _rollByOfflineLaw(
    OfflineLaw law,
    List<BauCuaFace> blocked,
    List<BauCuaFace> fallbackFaces,
    List<BauCuaFace>? previousResults,
  ) {
    final target = previousResults == null || previousResults.length < 3
        ? null
        : law.diceOrder[_formulaValue(
                law.formula,
                previousResults,
                law.n,
                law.diceOrder,
              ) %
              6];

    for (var attempt = 0; attempt < 200; attempt++) {
      final candidate = _rollCandidate(fallbackFaces, blocked);
      if (target == null || candidate.contains(target)) return candidate;
    }
    return _rollCandidate(fallbackFaces, blocked);
  }

  List<BauCuaFace> _rollCandidate(
    List<BauCuaFace> faces,
    List<BauCuaFace> blocked,
  ) {
    final allowed = faces.where((face) => !blocked.contains(face)).toList();
    final source = allowed.isEmpty ? faces : allowed;
    return List<BauCuaFace>.generate(
      3,
      (_) => source[_random.nextInt(source.length)],
    );
  }

  bool _passesAvoid(List<BauCuaFace> candidate, List<BauCuaFace?> avoids) {
    for (
      var index = 0;
      index < candidate.length && index < avoids.length;
      index++
    ) {
      final avoid = avoids[index];
      if (avoid != null && candidate[index] == avoid) return false;
    }
    return true;
  }

  int _formulaValue(
    String formula,
    List<BauCuaFace> dice,
    int n,
    List<BauCuaFace> diceOrder,
  ) {
    var total = n;
    if (formula.contains('A')) total += diceOrder.indexOf(dice[0]);
    if (formula.contains('B')) total += diceOrder.indexOf(dice[1]);
    if (formula.contains('C')) total += diceOrder.indexOf(dice[2]);
    return total;
  }
}
