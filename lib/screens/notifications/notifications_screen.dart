import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo interno de la pantalla
// ---------------------------------------------------------------------------

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;
}

// ---------------------------------------------------------------------------
// Pantalla principal
// ---------------------------------------------------------------------------

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Calcula la próxima fecha de cobro para un día del mes dado.
  // Si el día ya pasó este mes → mes siguiente.
  // Hace clamp al último día válido del mes para evitar fechas inexistentes.
  static DateTime _nextPaymentDate(int day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int lastDayThis = DateTime(now.year, now.month + 1, 0).day;
    final clampedThis = day.clamp(1, lastDayThis);
    final thisMonth = DateTime(now.year, now.month, clampedThis);

    if (!thisMonth.isBefore(today)) return thisMonth;

    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final lastDayNext = DateTime(nextYear, nextMonth + 1, 0).day;
    final clampedNext = day.clamp(1, lastDayNext);
    return DateTime(nextYear, nextMonth, clampedNext);
  }

  // Convierte loans y physicals en _NotificationItems ordenados por fecha.
  List<_NotificationItem> _buildItems(PortfolioLoaded state) {
    final items = <_NotificationItem>[];

    for (final loan in state.loans) {
      final day = loan.paymentDay;
      if (day == null) continue;
      items.add(_NotificationItem(
        title: loan.label,
        subtitle: 'Cobro a ${loan.borrower}',
        date: _nextPaymentDate(day),
        icon: loan.icon,
        color: const Color(0xFF4A90D9), // azul préstamos
      ));
    }

    for (final physical in state.physicals) {
      if (!physical.hasRent) continue;
      final day = physical.rentPaymentDay;
      if (day == null) continue;
      items.add(_NotificationItem(
        title: physical.name,
        subtitle: 'Cobro de arriendo · ${physical.category}',
        date: _nextPaymentDate(day),
        icon: physical.icon,
        color: AppColors.positive, // verde arriendos
      ));
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  // Texto "Faltan X días" | "Mañana" | "Hoy"
  String _daysLabel(DateTime date) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Mañana';
    return 'Faltan $diff días';
  }

  Color _daysColor(DateTime date) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final diff = date.difference(today).inDays;
    if (diff <= 3) return AppColors.warning;
    if (diff <= 7) return const Color(0xFF4A90D9);
    return AppColors.positive;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Próximos Cobros'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          if (state is PortfolioLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.positive),
            );
          }

          if (state is! PortfolioLoaded) {
            return const Center(
              child: Text(
                'Cargando portafolio…',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final items = _buildItems(state);

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes cobros próximos\nprogramados',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _NotificationCard(
              item: items[index],
              daysLabel: _daysLabel(items[index].date),
              daysColor: _daysColor(items[index].date),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta individual
// ---------------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.daysLabel,
    required this.daysColor,
  });

  final _NotificationItem item;
  final String daysLabel;
  final Color daysColor;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM', 'es_ES').format(item.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Ícono circular
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withValues(alpha: 0.15),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),

          // Título y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Días restantes + fecha
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                daysLabel,
                style: TextStyle(
                  color: daysColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
