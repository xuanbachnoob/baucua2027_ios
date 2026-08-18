import 'dart:math';

import 'package:baucua2027_ios_game/models/bau_cua_face.dart';
import 'package:baucua2027_ios_game/models/rule_config.dart';
import 'package:baucua2027_ios_game/screens/table_screen.dart';
import 'package:baucua2027_ios_game/services/offline_law_generator.dart';
import 'package:baucua2027_ios_game/services/result_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('luat con roll uses previous result to force next target', () {
    const diceOrder = [
      BauCuaFace.bau,
      BauCuaFace.cua,
      BauCuaFace.tom,
      BauCuaFace.ca,
      BauCuaFace.ga,
      BauCuaFace.nai,
    ];
    const config = RemoteRuleConfig(
      luatCon: LuatConRule(
        enabled: true,
        allEnabled: false,
        n: 0,
        ruleId: 3,
        diceOrder: diceOrder,
        selectedCons: [null, null, null],
      ),
      luatCai: LuatCaiRule(enabled: false, sets: []),
      control: RemoteControlConfig(
        enabled: false,
        commandDigits: '',
        commandFaces: [],
        commandId: '',
      ),
    );
    final generator = ResultGenerator(Random(7));
    const faces = BauCuaFace.values;
    const previousResults = [BauCuaFace.ca, BauCuaFace.ca, BauCuaFace.tom];

    for (var index = 0; index < 100; index++) {
      final result = generator.roll(
        faces: faces,
        remoteConfig: config,
        online: true,
        machineId: '526',
        now: DateTime(2026, 6, 5, 10),
        previousResults: previousResults,
      );

      expect(result, contains(BauCuaFace.tom));
    }
  });

  test('luat con avoids selected face by A B C position', () {
    const config = RemoteRuleConfig(
      luatCon: LuatConRule(
        enabled: true,
        allEnabled: false,
        n: 0,
        ruleId: 3,
        diceOrder: [
          BauCuaFace.bau,
          BauCuaFace.cua,
          BauCuaFace.tom,
          BauCuaFace.ca,
          BauCuaFace.ga,
          BauCuaFace.nai,
        ],
        selectedCons: [BauCuaFace.cua, null, null],
      ),
      luatCai: LuatCaiRule(enabled: false, sets: []),
      control: RemoteControlConfig(
        enabled: false,
        commandDigits: '',
        commandFaces: [],
        commandId: '',
      ),
    );
    final generator = ResultGenerator(Random(11));

    for (var index = 0; index < 100; index++) {
      final result = generator.roll(
        faces: BauCuaFace.values,
        remoteConfig: config,
        online: true,
        machineId: '526',
        now: DateTime(2026, 6, 6, 10),
      );

      expect(result[0], isNot(BauCuaFace.cua));
    }
  });

  test('remote command parses faces without changing rule dice order', () {
    final config = RemoteRuleConfig.fromMap({
      'luatCon': {
        'diceOrder': ['nai', 'ga', 'ca', 'tom', 'cua', 'bau'],
      },
      'control': {
        'enabled': true,
        'command': {
          'digits': '000',
          'faces': ['bau', 'cua', 'tom'],
          'requestId': 'abc',
        },
      },
    });

    expect(config.control.commandFaces, [
      BauCuaFace.bau,
      BauCuaFace.cua,
      BauCuaFace.tom,
    ]);
    expect(config.luatCon.diceOrder.first, BauCuaFace.nai);
  });

  test('luat cai always blocks the selected pair for each open zone', () {
    const config = RemoteRuleConfig(
      luatCon: LuatConRule(
        enabled: false,
        allEnabled: false,
        n: 0,
        ruleId: 3,
        diceOrder: BauCuaFace.values,
        selectedCons: [null, null, null],
      ),
      luatCai: LuatCaiRule(
        enabled: true,
        sets: [
          [BauCuaFace.bau, BauCuaFace.cua],
          [BauCuaFace.tom, BauCuaFace.ca],
          [BauCuaFace.ga, BauCuaFace.nai],
        ],
      ),
      control: RemoteControlConfig(
        enabled: false,
        commandDigits: '',
        commandFaces: [],
        commandId: '',
      ),
    );
    final generator = ResultGenerator(Random(17));
    const blockedByZone = {
      CupOpenZone.left: [BauCuaFace.bau, BauCuaFace.cua],
      CupOpenZone.right: [BauCuaFace.tom, BauCuaFace.ca],
      CupOpenZone.bottom: [BauCuaFace.ga, BauCuaFace.nai],
    };

    for (final entry in blockedByZone.entries) {
      for (var index = 0; index < 100; index++) {
        final result = generator.roll(
          faces: BauCuaFace.values,
          remoteConfig: config,
          online: true,
          machineId: '526',
          now: DateTime(2026, 6, 6, 10),
          openZone: entry.key,
        );
        expect(result, isNot(contains(entry.value[0])));
        expect(result, isNot(contains(entry.value[1])));
      }
    }
  });

  test('open button maps every touch position to a stable zone', () {
    expect(cupOpenZoneForPosition(const Offset(20, 20)), CupOpenZone.left);
    expect(cupOpenZoneForPosition(const Offset(200, 20)), CupOpenZone.right);
    expect(cupOpenZoneForPosition(const Offset(20, 70)), CupOpenZone.bottom);
    expect(cupOpenZoneForPosition(const Offset(200, 70)), CupOpenZone.bottom);
    expect(cupOpenZoneForPosition(const Offset(110, 20)), CupOpenZone.right);
  });

  test('offline laws only use two or three dice formulas', () {
    for (var day = 1; day <= 30; day++) {
      for (var hour = 0; hour < 24; hour++) {
        final law = OfflineLawGenerator.generate(
          machineCode: '526',
          date: DateTime(2026, 6, day),
          hour: hour,
        );
        final diceCount = RegExp('[ABC]').allMatches(law.formula).length;
        expect(diceCount, greaterThanOrEqualTo(2));
      }
    }
  });

  test('offline law uses previous result to force next target', () {
    final now = DateTime(2026, 6, 6, 10);
    final law = OfflineLawGenerator.generate(
      machineCode: '526',
      date: now,
      hour: now.hour,
    );
    const previous = [BauCuaFace.bau, BauCuaFace.cua, BauCuaFace.tom];
    var total = law.n;
    if (law.formula.contains('A')) total += law.diceOrder.indexOf(previous[0]);
    if (law.formula.contains('B')) total += law.diceOrder.indexOf(previous[1]);
    if (law.formula.contains('C')) total += law.diceOrder.indexOf(previous[2]);
    final target = law.diceOrder[total % 6];
    final generator = ResultGenerator(Random(23));

    for (var index = 0; index < 100; index++) {
      final result = generator.roll(
        faces: BauCuaFace.values,
        remoteConfig: RemoteRuleConfig.empty(),
        online: false,
        machineId: '526',
        now: now,
        previousResults: previous,
      );
      expect(result, contains(target));
    }
  });
}
