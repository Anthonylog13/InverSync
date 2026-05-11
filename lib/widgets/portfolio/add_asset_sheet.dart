import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../services/market_data_service.dart';
import '../../blocs/portfolio/portfolio_event.dart';
import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
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
  final _rateController = TextEditingController();
  final _monthsController = TextEditingController();
  final _paymentDayController = TextEditingController();
  final _rentDayController = TextEditingController();
  String _currency = 'COP';
  bool _hasRent = false;
  bool _isSaving = false;
  final _purchasePriceController = TextEditingController();
  String? _selectedTicker;
  String? _selectedTickerName;
  TextEditingController? _autocompleteController;

  static const _assetTypes = ['Accion/Cripto', 'Prestamo P2P', 'Bien Fisico'];

  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    _rateController.dispose();
    _monthsController.dispose();
    _paymentDayController.dispose();
    _rentDayController.dispose();
    _purchasePriceController.dispose();
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

  Map<String, dynamic> _buildAssetData() {
    final f1 = _field1Controller.text.trim();
    final f2 = double.tryParse(_field2Controller.text.trim()) ?? 0.0;
    final monthlyRate = double.tryParse(_rateController.text.trim()) ?? 0.0;
    final monthsElapsed = int.tryParse(_monthsController.text.trim()) ?? 0;
    final paymentDay = int.tryParse(_paymentDayController.text.trim());
    final rentDay = int.tryParse(_rentDayController.text.trim());
    switch (_assetType) {
      case 'Prestamo P2P':
        return LoanAsset(
          label: 'Prestamo $f1',
          borrower: f1,
          amount: f2,
          monthlyRate: monthlyRate,
          monthsElapsed: monthsElapsed,
          iconKey: 'person_outline_rounded',
          paymentDay: paymentDay,
        ).toJson();
      case 'Bien Fisico':
        return PhysicalAsset(
          name: f1,
          category: 'General',
          estimatedValue: f2,
          acquisitionValue: f2,
          iconKey: 'help_outline_rounded',
          hasRent: _hasRent,
          rentPaymentDay: _hasRent ? rentDay : null,
        ).toJson();
      default:
        final tickerRaw = (_selectedTicker ??
                _autocompleteController?.text.trim() ??
                f1)
            .toUpperCase();
        final tickerName = _selectedTickerName ?? tickerRaw;
        final purchasePrice =
            double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
        return MarketAsset(
          name: tickerName,
          ticker: tickerRaw,
          quantity: f2,
          price: purchasePrice,
          changePercent: 0.0,
          iconKey: 'help_outline_rounded',
          currency: _currency,
        ).toJson();
    }
  }

  Future<void> _save() async {
    final isMarket = _assetType == 'Accion/Cripto';
    final hasName = isMarket
        ? (_selectedTicker ?? _autocompleteController?.text.trim() ?? '')
            .isNotEmpty
        : _field1Controller.text.trim().isNotEmpty;
    if (!hasName) return;

    setState(() => _isSaving = true);

    try {
      // Despacha el evento; el BLoC maneja la persistencia y el Optimistic Update
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      context.read<PortfolioBloc>().add(
            AddAssetEvent(
              uid: uid,
              type: _assetType,
              assetData: _buildAssetData(),
            ),
          );

      // Escuchamos un único cambio de estado para detectar error del BLoC
      // vía BlocListener en el árbol padre; aquí cerramos el sheet directamente.
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.negative,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Autocomplete de tickers ──────────────────────────────────────────────

  Widget _buildTickerAutocomplete(MarketDataService marketService) {
    return Autocomplete<Map<String, String>>(
      displayStringForOption: (option) => option['symbol'] ?? '',
      optionsBuilder: (textValue) async {
        final q = textValue.text.trim();
        if (q.length < 3) return const [];
        return marketService.searchTicker(q);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _autocompleteController = controller;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Busca por nombre o símbolo (ej. Apple)',
                    hintStyle:
                        TextStyle(color: AppColors.textDisabled, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    labelText: 'Ticker / Símbolo',
                    labelStyle:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onSubmitted: (_) => onFieldSubmitted(),
                ),
              ),
            ],
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            elevation: 6,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, i) {
                  final opt = options.elementAt(i);
                  return InkWell(
                    onTap: () => onSelected(opt),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            opt['symbol'] ?? '',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              opt['shortname'] ?? '',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            opt['exchange'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (option) {
        setState(() {
          _selectedTicker = option['symbol'];
          _selectedTickerName = option['shortname'];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final marketService = context.read<MarketDataService>();
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
            onChanged: (v) => setState(() {
              _assetType = v ?? _assetType;
              _selectedTicker = null;
              _selectedTickerName = null;
              _autocompleteController = null;
            }),
          ),
          const SizedBox(height: 14),
          if (_assetType == 'Accion/Cripto')
            _buildTickerAutocomplete(marketService)
          else
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
          if (_assetType == 'Accion/Cripto') ...[  
            const SizedBox(height: 14),
            SheetField(
              controller: _purchasePriceController,
              label: 'Precio de compra unitario',
              hint: 'Ej. 12500.50',
              icon: Icons.price_change_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          if (_assetType == 'Prestamo P2P') ...[  
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SheetField(
                    controller: _rateController,
                    label: 'Tasa mensual (%)',
                    hint: 'Ej. 2.0',
                    icon: Icons.percent_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SheetField(
                    controller: _monthsController,
                    label: 'Meses transcurridos',
                    hint: 'Ej. 3',
                    icon: Icons.calendar_month_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SheetField(
              controller: _paymentDayController,
              label: 'Día de pago (1-31)',
              hint: 'Ej. 15',
              icon: Icons.event_rounded,
              keyboardType: TextInputType.number,
            ),
          ],
          if (_assetType == 'Bien Fisico') ...[  
            const SizedBox(height: 14),
            _RentToggle(
              value: _hasRent,
              onChanged: (v) => setState(() {
                _hasRent = v;
                if (!v) _rentDayController.clear();
              }),
            ),
            if (_hasRent) ...[  
              const SizedBox(height: 14),
              SheetField(
                controller: _rentDayController,
                label: 'Día de cobro arriendo (1-31)',
                hint: 'Ej. 5',
                icon: Icons.event_available_rounded,
                keyboardType: TextInputType.number,
              ),
            ],
          ],
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
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.background,
                      ),
                    )
                  : const Text('Guardar Activo'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle de arriendo ────────────────────────────────────────────────────────

class _RentToggle extends StatelessWidget {
  const _RentToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_work_outlined,
              color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '¿Genera arriendo?',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
