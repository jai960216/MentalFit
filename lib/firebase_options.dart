// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSzbe81ggGmgZoBzqRB_9WTTRdui0iwN4',
    appId: '1:1063603907093:android:d76bbbc473d88ae26dfc1c',
    messagingSenderId: '1063603907093',
    projectId: 'mental-fit-78d5a',
    storageBucket: 'mental-fit-78d5a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDCmyZ9LerrE3ZCZVgKmMEkbtqAI7sFdzM',
    appId: '1:1063603907093:ios:f4b90dcf0a9f0e866dfc1c',
    messagingSenderId: '1063603907093',
    projectId: 'mental-fit-78d5a',
    storageBucket: 'mental-fit-78d5a.firebasestorage.app',
    androidClientId: '1063603907093-5f3t8hnqttp6ek980iufp2phu4mqsfpt.apps.googleusercontent.com',
    iosClientId: '1063603907093-lis30ejh0heka8rfuk9lkoar69b803rc.apps.googleusercontent.com',
    iosBundleId: 'com.mentalfit.sports',
  );

}