import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
import '../shared/portfolio_shared_widgets.dart';

class MarketsTab extends StatelessWidget {
  const MarketsTab({super.key});

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
          if (state.markets.isEmpty) {
            return const Center(
              child: Text(
                'Sin activos de mercado',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
            itemCount: state.markets.length,
            itemBuilder: (context, i) =>
                MarketCard(asset: state.markets[i], isCopCurrency: state.isCopCurrency),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class MarketCard extends StatelessWidget {
  const MarketCard({
    super.key,
    required this.asset,
    this.isCopCurrency = true,
  });

  final MarketAsset asset;
  final bool isCopCurrency;

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
              color: _tickerColor(asset.ticker),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _tickerInitials(asset.ticker),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
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

  // ── Avatar helpers ────────────────────────────────────────────────────────

  static const _avatarColors = [
    Color(0xFF1A3A5C), // azul marino
    Color(0xFF4A235A), // morado oscuro
    Color(0xFF7B3F00), // naranja quemado
    Color(0xFF145A32), // verde esmeralda
    Color(0xFF1B2631), // azul pizarra
    Color(0xFF6E2C00), // caoba
  ];

  /// Extrae 1-2 iniciales del ticker descartando el sufijo tras el punto.
  /// "ECOPETROL.CL" → "EC" | "BTC-USD" → "BT" | "AAPL" → "AA"
  static String _tickerInitials(String ticker) {
    final base = ticker.split('.').first.split('-').first;
    return base.length >= 2
        ? base.substring(0, 2).toUpperCase()
        : base.toUpperCase();
  }

  /// Elige un color de [_avatarColors] de forma determinista según el ticker.
  static Color _tickerColor(String ticker) {
    final idx = ticker.hashCode.abs() % _avatarColors.length;
    return _avatarColors[idx];
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
