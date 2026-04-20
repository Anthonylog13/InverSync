import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../biometric_mock/biometric_mock_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              // Logo / ícono de marca
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
              // Título principal
              Text(
                'InverSync',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 8),
              // Subtítulo
              Text(
                'Tracker de Portafolio',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
              ),
              const Spacer(flex: 3),
              // Botón Google
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BiometricMockScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: _GoogleLogo(),
                label: const Text(
                  'Continuar con Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Disclaimer legal
              Text(
                'Al continuar aceptas los Términos de Servicio\ny la Política de Privacidad.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textDisabled,
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

/// Ícono de Google pintado con Canvas (sin dependencias externas).
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
