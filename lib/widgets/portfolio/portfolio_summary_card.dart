import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/mock_portfolio_data.dart';

class PortfolioSummary extends StatelessWidget {
  const PortfolioSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SummaryItem(
            label: 'Activos',
            value: '${marketAssets.length + physicalAssets.length}',
          ),
          SummaryItem(
            label: 'Prestamos',
            value: '${loanAssets.length}',
            valueColor: AppColors.warning,
          ),
          const SummaryItem(
            label: 'Rentabilidad',
            value: '+8.43%',
            valueColor: AppColors.positive,
          ),
        ],
      ),
    );
  }
}

class SummaryItem extends StatelessWidget {
  const SummaryItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}
