// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDi-nRqOr4aXurdZPf_S9vknWeCX32ypo0', 
    appId: '1:4789177032:web:d1da86a028d1632fe3f3fd',
    messagingSenderId: '4789177032',
    projectId: 'aj-stocks-dcdc5',
    authDomain: 'aj-stocks-dcdc5.firebaseapp.com',
    storageBucket: 'aj-stocks-dcdc5.firebasestorage.app',
    databaseURL: 'https://aj-stocks-dcdc5-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDi-nRqOr4aXurdZPf_S9vknWeCX32ypo0', 
    appId: '1:4789177032:android:9c8da8f6430ae256e3f3fd',
    messagingSenderId: '4789177032',
    projectId: 'aj-stocks-dcdc5',
    storageBucket: 'aj-stocks-dcdc5.firebasestorage.app',
    databaseURL: 'https://aj-stocks-dcdc5-default-rtdb.firebaseio.com',
  );
}
