import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/dashboard/asset_distribution_chart.dart';
import '../../widgets/dashboard/balance_card.dart';
import '../../widgets/dashboard/sync_action_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Único estado local: índice del sector del gráfico que el usuario toca.
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        // ── Loading / Initial ─────────────────────────────────────────────
        if (state is PortfolioInitial || state is PortfolioLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // ── Error ─────────────────────────────────────────────────────────
        if (state is PortfolioError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error al cargar el portafolio:\n${state.message}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.negative, fontSize: 14),
              ),
            ),
          );
        }

        // ── Loaded ────────────────────────────────────────────────────────
        if (state is PortfolioLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                BalanceCard(
                  totalBalance: state.totalBalance,
                  isCopCurrency: state.isCopCurrency,
                ),
                const SizedBox(height: 16),
                SyncActionButton(onTap: () {}),
                const SizedBox(height: 28),
                Text(
                  'Distribución de activos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                AssetDistributionChart(
                  markets: state.markets,
                  loans: state.loans,
                  physicals: state.physicals,
                  totalBalance: state.totalBalance,
                  touchedIndex: _touchedIndex,
                  onTouch: (i) => setState(() => _touchedIndex = i),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

