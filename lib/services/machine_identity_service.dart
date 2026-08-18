import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class MachineIdentityService {
  static const _machineIdKey = 'machine_id';

  Future<String> getOrCreateMachineId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_machineIdKey);
    if (existing != null && RegExp(r'^\d{3}$').hasMatch(existing)) {
      return existing;
    }

    final id = (100 + Random.secure().nextInt(900)).toString();
    await preferences.setString(_machineIdKey, id);
    return id;
  }
}
