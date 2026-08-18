import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/rule_config.dart';

class RuleSnapshot {
  const RuleSnapshot({
    required this.config,
    required this.online,
    required this.fromCache,
    required this.hasData,
    required this.serverUtc,
  });

  final RemoteRuleConfig config;
  final bool online;
  final bool fromCache;
  final bool hasData;
  final DateTime? serverUtc;
}

class RuleListenerService {
  RuleListenerService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<RuleSnapshot> watchMachine(String machineId) {
    return _firestore
        .collection('machines')
        .doc(machineId)
        .snapshots(includeMetadataChanges: true)
        .map(_snapshotFromDocument);
  }
}

RuleSnapshot _snapshotFromDocument(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  final fromCache = snapshot.metadata.isFromCache;
  final data = snapshot.data();
  return RuleSnapshot(
    config: RemoteRuleConfig.fromMap(data),
    online: kIsWeb ? data != null : !fromCache,
    fromCache: fromCache,
    hasData: data != null,
    serverUtc: null,
  );
}
