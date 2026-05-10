import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
import '../shared/portfolio_shared_widgets.dart';

class LoansTab extends StatelessWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoading || state is PortfolioInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is PortfolioError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: AppColors.negative),
            ),
          );
        }
        if (state is PortfolioLoaded) {
          if (state.loans.isEmpty) {
            return const Center(
              child: Text(
                'Sin préstamos registrados',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
            itemCount: state.loans.length,
            itemBuilder: (context, i) => LoanCard(loan: state.loans[i]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class LoanCard extends StatelessWidget {
  const LoanCard({super.key, required this.loan});

  final LoanAsset loan;

  @override
  Widget build(BuildContext context) {
    final accrued =
        loan.amount * (loan.monthlyRate / 100) * loan.monthsElapsed;
    final total = loan.amount + accrued;
    final hasInterest = loan.monthlyRate > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(loan.icon, color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loan.label,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(loan.borrower,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('${loan.monthsElapsed} mes(es)',
                        style: const TextStyle(
                            color: AppColors.textDisabled, fontSize: 11)),
                    const SizedBox(width: 6),
                    if (hasInterest)
                      AssetBadge(
                        label: '${loan.monthlyRate}% /mes',
                        color: AppColors.warning,
                      )
                    else
                      const AssetBadge(label: 'Sin interes'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$ ${_fmt(total)} COP',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              if (hasInterest) ...[
                const SizedBox(height: 3),
                Text('+\$ ${_fmt(accrued)} int.',
                    style: const TextStyle(
                        color: AppColors.warning, fontSize: 11)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}
