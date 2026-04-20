import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../shared/portfolio_shared_widgets.dart';

class AddAssetSheet extends StatefulWidget {
  const AddAssetSheet({super.key});

  @override
  State<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<AddAssetSheet> {
  String _assetType = 'Accion/Cripto';
  final _field1Controller = TextEditingController();
  final _field2Controller = TextEditingController();
  String _currency = 'COP';

  static const _assetTypes = ['Accion/Cripto', 'Prestamo P2P', 'Bien Fisico'];

  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    super.dispose();
  }

  String get _field1Label {
    switch (_assetType) {
      case 'Prestamo P2P':
        return 'Nombre del deudor';
      case 'Bien Fisico':
        return 'Nombre del bien';
      default:
        return 'Ticker / Simbolo';
    }
  }

  String get _field1Hint {
    switch (_assetType) {
      case 'Prestamo P2P':
        return 'Ej. Tio Carlos';
      case 'Bien Fisico':
        return 'Ej. Moto TVS 200';
      default:
        return 'Ej. ECO.CB, BTC';
    }
  }

  String get _field2Label {
    switch (_assetType) {
      case 'Prestamo P2P':
        return 'Monto prestado';
      case 'Bien Fisico':
        return 'Valor estimado';
      default:
        return 'Cantidad de titulos';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Registrar Activo',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Elige el tipo y completa los campos',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          DropdownField(
            label: 'Tipo de Activo',
            icon: Icons.category_outlined,
            value: _assetType,
            items: _assetTypes,
            onChanged: (v) => setState(() => _assetType = v ?? _assetType),
          ),
          const SizedBox(height: 14),
          SheetField(
            controller: _field1Controller,
            label: _field1Label,
            hint: _field1Hint,
            icon: Icons.label_outline_rounded,
          ),
          const SizedBox(height: 14),
          SheetField(
            controller: _field2Controller,
            label: _field2Label,
            hint: 'Ej. 150',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          DropdownField(
            label: 'Moneda',
            icon: Icons.attach_money_rounded,
            value: _currency,
            items: const ['COP', 'USD'],
            onChanged: (v) => setState(() => _currency = v ?? 'COP'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Guardar Activo'),
            ),
          ),
        ],
      ),
    );
  }
}
