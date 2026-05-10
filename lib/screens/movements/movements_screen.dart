import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movement_model.dart';

class MovementsScreen extends StatelessWidget {
  const MovementsScreen({super.key});

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
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: AppColors.negative),
            ),
          );
        }

        // ── Loaded ────────────────────────────────────────────────────────
        if (state is PortfolioLoaded) {
          if (state.movements.isEmpty) {
            return const _EmptyMovements();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: state.movements.length,
            itemBuilder: (context, i) =>
                MovementCard(movement: state.movements[i]),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyMovements extends StatelessWidget {
  const _EmptyMovements();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textDisabled.withAlpha(120),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no hay movimientos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra activos para ver tu historial aquí.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textDisabled,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de movimiento ────────────────────────────────────────────────────

class MovementCard extends StatelessWidget {
  const MovementCard({super.key, required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    final cfg = _config(movement.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // ── Ícono de tipo ─────────────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cfg.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cfg.icon, color: cfg.iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // ── Título + fecha ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(movement.date),
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ── Monto ────────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${cfg.sign}${_formatAmount(movement.amount)} ${movement.currency}',
                style: TextStyle(
                  color: cfg.amountColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              _TypeBadge(label: cfg.label, color: cfg.iconColor),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime d) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatAmount(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }

  _MovementConfig _config(MovementType type) {
    switch (type) {
      case MovementType.income:
        return _MovementConfig(
          icon: Icons.arrow_downward_rounded,
          iconColor: AppColors.positive,
          bgColor: AppColors.positive.withAlpha(25),
          amountColor: AppColors.positive,
          sign: '+',
          label: 'Ingreso',
        );
      case MovementType.expense:
        return _MovementConfig(
          icon: Icons.arrow_upward_rounded,
          iconColor: AppColors.negative,
          bgColor: AppColors.negative.withAlpha(25),
          amountColor: AppColors.negative,
          sign: '-',
          label: 'Gasto',
        );
      case MovementType.investment:
        return _MovementConfig(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF8ECFFF),
          bgColor: const Color(0xFF8ECFFF).withAlpha(25),
          amountColor: AppColors.textPrimary,
          sign: '',
          label: 'Inversión',
        );
    }
  }
}

// ── Config por tipo ───────────────────────────────────────────────────────────

class _MovementConfig {
  const _MovementConfig({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.amountColor,
    required this.sign,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color amountColor;
  final String sign;
  final String label;
}

// ── Badge de tipo ─────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
