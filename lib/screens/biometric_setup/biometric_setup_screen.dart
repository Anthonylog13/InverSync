import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../main_layout/main_layout_screen.dart';

/// Pantalla que aparece la PRIMERA VEZ después del login, ofreciendo al
/// usuario activar la protección biométrica de su portafolio.
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _isLoading = false;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available =
        await AuthService.instance.checkBiometricsAvailability();
    if (mounted) setState(() => _biometricsAvailable = available);
  }

  Future<void> _activateBiometrics() async {
    setState(() => _isLoading = true);

    try {
      final bool authenticated =
          await AuthService.instance.authenticateWithBiometrics(
        reason: 'Registra tu huella para proteger InverSync',
      );

      if (!mounted) return;

      if (authenticated) {
        // Guardar el flag y entrar al app
        await AuthService.instance.saveBiometricsSetup(value: true);
        if (!mounted) return;
        _goToMain();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo verificar la biometría. Intenta de nuevo.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skipSetup() {
    // Deja el flag en false (o inexistente) y entra igual
    _goToMain();
  }

  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
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

              // ── Ícono central ─────────────────────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(50),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.primary,
                  size: 52,
                ),
              ),
              const SizedBox(height: 32),

              // ── Textos ────────────────────────────────────────────────────
              Text(
                'Protege tu portafolio',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Activa Face ID o huella dactilar para que solo tú\npuedas ver tu patrimonio.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // ── Botón principal ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  // Deshabilitar si el dispositivo no tiene biometría
                  onPressed:
                      (_isLoading || !_biometricsAvailable)
                          ? null
                          : _activateBiometrics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.primary.withAlpha(80),
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
                      : const Icon(Icons.fingerprint_rounded),
                  label: Text(
                    _biometricsAvailable
                        ? 'Activar Face ID / Huella'
                        : 'Biometría no disponible',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Botón secundario ──────────────────────────────────────────
              TextButton(
                onPressed: _isLoading ? null : _skipSetup,
                child: Text(
                  'Hacerlo más tarde',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textSecondary,
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
