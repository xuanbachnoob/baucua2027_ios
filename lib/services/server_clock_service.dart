import 'package:cloud_firestore/cloud_firestore.dart';

class ServerClockService {
  ServerClockService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DateTime?> fetchServerUtc({String? machineId}) async {
    return _fetchFromRuntime();
  }

  Future<DateTime?> _fetchFromRuntime() async {
    final doc = _firestore.collection('_runtime').doc('server_clock');
    await doc.set({
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final snapshot = await doc.get(const GetOptions(source: Source.server));
    final value = snapshot.data()?['updatedAt'];
    if (value is Timestamp) {
      return value.toDate().toUtc();
    }
    return null;
  }
}
