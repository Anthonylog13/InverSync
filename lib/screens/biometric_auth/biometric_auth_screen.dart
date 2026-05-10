import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import '../main_layout/main_layout_screen.dart';

/// Pantalla candado para usuarios RECURRENTES con sesión Firebase activa.
///
/// Dispara automáticamente el prompt biométrico del sistema al abrirse.
/// Si el usuario cancela o falla, muestra opciones de reintentar o cerrar sesión.
class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isAuthenticating = false;
  bool _failed = false;

  // Animación de pulso en el ícono de huella
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    // Disparar la autenticación al montar el widget
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _failed = false;
    });

    try {
      final bool success =
          await AuthService.instance.authenticateWithBiometrics(
        reason: 'Usa tu huella o Face ID para desbloquear InverSync',
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
        );
      } else {
        setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Ícono pulsante ────────────────────────────────────────────
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _failed ? AppColors.negative : AppColors.primary,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_failed ? AppColors.negative : AppColors.primary)
                            .withAlpha(60),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    color:
                        _failed ? AppColors.negative : AppColors.primary,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Texto principal ───────────────────────────────────────────
              Text(
                _failed ? 'No se pudo verificar' : 'Bienvenido de nuevo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _failed
                    ? 'La autenticación falló o fue cancelada.'
                    : 'Coloca tu dedo en el sensor o mira la cámara para desbloquear tu portafolio.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // ── Botones (visibles solo cuando falla) ──────────────────────
              if (_failed) ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.background,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'Reintentar',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: _isAuthenticating ? null : _signOut,
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.negative, size: 18),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: AppColors.negative,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],

              // ── Indicador cuando está procesando (antes del primer fallo) ──
              if (_isAuthenticating && !_failed)
                const CircularProgressIndicator(color: AppColors.primary),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
