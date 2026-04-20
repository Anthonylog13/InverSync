import 'package:flutter/material.dart';

import '../../widgets/dashboard/asset_distribution_chart.dart';
import '../../widgets/dashboard/balance_card.dart';
import '../../widgets/dashboard/sync_action_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _touchedIndex = -1;
  bool _inCOP = false;

  static const double _usdToCop = 4200;
  static const double _balanceUsd = 15450.00;

  static const _chartSections = [
    ChartSectionData('Criptomonedas', 40, Color(0xFF00D05A)),
    ChartSectionData('Acciones BVC', 35, Color(0xFF8ECFFF)),
    ChartSectionData('Mercado Asiático', 25, Color(0xFFB0B0B0)),
  ];

  String get _displayBalance {
    if (_inCOP) {
      return '\$ ${_formatNumber(_balanceUsd * _usdToCop)} COP';
    }
    return '\$ ${_formatNumber(_balanceUsd)} USD';
  }

  String _formatNumber(double n) {
    final parts = n.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          BalanceCard(
            balance: _displayBalance,
            inCOP: _inCOP,
            onToggleCurrency: () => setState(() => _inCOP = !_inCOP),
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
            sections: _chartSections,
            touchedIndex: _touchedIndex,
            onTouch: (i) => setState(() => _touchedIndex = i),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

