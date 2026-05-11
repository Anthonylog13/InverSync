import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
import '../../widgets/dashboard/asset_distribution_chart.dart';
import '../../widgets/dashboard/balance_card.dart';
import '../../widgets/dashboard/portfolio_line_chart.dart';
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
                  roiPercent: state.roiPercent,
                ),
                const SizedBox(height: 16),
                PortfolioLineChart(movements: state.movements),
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
                const SizedBox(height: 28),
                Text(
                  'Proyecciones',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _ProjectionsCard(
                  loans: state.loans,
                  physicals: state.physicals,
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

// ---------------------------------------------------------------------------
// Widget de proyecciones de flujo de caja mensual
// ---------------------------------------------------------------------------

class _ProjectionsCard extends StatelessWidget {
  const _ProjectionsCard({
    required this.loans,
    required this.physicals,
  });

  final List<LoanAsset> loans;
  final List<PhysicalAsset> physicals;

  @override
  Widget build(BuildContext context) {
    // Intereses mensuales estimados de todos los préstamos vigentes.
    final loanInterestMonthly = loans.fold(0.0, (sum, l) {
      if (l.monthlyRate <= 0 || l.outstandingPrincipal <= 0) return sum;
      return sum + l.outstandingPrincipal * (l.monthlyRate / 100.0);
    });

    // Rentas mensuales de bienes físicos con arriendo activo.
    final rentMonthly = physicals.fold(0.0, (sum, p) {
      if (!p.hasRent || p.rentAmount == null) return sum;
      return sum + p.rentAmount!;
    });

    final totalMonthly = loanInterestMonthly + rentMonthly;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Flujo de Caja Mensual Estimado',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),
          // Fila: intereses de préstamos
          _ProjectionRow(
            icon: Icons.handshake_outlined,
            label: 'Intereses de préstamos',
            amount: loanInterestMonthly,
          ),
          const SizedBox(height: 10),
          // Fila: rentas de bienes físicos
          _ProjectionRow(
            icon: Icons.landscape_rounded,
            label: 'Rentas de bienes físicos',
            amount: rentMonthly,
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),
          // Total mensual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total mensual',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                '\$ ${_fmtCop(totalMonthly)} COP',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (totalMonthly > 0) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '≈ \$ ${_fmtCop(totalMonthly * 12)} COP / año',
                style: const TextStyle(
                    color: AppColors.textDisabled, fontSize: 11),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            const Text(
              'Registra préstamos con tasa o bienes con arriendo para ver proyecciones.',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtCop(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

class _ProjectionRow extends StatelessWidget {
  const _ProjectionRow({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final hasValue = amount > 0;
    return Row(
      children: [
        Icon(icon,
            color: hasValue ? AppColors.textSecondary : AppColors.textDisabled,
            size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Text(
          '\$ ${_fmtCop(amount)} COP',
          style: TextStyle(
            color: hasValue ? AppColors.textPrimary : AppColors.textDisabled,
            fontSize: 13,
            fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  static String _fmtCop(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}
