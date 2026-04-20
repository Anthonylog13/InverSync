// import 'package:firebase_core/firebase_core.dart'; // TODO: habilitar tras flutterfire configure
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/login/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // TODO: habilitar tras flutterfire configure
  runApp(const InverSyncApp());
}

class InverSyncApp extends StatelessWidget {
  const InverSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InverSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
