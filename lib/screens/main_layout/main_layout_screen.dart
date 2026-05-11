import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_event.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../calendar/calendar_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../login/login_screen.dart';
import '../movements/movements_screen.dart';
import '../notifications/notifications_screen.dart';
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
    CalendarScreen(),
    MovementsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Usar addPostFrameCallback garantiza que el widget esté completamente
    // insertado en el árbol antes de leer los providers del contexto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Solicitar permisos de notificaciones la primera vez
      context.read<NotificationService>().requestPermissions();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        context.read<PortfolioBloc>().add(LoadPortfolioData(uid: uid));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          BlocBuilder<PortfolioBloc, PortfolioState>(
            builder: (context, state) {
              final hasPending = state is PortfolioLoaded &&
                  (state.loans.any((l) => l.paymentDay != null) ||
                      state.physicals
                          .any((p) => p.hasRent && p.rentPaymentDay != null));

              return IconButton(
                tooltip: 'Próximos cobros',
                icon: Badge(
                  isLabelVisible: hasPending,
                  backgroundColor: AppColors.positive,
                  smallSize: 8,
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              );
            },
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

class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.surfaceVariant),
            accountName: Text(
              user?.displayName ?? 'Usuario InverSync',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            accountEmail: Text(
              user?.email ?? 'correo@inversync.com',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha(40),
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      _initials(user?.displayName),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
          ),
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
            onTap: () async {
              await AuthService.instance.signOut();
              if (!context.mounted) return;
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

  /// Extrae las iniciales del nombre (ej. "Anthony Arango" → "AA").
  /// Si no hay nombre, devuelve el ícono por defecto vía null.
  String _initials(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return '?';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
