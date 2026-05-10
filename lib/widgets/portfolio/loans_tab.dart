import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
import '../../providers/portfolio_provider.dart';
import '../shared/portfolio_shared_widgets.dart';

class LoansTab extends StatelessWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PortfolioProvider>();
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
      itemCount: provider.loans.length,
      itemBuilder: (context, i) => LoanCard(loan: provider.loans[i]),
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
