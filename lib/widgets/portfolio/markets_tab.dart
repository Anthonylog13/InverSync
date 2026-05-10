import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
import '../../providers/portfolio_provider.dart';
import '../shared/portfolio_shared_widgets.dart';

class MarketsTab extends StatelessWidget {
  const MarketsTab({super.key});

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
      itemCount: provider.markets.length,
      itemBuilder: (context, i) => MarketCard(asset: provider.markets[i]),
    );
  }
}

class MarketCard extends StatelessWidget {
  const MarketCard({super.key, required this.asset});

  final MarketAsset asset;

  static const double _usdToCop = 4200;

  @override
  Widget build(BuildContext context) {
    final isPos = asset.changePercent >= 0;
    final changeColor = isPos ? AppColors.positive : AppColors.negative;
    final sign = isPos ? '+' : '';
    final double valueUsd = asset.currency == 'COP'
        ? (asset.price * asset.quantity) / _usdToCop
        : asset.price * asset.quantity;

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
                    Text(
                      '${asset.ticker}  \u00b7  ${_qty(asset.quantity)} uds.',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    AssetBadge(label: asset.currency),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '\u2248 USD ${_price(valueUsd)}',
                  style: const TextStyle(
                      color: AppColors.textDisabled, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$ ${_price(asset.price)}',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              ChangeBadge(
                value: '$sign${asset.changePercent.toStringAsFixed(2)}%',
                color: changeColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _price(double p) {
    if (p >= 1000) {
      return p
          .toStringAsFixed(2)
          .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
    }
    return p.toStringAsFixed(2);
  }

  String _qty(double q) =>
      q == q.truncate() ? q.toInt().toString() : q.toStringAsFixed(4);
}
