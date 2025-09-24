import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Add the web configuration here
      return const FirebaseOptions(
        apiKey: "AIzaSyCnLPkg2BSXDIwsb97japTubvhTccv7rBQ",
        appId: "1:401495787930:web:YOUR_WEB_APP_ID", // Replace with your Web App ID
        messagingSenderId: "401495787930",
        projectId: "taskmanager-27315",
        authDomain: "taskmanager-27315.firebaseapp.com",
        storageBucket: "taskmanager-27315.appspot.com",
        measurementId: "G-YOURMEASUREMENTID" // This is optional
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: "AIzaSyAm0u41rcUhnVnyvA9cCvs5fIdT178NNic",
          appId: "1:401495787930:android:5e44fa46ea56a32d1e5223",
          messagingSenderId: "401495787930",
          projectId: "taskmanager-27315",
          storageBucket: "taskmanager-27315.firebasestorage.app",
        );

      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for iOS or macOS.',
        );

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}