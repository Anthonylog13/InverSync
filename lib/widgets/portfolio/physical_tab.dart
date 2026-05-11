import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_event.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
import '../shared/portfolio_shared_widgets.dart';

class PhysicalTab extends StatelessWidget {
  const PhysicalTab({super.key});

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
          if (state.physicals.isEmpty) {
            return const Center(
              child: Text(
                'Sin bienes físicos registrados',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
            itemCount: state.physicals.length,
            itemBuilder: (context, i) {
              final asset = state.physicals[i];
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final bloc = context.read<PortfolioBloc>();
              return Dismissible(
                key: ValueKey(asset.id),
                direction: DismissDirection.endToStart,
                background: _DeleteBackground(),
                onDismissed: (_) => bloc.add(
                  DeleteAssetEvent(
                    uid: uid,
                    collection: 'physicals',
                    assetId: asset.id,
                  ),
                ),
                child: PhysicalCard(asset: asset),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
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

/// Fondo rojo de borrar visible al deslizar de derecha a izquierda.
class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.negative,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline_rounded,
          color: Colors.white, size: 26),
    );
  }
}
