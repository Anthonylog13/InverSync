import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/portfolio/portfolio_bloc.dart';
import 'core/theme/app_theme.dart';
import 'screens/biometric_auth/biometric_auth_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/main_layout/main_layout_screen.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Determinar la pantalla inicial según el estado de sesión y biometría
  final Widget home = await _resolveInitialScreen();

  runApp(InverSyncApp(home: home));
}

/// Lógica de decisión de ruta inicial:
///
/// 1. ¿Hay sesión Firebase activa?
///    SÍ → ¿Tiene biometría configurada?
///          SÍ → BiometricAuthScreen (pantalla candado)
///          NO  → MainLayoutScreen  (entra directo)
///    NO  → LoginScreen
Future<Widget> _resolveInitialScreen() async {
  final User? user = FirebaseAuth.instance.currentUser;

  if (user == null) return const LoginScreen();

  final bool biometricsSetup = await AuthService.instance.hasBiometricsSetup();

  if (biometricsSetup) return const BiometricAuthScreen();

  return const MainLayoutScreen();
}

class InverSyncApp extends StatelessWidget {
  const InverSyncApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      // FirestoreService disponible para cualquier BLoC o widget descendiente
      create: (_) => FirestoreService(),
      child: BlocProvider(
        // PortfolioBloc recibe FirestoreService por DI.
        // La carga se dispara desde MainLayoutScreen cuando se conoce el UID.
        create: (ctx) => PortfolioBloc(
          firestoreService: ctx.read<FirestoreService>(),
        ),
        child: MaterialApp(
          title: 'InverSync',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: home,
        ),
      ),
    );
  }
}
