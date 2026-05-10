import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';

// ─── Modelo interno de sección del gráfico ────────────────────────────────────

class _Section {
  const _Section(this.label, this.percent, this.color);
  final String label;
  final double percent;
  final Color color;
}

// ─── Constantes de color por categoría ───────────────────────────────────────

const _colorMercados = AppColors.primary;            // Verde acento
const _colorPrestamos = Color(0xFFFFC107);            // Amarillo / Warning
const _colorBienes = Color(0xFF8ECFFF);              // Azul claro

class AssetDistributionChart extends StatelessWidget {
  const AssetDistributionChart({
    super.key,
    required this.markets,
    required this.loans,
    required this.physicals,
    required this.totalBalance,
    required this.touchedIndex,
    required this.onTouch,
  });

  final List<MarketAsset> markets;
  final List<LoanAsset> loans;
  final List<PhysicalAsset> physicals;

  /// Balance total en USD proveniente del estado [PortfolioLoaded].
  final double totalBalance;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  static const double _usdToCop = 4200;

  // ── Cálculo de totales en USD por categoría ────────────────────────────────

  double get _marketsTotal => markets.fold(0.0, (sum, m) {
        final v = m.currency == 'COP'
            ? (m.price * m.quantity) / _usdToCop
            : m.price * m.quantity;
        return sum + v;
      });

  double get _loansTotal =>
      loans.fold(0.0, (sum, l) => sum + l.amount / _usdToCop);

  double get _physicalsTotal =>
      physicals.fold(0.0, (sum, p) => sum + p.estimatedValue / _usdToCop);

  // ── Construye la lista de secciones con porcentajes dinámicos ─────────────

  List<_Section> _buildSections() {
    if (totalBalance <= 0) {
      // Sin datos: una sola sección gris como placeholder
      return [const _Section('Sin activos', 100, AppColors.surfaceVariant)];
    }

    final raw = [
      _Section('Mercados', _marketsTotal / totalBalance * 100, _colorMercados),
      _Section('Préstamos P2P', _loansTotal / totalBalance * 100, _colorPrestamos),
      _Section('Bienes Físicos', _physicalsTotal / totalBalance * 100, _colorBienes),
    ];

    // Filtra categorías vacías para no dibujar sectores 0%
    return raw.where((s) => s.percent > 0.5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      onTouch(-1);
                      return;
                    }
                    onTouch(response.touchedSection!.touchedSectionIndex);
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 52,
                sections: List.generate(sections.length, (i) {
                  final isTouched = i == touchedIndex;
                  final s = sections[i];
                  return PieChartSectionData(
                    color: s.color,
                    value: s.percent,
                    title: '${s.percent.toStringAsFixed(1)}%',
                    radius: isTouched ? 72 : 60,
                    titleStyle: TextStyle(
                      fontSize: isTouched ? 14 : 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Leyenda dinámica ──────────────────────────────────────────────
          ...sections.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${s.percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
