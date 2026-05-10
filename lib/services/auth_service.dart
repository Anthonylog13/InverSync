import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clave utilizada para persistir si el usuario ya configuró biometría.
const _kBiometricsSetup = 'has_biometrics_setup';

/// Servicio centralizado de autenticación e identidad biométrica.
///
/// Gestiona:
/// - Sign-in / sign-out con Firebase + Google.
/// - Verificación y autenticación biométrica con local_auth.
/// - Persistencia del flag de configuración biométrica en SharedPreferences.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _webClientId =
      '943067865641-ph404j5rt5bl9r5kh3l4messnldheclg.apps.googleusercontent.com';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
  );
  final LocalAuthentication _localAuth = LocalAuthentication();

  // ---------------------------------------------------------------------------
  // Autenticación con Google + Firebase
  // ---------------------------------------------------------------------------

  /// Lanza el flujo OAuth de Google y autentica al usuario en Firebase.
  ///
  /// Retorna el [User] autenticado, o lanza una [Exception] descriptiva.
  Future<User> signInWithGoogle() async {
    // 1. Iniciar flujo Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // El usuario canceló el selector de cuentas
      throw Exception('Inicio de sesión cancelado por el usuario.');
    }

    // 2. Obtener tokens de Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // 3. Construir credencial de Firebase
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Autenticar en Firebase
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    final User? user = userCredential.user;
    if (user == null) {
      throw Exception(
          'Firebase no retornó un usuario válido tras la autenticación.');
    }
    return user;
  }

  /// Cierra sesión en Firebase y en GoogleSignIn.
  /// También elimina el flag biométrico local para forzar reconfiguración.
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
    await clearBiometricsSetup();
  }

  /// Devuelve el usuario actualmente autenticado, o null si no hay sesión.
  User? get currentUser => _firebaseAuth.currentUser;

  // ---------------------------------------------------------------------------
  // Biometría (local_auth)
  // ---------------------------------------------------------------------------

  /// Retorna `true` si el dispositivo soporta biometría y tiene al menos
  /// una huella / Face ID enrolada.
  Future<bool> checkBiometricsAvailability() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) return false;
      final List<BiometricType> available =
          await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Solicita autenticación biométrica al usuario.
  ///
  /// [reason] es el texto mostrado en el diálogo del sistema.
  /// Retorna `true` si la autenticación fue exitosa.
  Future<bool> authenticateWithBiometrics({
    String reason = 'Confirma tu identidad para acceder a InverSync',
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true, // mantiene el diálogo si la app va a segundo plano
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Persistencia del flag biométrico (SharedPreferences)
  // ---------------------------------------------------------------------------

  /// Guarda en disco que el usuario ya configuró la biometría.
  Future<void> saveBiometricsSetup({required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricsSetup, value);
  }

  /// Lee desde disco si el usuario configuró la biometría.
  /// Retorna `false` si la clave aún no existe.
  Future<bool> hasBiometricsSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricsSetup) ?? false;
  }

  /// Elimina el flag biométrico (llamado al cerrar sesión).
  Future<void> clearBiometricsSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kBiometricsSetup);
  }
}
