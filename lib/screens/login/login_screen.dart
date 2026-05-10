import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../biometric_auth/biometric_auth_screen.dart';
import '../biometric_setup/biometric_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Autenticación con Google + Firebase
      await AuthService.instance.signInWithGoogle();

      // 2. Decidir a qué pantalla navegar según el flag biométrico
      final bool biometricsSetup =
          await AuthService.instance.hasBiometricsSetup();

      if (!mounted) return;

      if (biometricsSetup) {
        // Ya configuró biometría → pedir huella para desbloquear
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BiometricAuthScreen()),
        );
      } else {
        // Primera vez → ofrecer configurar biometría
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BiometricSetupScreen()),
        );
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo ──────────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),

              // ── Título ────────────────────────────────────────────────────
              Text(
                'InverSync',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 8),

              Text(
                'tu portafolio de inversión en un solo lugar',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
              ),

              const Spacer(flex: 3),

              // ── Error inline ──────────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.negative.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.negative),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.negative, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: AppColors.negative, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Botón Google ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.primary.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.background,
                          ),
                        )
                      : _GoogleLogo(),
                  label: Text(
                    _isLoading ? 'Iniciando sesión...' : 'Continuar con Google',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget interno: logo "G" de Google ──────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

