import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
import '../../providers/portfolio_provider.dart';
import '../shared/portfolio_shared_widgets.dart';

class PhysicalTab extends StatelessWidget {
  const PhysicalTab({super.key});

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
      itemCount: provider.physicals.length,
      itemBuilder: (context, i) => PhysicalCard(asset: provider.physicals[i]),
    );
  }
}

class PhysicalCard extends StatelessWidget {
  const PhysicalCard({super.key, required this.asset});

  final PhysicalAsset asset;

  @override
  Widget build(BuildContext context) {
    final diff = asset.estimatedValue - asset.acquisitionValue;
    final isGain = diff >= 0;
    final pct = (diff / asset.acquisitionValue * 100).abs();

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
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(asset.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(asset.category,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: 6),
                    const AssetBadge(label: 'COP'),
                  ],
                ),
                const SizedBox(height: 3),
                Text('Compra: \$ ${_fmt(asset.acquisitionValue)}',
                    style: const TextStyle(
                        color: AppColors.textDisabled, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$ ${_fmt(asset.estimatedValue)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              ChangeBadge(
                value: '${isGain ? '+' : '-'}${pct.toStringAsFixed(1)}%',
                color: isGain ? AppColors.positive : AppColors.negative,
              ),
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
