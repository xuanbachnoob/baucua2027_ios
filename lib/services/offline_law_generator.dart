import '../models/bau_cua_face.dart';

class OfflineLaw {
  const OfflineLaw({
    required this.machineCode,
    required this.day,
    required this.hour,
    required this.diceOrder,
    required this.formula,
    required this.n,
    required this.avoidNumber,
    required this.avoidFace,
    required this.checkHack,
  });

  final String machineCode;
  final int day;
  final int hour;
  final List<BauCuaFace> diceOrder;
  final String formula;
  final int n;
  final int avoidNumber;
  final BauCuaFace avoidFace;
  final String checkHack;

  String get formulaWithN => '$formula + $n';
}

class OfflineLawGenerator {
  static const _secret = 'baucua2027-ios-am1-offline-v1';
  static const _vietnamOffset = Duration(hours: 7);

  static const diceFaces = [
    BauCuaFace.bau,
    BauCuaFace.cua,
    BauCuaFace.tom,
    BauCuaFace.ca,
    BauCuaFace.ga,
    BauCuaFace.nai,
  ];

  static const formulas = ['A + B', 'B + C', 'A + C', 'A + B + C'];

  static List<OfflineLaw> generateForDay({
    required String machineCode,
    required DateTime date,
    int? startHour,
    int maxCount = 3,
  }) {
    final firstHour = startHour ?? date.hour;
    final lastHour = (firstHour + maxCount - 1).clamp(0, 23);
    return [
      for (var hour = firstHour; hour <= lastHour; hour++)
        generate(machineCode: machineCode, date: date, hour: hour),
    ];
  }

  static OfflineLaw generate({
    required String machineCode,
    required DateTime date,
    required int hour,
  }) {
    final lawSeed = _hash(
      '$_secret|$machineCode|${date.year}|${date.month}|'
      '${date.day}|$hour',
    );
    final random = _SeededRandom(lawSeed);
    final diceOrder = List<BauCuaFace>.from(diceFaces);

    for (var index = diceOrder.length - 1; index > 0; index--) {
      final swapIndex = random.nextInt(index + 1);
      final current = diceOrder[index];
      diceOrder[index] = diceOrder[swapIndex];
      diceOrder[swapIndex] = current;
    }

    final n = (hour + 1) % 6;
    final avoidNumber = hour % 6;
    final formula = formulas[random.nextInt(formulas.length)];
    final checkHack = generateCheckHack(date: date, hour: hour);

    return OfflineLaw(
      machineCode: machineCode,
      day: date.day,
      hour: hour,
      diceOrder: diceOrder,
      formula: formula,
      n: n,
      avoidNumber: avoidNumber,
      avoidFace: diceOrder[avoidNumber],
      checkHack: checkHack,
    );
  }

  static String generateCheckHack({required DateTime date, required int hour}) {
    final checkSeed = _hash(
      '$_secret|check-hack|${date.year}|${date.month}|${date.day}|$hour',
    );
    return (checkSeed % 1000).toString().padLeft(3, '0');
  }

  static DateTime vietnamNow() {
    final value = DateTime.now().toUtc().add(_vietnamOffset);
    return DateTime(value.year, value.month, value.day, value.hour);
  }

  static String currentCheckHack() {
    final now = vietnamNow();
    return generateCheckHack(date: now, hour: now.hour);
  }

  static int _hash(String value) {
    var hash = BigInt.from(0x811C9DC5);
    final prime = BigInt.from(0x01000193);
    final mask = BigInt.from(0xFFFFFFFF);
    for (final unit in value.codeUnits) {
      hash = hash ^ BigInt.from(unit);
      hash = (hash * prime) & mask;
    }
    return hash == BigInt.zero ? 0x6D2B79F5 : hash.toInt();
  }
}

class _SeededRandom {
  _SeededRandom(this._state);

  int _state;

  int nextInt(int max) {
    _state ^= (_state << 13) & 0xFFFFFFFF;
    _state ^= _state >>> 17;
    _state ^= (_state << 5) & 0xFFFFFFFF;
    _state &= 0xFFFFFFFF;
    return _state % max;
  }
}
