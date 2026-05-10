import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_event.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/portfolio/add_asset_sheet.dart';
import '../../widgets/portfolio/loans_tab.dart';
import '../../widgets/portfolio/markets_tab.dart';
import '../../widgets/portfolio/physical_tab.dart';
import '../../widgets/portfolio/portfolio_summary_card.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // El BLoC ya lanzó LoadPortfolioData en main.dart al ser creado.
    // Sólo relanzamos si el estado actual es el inicial (primera navegación
    // a esta pantalla antes de que el BLoC responda).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<PortfolioBloc>();
      if (bloc.state.runtimeType == PortfolioInitial) {
        bloc.add(const LoadPortfolioData());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddAssetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddAssetSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const PortfolioSummary(),
            Container(
              color: AppColors.background,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textDisabled,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(text: 'Mercados'),
                  Tab(text: 'Prestamos'),
                  Tab(text: 'Bienes'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  MarketsTab(),
                  LoansTab(),
                  PhysicalTab(),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _openAddAssetSheet,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
            elevation: 6,
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}
