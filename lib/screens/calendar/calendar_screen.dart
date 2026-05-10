import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';

// ── Modelo interno de evento de calendario ────────────────────────────────────

class _CalendarEvent {
  const _CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ---------------------------------------------------------------------------
  // Derivar eventos desde el estado del BLoC
  // ---------------------------------------------------------------------------

  /// Construye un mapa `{ DateTime → List<_CalendarEvent> }` a partir de
  /// los activos del usuario. Solo considera el mes de [focusedDay].
  Map<DateTime, List<_CalendarEvent>> _buildEventMap(PortfolioLoaded state) {
    final Map<DateTime, List<_CalendarEvent>> map = {};

    void addEvent(int day, _CalendarEvent event) {
      // Clamp: si el día supera el último del mes, usa el último día válido.
      final lastDay =
          DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
      final safeDay = day.clamp(1, lastDay);
      final date = DateTime(_focusedDay.year, _focusedDay.month, safeDay);
      map.putIfAbsent(date, () => []).add(event);
    }

    // Préstamos con día de pago
    for (final loan in state.loans) {
      final day = loan.paymentDay;
      if (day == null) continue;
      addEvent(
        day,
        _CalendarEvent(
          title: 'Pago cuota: ${loan.borrower}',
          subtitle:
              '\$${_fmt(loan.amount)} ${_monthlyLabel(loan.monthlyRate)}',
          icon: Icons.handshake_outlined,
          color: AppColors.warning,
        ),
      );
    }

    // Bienes con arriendo
    for (final physical in state.physicals) {
      if (!physical.hasRent) continue;
      final day = physical.rentPaymentDay;
      if (day == null) continue;
      addEvent(
        day,
        _CalendarEvent(
          title: 'Cobro arriendo: ${physical.name}',
          subtitle: physical.category,
          icon: Icons.home_work_outlined,
          color: AppColors.positive,
        ),
      );
    }

    return map;
  }

  List<_CalendarEvent> _eventsForDay(
    DateTime day,
    Map<DateTime, List<_CalendarEvent>> eventMap,
  ) =>
      eventMap[DateTime(day.year, day.month, day.day)] ?? [];

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioInitial || state is PortfolioLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is PortfolioError) {
          return Center(
            child: Text('Error: ${state.message}',
                style: const TextStyle(color: AppColors.negative)),
          );
        }

        if (state is! PortfolioLoaded) return const SizedBox.shrink();

        final eventMap = _buildEventMap(state);
        final selectedEvents = _eventsForDay(_selectedDay, eventMap);

        return Column(
          children: [
            // ── Calendario ─────────────────────────────────────────────────
            _buildCalendar(eventMap),
            const Divider(height: 1, color: AppColors.border),
            // ── Lista de eventos del día seleccionado ──────────────────────
            Expanded(child: _buildEventList(selectedEvents)),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets auxiliares
  // ---------------------------------------------------------------------------

  Widget _buildCalendar(Map<DateTime, List<_CalendarEvent>> eventMap) {
    return TableCalendar<_CalendarEvent>(
      locale: 'es_ES',
      firstDay: DateTime(2020),
      lastDay: DateTime(2100),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      eventLoader: (day) => _eventsForDay(day, eventMap),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
      startingDayOfWeek: StartingDayOfWeek.monday,
      onDaySelected: (selected, focused) => setState(() {
        _selectedDay = selected;
        _focusedDay = focused;
      }),
      onPageChanged: (focused) => setState(() {
        _focusedDay = focused;
        _selectedDay = focused; // resetea selección al cambiar mes
      }),
      // ── Estilos dark mode ────────────────────────────────────────────────
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        leftChevronIcon:
            Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
        rightChevronIcon:
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        headerPadding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: AppColors.surface),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle:
            TextStyle(color: AppColors.textSecondary, fontSize: 12),
        weekendStyle:
            TextStyle(color: AppColors.textDisabled, fontSize: 12),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle:
            const TextStyle(color: AppColors.textPrimary),
        weekendTextStyle:
            const TextStyle(color: AppColors.textSecondary),
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withAlpha(50),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: AppColors.background,
          fontWeight: FontWeight.w700,
        ),
        markerDecoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        cellMargin: const EdgeInsets.all(4),
      ),
    );
  }

  Widget _buildEventList(List<_CalendarEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: AppColors.textDisabled.withAlpha(120),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin eventos este día',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: events.length,
      itemBuilder: (_, i) => _EventCard(event: events[i]),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers de formato
  // ---------------------------------------------------------------------------

  static String _fmt(double v) {
    final parts = v.toStringAsFixed(0).split('');
    final buf = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buf.write(',');
      buf.write(parts[i]);
    }
    return buf.toString();
  }

  static String _monthlyLabel(double rate) =>
      rate > 0 ? '${rate.toStringAsFixed(1)}% mensual' : '';
}

// ── Tarjeta de evento ─────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final _CalendarEvent event;

  @override
  Widget build(BuildContext context) {
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
          // Ícono
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: event.color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(event.icon, color: event.color, size: 22),
          ),
          const SizedBox(width: 14),
          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.subtitle,
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Badge de tipo
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: event.color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: event.color.withAlpha(60)),
            ),
            child: Text(
              'Hoy',
              style: TextStyle(
                color: event.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
