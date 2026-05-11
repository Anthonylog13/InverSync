import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelo interno
// ---------------------------------------------------------------------------

class _AlertItem {
  const _AlertItem({
    required this.title,
    required this.subtitle,
    required this.daysToEvent,
    required this.date,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final int daysToEvent;
  final DateTime date;
  final IconData icon;
  final Color color;
}

// ---------------------------------------------------------------------------
// Pantalla – Centro de Alertas Críticas
// ---------------------------------------------------------------------------

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const int _urgencyThresholdDays = 3;

  // Próxima fecha de cobro para un día del mes (clamp al último día válido).
  static DateTime _nextPaymentDate(int day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDayThis = DateTime(now.year, now.month + 1, 0).day;
    final thisMonth = DateTime(now.year, now.month, day.clamp(1, lastDayThis));
    if (!thisMonth.isBefore(today)) return thisMonth;
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final lastDayNext = DateTime(nextYear, nextMonth + 1, 0).day;
    return DateTime(nextYear, nextMonth, day.clamp(1, lastDayNext));
  }

  static int _diffDays(DateTime date) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return date.difference(today).inDays;
  }

  // API pública usada por MainLayoutScreen para el Badge inteligente.
  static bool hasUrgentAlerts(PortfolioLoaded state) {
    for (final loan in state.loans) {
      final day = loan.paymentDay;
      if (day != null &&
          _diffDays(_nextPaymentDate(day)) <= _urgencyThresholdDays) {
        return true;
      }
    }
    for (final physical in state.physicals) {
      if (!physical.hasRent) continue;
      final day = physical.rentPaymentDay;
      if (day != null &&
          _diffDays(_nextPaymentDate(day)) <= _urgencyThresholdDays) {
        return true;
      }
    }
    return false;
  }

  // Genera solo alertas urgentes (≤ 3 días), ordenadas del más próximo al lejano.
  List<_AlertItem> _buildItems(PortfolioLoaded state) {
    final items = <_AlertItem>[];
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    for (final loan in state.loans) {
      final day = loan.paymentDay;
      if (day == null) continue;
      final date = _nextPaymentDate(day);
      final diff = date.difference(today).inDays;
      if (diff > _urgencyThresholdDays) continue;
      items.add(_AlertItem(
        title: _loanTitle(loan.borrower, diff),
        subtitle: 'Préstamo · ${loan.label}',
        daysToEvent: diff,
        date: date,
        icon: loan.icon,
        color: _urgencyColor(diff),
      ));
    }

    for (final physical in state.physicals) {
      if (!physical.hasRent) continue;
      final day = physical.rentPaymentDay;
      if (day == null) continue;
      final date = _nextPaymentDate(day);
      final diff = date.difference(today).inDays;
      if (diff > _urgencyThresholdDays) continue;
      items.add(_AlertItem(
        title: _rentTitle(physical.name, diff),
        subtitle: 'Arriendo · ${physical.category}',
        daysToEvent: diff,
        date: date,
        icon: physical.icon,
        color: _urgencyColor(diff),
      ));
    }

    items.sort((a, b) => a.daysToEvent.compareTo(b.daysToEvent));
    return items;
  }

  static String _loanTitle(String borrower, int diff) {
    if (diff == 0) return '¡Hoy es el cobro de $borrower!';
    if (diff == 1) return '¡Mañana es el cobro de $borrower!';
    return '¡Recordatorio! En $diff días debes cobrar la cuota de $borrower';
  }

  static String _rentTitle(String name, int diff) {
    if (diff == 0) return '¡Hoy es el cobro del arriendo de $name!';
    if (diff == 1) return '¡Mañana es el cobro del arriendo de $name!';
    return '¡Alerta! Se acerca el cobro del arriendo de $name';
  }

  static Color _urgencyColor(int diff) {
    if (diff == 0) return AppColors.negative;        // rojo – hoy
    if (diff == 1) return AppColors.warning;          // naranja – mañana
    return const Color(0xFF4A90D9);                  // azul – 2-3 días
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Centro de Alertas'),
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
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: AppColors.positive,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Todo al día.',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No tienes alertas pendientes\npara los próximos días.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _AlertCard(item: items[index]),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de alerta estilo "buzón" con borde lateral de color
// ---------------------------------------------------------------------------

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.item});

  final _AlertItem item;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM', 'es_ES').format(item.date);
    final diff = item.daysToEvent;
    final chipLabel =
        diff == 0 ? 'HOY' : diff == 1 ? 'MAÑANA' : 'EN $diff DÍAS';

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: item.color, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono circular
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withValues(alpha: 0.15),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),

            // Cuerpo del mensaje
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chip de urgencia
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chipLabel,
                      style: TextStyle(
                        color: item.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Título – mensaje de alerta
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtítulo – contexto
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Fecha compacta
            Text(
              dateLabel,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
