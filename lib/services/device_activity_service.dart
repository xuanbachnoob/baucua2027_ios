import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceActivityService {
  DeviceActivityService({FirebaseFirestore? firestore})
    : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _instance => _firestore ?? FirebaseFirestore.instance;

  Future<void> reportOnline({
    required String machineId,
    required DateTime onlineStartedAt,
    required int shakeCount,
  }) {
    return _machine(machineId).set({
      'activity': {
        'online': true,
        'onlineStartedAt': Timestamp.fromDate(onlineStartedAt),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'shakeCount': shakeCount,
      },
    }, SetOptions(merge: true));
  }

  Future<void> reportOffline({
    required String machineId,
    required DateTime onlineStartedAt,
    required int shakeCount,
  }) {
    return _machine(machineId).set({
      'activity': {
        'online': false,
        'onlineStartedAt': Timestamp.fromDate(onlineStartedAt),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'shakeCount': shakeCount,
      },
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _machine(String machineId) {
    return _instance.collection('machines').doc(machineId);
  }
}
