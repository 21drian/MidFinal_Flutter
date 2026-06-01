import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'firebase_options.dart';
import 'screens/screens.dart';
import 'services/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable SQLite support for Windows/Linux desktop.
  // This is needed because sqflite alone mainly supports mobile.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Default Firebase app for your own Auth and TODO Firestore.
  await Firebase.initializeApp(options: FirebaseConfigs.personal);

  // Instructor Firebase app for Grades.
  // Keep this commented for now because grades will use mock API data first.
  // Uncomment only when your instructor gives you the Firebase/API config.
  // await Firebase.initializeApp(
  //   name: 'instructor',
  //   options: FirebaseConfigs.instructor,
  // );

  runApp(const MacalolotApp());
}

class MacalolotApp extends StatelessWidget {
  const MacalolotApp({super.key});

  static const _primary = Color(0xFFE6532E);
  static const _textDark = Color(0xFF2D2D2D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScoreMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: _textDark,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator(color: _primary)),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
