import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyBzUFee3fRLUuZdik6_PtcVzInPNZHRqWQ",
            authDomain: "map-pro-a3g76f.firebaseapp.com",
            projectId: "map-pro-a3g76f",
            storageBucket: "map-pro-a3g76f.firebasestorage.app",
            messagingSenderId: "968580739556",
            appId: "1:968580739556:web:c672fca96626ac863757f1"));
  } else {
    await Firebase.initializeApp();
  }
}
