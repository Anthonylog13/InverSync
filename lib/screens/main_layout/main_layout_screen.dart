import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../login/login_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../settings/settings_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PortfolioScreen(),
    _PlaceholderScreen(label: 'Calendario'),
    _PlaceholderScreen(label: 'Movimientos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _AppDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart_rounded),
            label: 'Portafolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt_rounded),
            label: 'Movimientos',
          ),
        ],
      ),
    );
  }

  String get _appBarTitle {
    const titles = ['Inicio', 'Portafolio', 'Calendario', 'Movimientos'];
    return titles[_currentIndex];
  }
}

// ---------------------------------------------------------------------------
// Drawer
// ---------------------------------------------------------------------------
class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surfaceVariant),
            accountName: const Text(
              'Usuario InverSync',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            accountEmail: const Text(
              'usuario@inversync.com',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha(40),
              child: const Icon(Icons.person, color: AppColors.primary, size: 32),
            ),
          ),
          // Opciones
          _DrawerItem(
            icon: Icons.person_outline_rounded,
            label: 'Mi Perfil',
            onTap: () => Navigator.pop(context),
          ),
          _DrawerItem(
            icon: Icons.settings_outlined,
            label: 'Configuración',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Spacer(),
          const Divider(height: 1),
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            color: AppColors.negative,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      onTap: onTap,
      horizontalTitleGap: 4,
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder para pestañas no implementadas aún
// ---------------------------------------------------------------------------
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction_rounded, color: AppColors.textDisabled, size: 48),
          const SizedBox(height: 12),
          Text(
            '$label — Próximamente',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

