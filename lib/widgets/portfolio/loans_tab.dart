import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/portfolio/portfolio_bloc.dart';
import '../../blocs/portfolio/portfolio_event.dart';
import '../../blocs/portfolio/portfolio_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/asset_models.dart';
import '../shared/portfolio_shared_widgets.dart';

class LoansTab extends StatelessWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortfolioBloc, PortfolioState>(
      builder: (context, state) {
        if (state is PortfolioLoading || state is PortfolioInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (state is PortfolioError) {
          return Center(
            child: Text(
              'Error: ${state.message}',
              style: const TextStyle(color: AppColors.negative),
            ),
          );
        }
        if (state is PortfolioLoaded) {
          if (state.loans.isEmpty) {
            return const Center(
              child: Text(
                'Sin préstamos registrados',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 88),
            itemCount: state.loans.length,
            itemBuilder: (context, i) {
              final loan = state.loans[i];
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final bloc = context.read<PortfolioBloc>();
              return Dismissible(
                key: ValueKey(loan.id),
                direction: DismissDirection.endToStart,
                background: _DeleteBackground(),
                onDismissed: (_) => bloc.add(
                  DeleteAssetEvent(
                    uid: uid,
                    collection: 'loans',
                    assetId: loan.id,
                  ),
                ),
                child: LoanCard(loan: loan, uid: uid),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogo de registro de pago
// ---------------------------------------------------------------------------

/// Muestra el diálogo de amortización y despacha [RegisterLoanPaymentEvent]
/// al confirmar. Captura el bloc antes de la operación async.
Future<void> _showPaymentDialog({
  required BuildContext context,
  required PortfolioBloc bloc,
  required LoanAsset loan,
  required String uid,
}) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _PaymentDialog(loan: loan),
  );
  if (result == null) return;
  bloc.add(
    RegisterLoanPaymentEvent(
      uid: uid,
      loanId: loan.id,
      amount: result['amount'] as double,
      paymentType: result['type'] as String,
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.loan});

  final LoanAsset loan;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amountCtrl = TextEditingController();
  String _type = 'interest';

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accrued = widget.loan.currentAccruedInterest;
    final principal = widget.loan.outstandingPrincipal;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Registrar Pago',
        style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen del préstamo
          _SummaryRow('Capital pendiente', _fmtCop(principal)),
          if (accrued > 0) _SummaryRow('Interés acumulado estimado', _fmtCop(accrued),
              color: AppColors.warning),
          const SizedBox(height: 14),
          // Selector de tipo de pago (ChoiceChip compatible M2/M3)
          Row(
            children: [
              _TypeChip(
                label: 'Intereses',
                selected: _type == 'interest',
                onTap: () => setState(() => _type = 'interest'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: 'Capital',
                selected: _type == 'principal',
                onTap: () => setState(() => _type = 'principal'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Campo de monto
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Monto (COP)',
              labelStyle:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final raw = _amountCtrl.text.replaceAll(',', '.').trim();
            final amount = double.tryParse(raw);
            if (amount == null || amount <= 0) return;
            Navigator.of(context).pop({'amount': amount, 'type': _type});
          },
          child: const Text('Registrar',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  String _fmtCop(double v) => '\$ ${v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (m) => '${m[1]},',
      )} COP';
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Text(value,
              style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LoanCard
// ---------------------------------------------------------------------------

class LoanCard extends StatelessWidget {
  const LoanCard({super.key, required this.loan, required this.uid});

  final LoanAsset loan;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final principal = loan.outstandingPrincipal;
    final hasInterest = loan.monthlyRate > 0;
    final accrued = loan.currentAccruedInterest;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(loan.icon, color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.label,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    Text(loan.borrower,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          loan.cuotas != null
                              ? '${loan.cuotas} cuotas'
                              : 'Sin plazo fijo',
                          style: const TextStyle(
                              color: AppColors.textDisabled, fontSize: 11)),
                        const SizedBox(width: 6),
                        if (hasInterest)
                          AssetBadge(
                            label: '${loan.monthlyRate}% /mes',
                            color: AppColors.warning,
                          )
                        else
                          const AssetBadge(label: 'Sin interés'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$ ${_fmt(principal)} COP',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (hasInterest && accrued > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      '≈ \$ ${_fmt(accrued)} int.',
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 11)),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Botón de registro de pago
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.payments_outlined, size: 16),
              label: const Text('Registrar Pago',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              onPressed: () {
                final bloc = context.read<PortfolioBloc>();
                _showPaymentDialog(
                    context: context, bloc: bloc, loan: loan, uid: uid);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

/// Fondo rojo de borrar visible al deslizar de derecha a izquierda.
class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.negative,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_outline_rounded,
          color: Colors.white, size: 26),
    );
  }
}
