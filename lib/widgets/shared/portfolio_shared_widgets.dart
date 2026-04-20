import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// ===========================================================================
// AssetBadge — etiqueta de color genérica
// Nota: se llama AssetBadge (no Badge) para evitar conflicto con el widget
// Badge de material.dart disponible desde Flutter 3.10.
// ===========================================================================

class AssetBadge extends StatelessWidget {
  const AssetBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textDisabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: c.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ===========================================================================
// ChangeBadge — pastilla de variación porcentual
// ===========================================================================

class ChangeBadge extends StatelessWidget {
  const ChangeBadge({super.key, required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ===========================================================================
// DropdownField — selector estilizado para el bottom sheet
// ===========================================================================

class DropdownField extends StatelessWidget {
  const DropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                dropdownColor: AppColors.surfaceVariant,
                icon: const Icon(Icons.expand_more_rounded,
                    color: AppColors.textSecondary),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                isExpanded: true,
                hint: Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                onChanged: onChanged,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// SheetField — campo de texto estilizado para el bottom sheet
// ===========================================================================

class SheetField extends StatelessWidget {
  const SheetField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
