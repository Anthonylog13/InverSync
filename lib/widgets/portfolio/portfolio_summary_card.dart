import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';

class PortfolioSummary extends StatelessWidget {
  const PortfolioSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        final markets = state is PortfolioLoaded ? state.markets.length : 0;
        final physicals = state is PortfolioLoaded ? state.physicals.length : 0;
        final loans = state is PortfolioLoaded ? state.loans.length : 0;
        final roi = state is PortfolioLoaded ? state.roiPercent : 0.0;
        final roiColor = roi >= 0 ? AppColors.positive : AppColors.negative;
        final roiLabel =
            '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(2)}%';

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
                value: '${markets + physicals}',
              ),
              SummaryItem(
                label: 'Préstamos',
                value: '$loans',
                valueColor: AppColors.warning,
              ),
              SummaryItem(
                label: 'Rentabilidad',
                value: roiLabel,
                valueColor: roiColor,
              ),
            ],
          ),
        );
      },
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
