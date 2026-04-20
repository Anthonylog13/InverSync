import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    required this.inCOP,
    required this.onToggleCurrency,
  });

  final String balance;
  final bool inCOP;
  final VoidCallback onToggleCurrency;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Portafolio total',
                  style: Theme.of(context).textTheme.bodyMedium),
              GestureDetector(
                onTap: onToggleCurrency,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _CurrencyChip(label: 'USD', active: !inCOP),
                      _CurrencyChip(label: 'COP', active: inCOP),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            balance,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 34,
                  letterSpacing: -1.5,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_upward_rounded,
                  color: AppColors.positive, size: 14),
              const SizedBox(width: 4),
              Text(
                '+2.34%  hoy',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.positive,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (inCOP) ...[
                const SizedBox(width: 8),
                Text(
                  '≈ TRM \$4,200',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textDisabled,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Privado: solo usado dentro de BalanceCard
class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: active ? AppColors.background : AppColors.textSecondary,
        ),
      ),
    );
  }
}
