import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/movement_model.dart';

/// Gráfico de línea que muestra la evolución acumulada del capital invertido
/// basándose en el historial de movimientos del usuario.
///
/// El eje X representa el tiempo (índice ordinal de los movimientos ordenados
/// por fecha) y el eje Y el capital acumulado en USD.
class PortfolioLineChart extends StatelessWidget {
  const PortfolioLineChart({super.key, required this.movements});

  final List<Movement> movements;

  static const double _usdToCop = 4200.0;

  /// Construye la lista de [FlSpot] a partir de los movimientos ordenados.
  /// Solo incluye movimientos de tipo `investment` e `income` (entradas de
  /// capital). Normaliza a USD.
  List<FlSpot> _buildSpots() {
    // Filtrar solo entradas de capital y ordenar por fecha
    final entries = movements
        .where((m) =>
            m.type == MovementType.investment || m.type == MovementType.income)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (entries.isEmpty) return [const FlSpot(0, 0)];

    final spots = <FlSpot>[];
    double cumulative = 0.0;

    for (int i = 0; i < entries.length; i++) {
      final m = entries[i];
      final amountUsd = m.currency == 'COP' ? m.amount / _usdToCop : m.amount;
      cumulative += amountUsd;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    final maxY = spots.map((s) => s.y).fold(0.0, max);
    // Añadir 15% de margen superior para que la línea no quede pegada al borde
    final chartMaxY = maxY > 0 ? maxY * 1.15 : 100.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Capital acumulado',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble().clamp(1, double.infinity),
                minY: 0,
                maxY: chartMaxY,
                // ── Sin cuadrículas para look "Apple Stocks" ───────────────
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                // ── Tooltip al tocar ───────────────────────────────────────
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceVariant,
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map((s) => LineTooltipItem(
                              '\$ ${s.y.toStringAsFixed(0)} USD',
                              const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                // ── Línea principal ────────────────────────────────────────
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    // Sin puntos en los nodos
                    dotData: const FlDotData(show: false),
                    // Gradiente verde debajo de la línea
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withAlpha(60),
                          AppColors.primary.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}
