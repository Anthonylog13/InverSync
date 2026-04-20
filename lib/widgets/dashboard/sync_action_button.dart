import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SyncActionButton extends StatelessWidget {
  const SyncActionButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D05A), Color(0xFF009940)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(60),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background.withAlpha(50),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sync_rounded,
                color: AppColors.background,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sincronizar Criptos',
                    style: TextStyle(
                      color: AppColors.background,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Conectar con Binance API',
                    style: TextStyle(
                      color: AppColors.background.withAlpha(160),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.background.withAlpha(160),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
