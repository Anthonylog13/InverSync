import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _priceAlertsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionHeader(label: 'Seguridad'),
          SwitchListTile(
            value: _biometricEnabled,
            onChanged: (v) => setState(() => _biometricEnabled = v),
            secondary: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _biometricEnabled
                    ? AppColors.primary.withAlpha(30)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.fingerprint,
                color: _biometricEnabled
                    ? AppColors.primary
                    : AppColors.textDisabled,
                size: 22,
              ),
            ),
            title: const Text(
              'Activar acceso biométrico',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _biometricEnabled ? 'Huella / Face ID activado' : 'Desactivado',
              style: TextStyle(
                color: _biometricEnabled
                    ? AppColors.positive
                    : AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          const SizedBox(height: 8),
          _SectionHeader(label: 'Notificaciones'),
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
            secondary: _SettingsIcon(
              icon: Icons.notifications_outlined,
              active: _notificationsEnabled,
            ),
            title: const Text(
              'Notificaciones push',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            value: _priceAlertsEnabled,
            onChanged: (v) => setState(() => _priceAlertsEnabled = v),
            secondary: _SettingsIcon(
              icon: Icons.trending_up_rounded,
              active: _priceAlertsEnabled,
            ),
            title: const Text(
              'Alertas de precio',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            ),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
          const SizedBox(height: 8),
          _SectionHeader(label: 'Sobre la app'),
          _InfoTile(label: 'Versión', value: '1.0.0-mvp'),
          _InfoTile(label: 'Entorno', value: 'Mock (Mockoon)'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers de UI
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textDisabled,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.active});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active
            ? AppColors.primary.withAlpha(30)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: active ? AppColors.primary : AppColors.textDisabled,
        size: 22,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
