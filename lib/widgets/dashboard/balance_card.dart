import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_event.dart';
import '../../core/theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.isCopCurrency,
    required this.roiPercent,
  });

  /// Balance total en USD proveniente del estado [PortfolioLoaded].
  final double totalBalance;

  /// Si es true, el balance se muestra en COP; de lo contrario en USD.
  final bool isCopCurrency;

  /// Rentabilidad global calculada por el BLoC.
  final double roiPercent;

  static const double _usdToCop = 4200;

  String get _displayBalance {
    if (isCopCurrency) {
      return '\$ ${_fmt(totalBalance * _usdToCop)} COP';
    }
    return '\$ ${_fmt(totalBalance)} USD';
  }

  static String _fmt(double n) {
    final parts = n.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

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
              // Toggle: despacha ToggleCurrencyEvent al BLoC
              GestureDetector(
                onTap: () => context
                    .read<PortfolioBloc>()
                    .add(const ToggleCurrencyEvent()),
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
                      _CurrencyChip(label: 'USD', active: !isCopCurrency),
                      _CurrencyChip(label: 'COP', active: isCopCurrency),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _displayBalance,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 34,
                  letterSpacing: -1.5,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                roiPercent >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: roiPercent >= 0
                    ? AppColors.positive
                    : AppColors.negative,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${roiPercent >= 0 ? '+' : ''}'  
                '${roiPercent.toStringAsFixed(2)}%  ROI total',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: roiPercent >= 0
                          ? AppColors.positive
                          : AppColors.negative,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (isCopCurrency) ...[
                const SizedBox(width: 8),
                Text(
                  '≈ TRM \$${_fmt(_usdToCop)}',
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
