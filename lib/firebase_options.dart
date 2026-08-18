import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCKvmHoA-GkB-CB4G5-PY_ks_6C0fFS8SE',
    appId: '1:304108838218:android:d618c99a094cfc8ceb35b3',
    messagingSenderId: '304108838218',
    projectId: 'baucua2027-ios',
    authDomain: 'baucua2027-ios.firebaseapp.com',
    storageBucket: 'baucua2027-ios.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKvmHoA-GkB-CB4G5-PY_ks_6C0fFS8SE',
    appId: '1:304108838218:android:d618c99a094cfc8ceb35b3',
    messagingSenderId: '304108838218',
    projectId: 'baucua2027-ios',
    storageBucket: 'baucua2027-ios.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDRPPluMra2jMzm4qAvv2dGS36aGVcnPqc',
    appId: '1:304108838218:ios:80b43e7a106c2404eb35b3',
    messagingSenderId: '304108838218',
    projectId: 'baucua2027-ios',
    storageBucket: 'baucua2027-ios.firebasestorage.app',
    iosBundleId: 'com.baucua2027ios.game',
  );
}
