import 'package:cloud_firestore/cloud_firestore.dart';

import 'bau_cua_face.dart';

enum CupOpenZone { left, right, bottom }

class LuatConRule {
  const LuatConRule({
    required bool enabled,
    required this.allEnabled,
    required this.n,
    required this.ruleId,
    required this.diceOrder,
    required this.selectedCons,
    this.expiresAt,
  }) : _enabled = enabled;

  factory LuatConRule.initial() {
    return const LuatConRule(
      enabled: false,
      allEnabled: false,
      n: 4,
      ruleId: 3,
      diceOrder: [
        BauCuaFace.bau,
        BauCuaFace.cua,
        BauCuaFace.tom,
        BauCuaFace.ca,
        BauCuaFace.ga,
        BauCuaFace.nai,
      ],
      selectedCons: [null, null, null],
    );
  }

  factory LuatConRule.fromMap(Map<String, dynamic>? data) {
    if (data == null) return LuatConRule.initial();
    return LuatConRule(
      enabled: _readBool(data, ['enabled', 'luatConEnabled']),
      allEnabled: _readBool(data, ['allEnabled']),
      n: _readInt(data['n'], 4).clamp(0, 5),
      ruleId: _readInt(data['ruleId'], 3).clamp(1, 5),
      diceOrder: _readFaceList(
        data['diceOrder'],
        LuatConRule.initial().diceOrder,
      ),
      selectedCons: _readNullableFaceList(
        data['selectedCons'] ??
            [data['avoidA'], data['avoidB'], data['avoidC']],
      ),
      expiresAt: _readDateTime(data['expiresAt']),
    );
  }

  final bool _enabled;
  final bool allEnabled;
  final int n;
  final int ruleId;
  final List<BauCuaFace> diceOrder;
  final List<BauCuaFace?> selectedCons;
  final DateTime? expiresAt;

  bool get enabled => _enabled && !_isExpired(expiresAt);

  String get formula {
    return switch (ruleId) {
      1 => 'A + B + N',
      2 => 'B + C + N',
      3 => 'A + B + C + N',
      4 => 'A + C + N',
      5 => 'B + N',
      _ => 'A + B + C + N',
    };
  }
}

class LuatCaiRule {
  const LuatCaiRule({
    required bool enabled,
    required this.sets,
    this.expiresAt,
  }) : _enabled = enabled;

  factory LuatCaiRule.initial() {
    return const LuatCaiRule(
      enabled: false,
      sets: [
        [BauCuaFace.nai, BauCuaFace.bau],
        [BauCuaFace.ca, BauCuaFace.ga],
        [BauCuaFace.cua, BauCuaFace.tom],
      ],
    );
  }

  factory LuatCaiRule.fromMap(Map<String, dynamic>? data) {
    if (data == null) return LuatCaiRule.initial();
    final initial = LuatCaiRule.initial();
    return LuatCaiRule(
      enabled: _readBool(data, ['enabled']),
      sets: _readSets(data['sets'], initial.sets),
      expiresAt: _readDateTime(data['expiresAt']),
    );
  }

  final bool _enabled;
  final List<List<BauCuaFace>> sets;
  final DateTime? expiresAt;

  bool get enabled => _enabled && !_isExpired(expiresAt);

  List<BauCuaFace> blockedFor(CupOpenZone zone) {
    final index = switch (zone) {
      CupOpenZone.left => 0,
      CupOpenZone.right => 1,
      CupOpenZone.bottom => 2,
    };
    return sets.length > index ? sets[index] : const [];
  }
}

class RemoteControlConfig {
  const RemoteControlConfig({
    required this.enabled,
    required this.commandDigits,
    required this.commandFaces,
    required this.commandId,
  });

  factory RemoteControlConfig.empty() {
    return const RemoteControlConfig(
      enabled: false,
      commandDigits: '',
      commandFaces: [],
      commandId: '',
    );
  }

  factory RemoteControlConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return RemoteControlConfig.empty();
    final command = _readMap(data['command']);
    return RemoteControlConfig(
      enabled: _readBool(data, ['enabled']),
      commandDigits: _readString(command?['digits']),
      commandFaces: _readCommandFaces(command?['faces']),
      commandId: _readString(command?['requestId']),
    );
  }

  final bool enabled;
  final String commandDigits;
  final List<BauCuaFace> commandFaces;
  final String commandId;
}

class RemoteRuleConfig {
  const RemoteRuleConfig({
    required this.luatCon,
    required this.luatCai,
    required this.control,
  });

  factory RemoteRuleConfig.empty() {
    return RemoteRuleConfig(
      luatCon: LuatConRule.initial(),
      luatCai: LuatCaiRule.initial(),
      control: RemoteControlConfig.empty(),
    );
  }

  factory RemoteRuleConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return RemoteRuleConfig.empty();
    return RemoteRuleConfig(
      luatCon: LuatConRule.fromMap(_readMap(data['luatCon'])),
      luatCai: LuatCaiRule.fromMap(_readMap(data['luatCai'])),
      control: RemoteControlConfig.fromMap(_readMap(data['control'])),
    );
  }

  final LuatConRule luatCon;
  final LuatCaiRule luatCai;
  final RemoteControlConfig control;
}

Map<String, dynamic>? _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

bool _readBool(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == 'bat' || normalized == 'bật') {
        return true;
      }
    }
  }
  return false;
}

int _readInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) return DateTime.tryParse(value);
  return null;
}

bool _isExpired(DateTime? value) {
  return value != null && !value.isAfter(DateTime.now());
}

String _readString(Object? value) {
  return value is String ? value : '';
}

List<BauCuaFace> _readFaceList(Object? value, List<BauCuaFace> fallback) {
  if (value is! List) return List<BauCuaFace>.from(fallback);
  final faces = value.map(_faceFromValue).whereType<BauCuaFace>().toList();
  return faces.length == 6 ? faces : List<BauCuaFace>.from(fallback);
}

List<BauCuaFace> _readCommandFaces(Object? value) {
  if (value is! List) return const [];
  return value.map(_faceFromValue).whereType<BauCuaFace>().take(3).toList();
}

List<BauCuaFace?> _readNullableFaceList(Object? value) {
  final values = value is List ? value : const [];
  final faces = [
    for (var index = 0; index < 3; index++)
      index < values.length ? _faceFromValue(values[index]) : null,
  ];
  return faces;
}

List<List<BauCuaFace>> _readSets(
  Object? value,
  List<List<BauCuaFace>> fallback,
) {
  if (value is! List) {
    return fallback.map((set) => List<BauCuaFace>.from(set)).toList();
  }

  final sets = <List<BauCuaFace>>[];
  for (final rawSet in value) {
    final rawFaces = rawSet is Map ? rawSet['faces'] : rawSet;
    if (rawFaces is! List) continue;
    final set = rawFaces.map(_faceFromValue).whereType<BauCuaFace>().toList();
    if (set.length == 2) sets.add(set);
  }

  return sets.length == 3
      ? sets
      : fallback.map((set) => List<BauCuaFace>.from(set)).toList();
}

BauCuaFace? _faceFromValue(Object? value) {
  if (value is BauCuaFace) return value;
  if (value is! String) return null;
  final normalized = value
      .toLowerCase()
      .replaceAll('assets/', '')
      .replaceAll('dice_', '')
      .replaceAll('symbol_', '')
      .replaceAll('.png', '')
      .trim();
  return BauCuaFace.values.cast<BauCuaFace?>().firstWhere(
    (face) => face?.assetName == normalized,
    orElse: () => null,
  );
}
