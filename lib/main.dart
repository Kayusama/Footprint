import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:footprint3/landing_page.dart';
import 'package:footprint3/login_page.dart';
import 'package:footprint3/utils.dart';
import 'package:flutter/foundation.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyCzBKV8nDLfoEW8P-qN8kZQq4vQLKbFsu4",
          authDomain: "footprint-b00bs.firebaseapp.com",
          databaseURL: "https://footprint-b00bs-default-rtdb.asia -southeast1.firebasedatabase.app",
          projectId: "footprint-b00bs",
          storageBucket: "footprint-b00bs.firebasestorage.app",
          messagingSenderId: "688442946572",
          appId: "1:688442946572:web:af2f04c4894873a2212a29",
          ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Footprint',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.orange,
          backgroundColor: backgroundColor,
        ),
        useMaterial3: true,
      ),
      // showPerformanceOverlay: true,
      home: kIsWeb
          ? const FootprintLandingPage()
          : const LoginPage(),
    );
  }
}
