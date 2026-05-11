import 'package:equatable/equatable.dart';

/// Jerarquía sellada de eventos del PortfolioBloc.
///
/// Todos los eventos extienden [PortfolioEvent], que garantiza igualdad
/// estructural vía [Equatable] (útil para tests y deduplicación).
sealed class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

/// Solicita la carga inicial de todos los activos desde Firestore.
///
/// [uid] : UID del usuario autenticado cuya subcolección se consultará.
final class LoadPortfolioData extends PortfolioEvent {
  const LoadPortfolioData({required this.uid});

  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Solicita agregar un nuevo activo.
///
/// [uid]       : UID del usuario autenticado.
/// [type]      : 'Accion/Cripto' | 'Prestamo P2P' | 'Bien Fisico'
/// [assetData] : payload JSON que se persistirá en Firestore.
final class AddAssetEvent extends PortfolioEvent {
  const AddAssetEvent({
    required this.uid,
    required this.type,
    required this.assetData,
  });

  final String uid;
  final String type;
  final Map<String, dynamic> assetData;

  @override
  List<Object?> get props => [uid, type, assetData];
}

/// Alterna la moneda base del dashboard entre COP y USD.
final class ToggleCurrencyEvent extends PortfolioEvent {
  const ToggleCurrencyEvent();
}

/// Solicita eliminar un activo del portafolio.
///
/// [uid]        : UID del usuario autenticado.
/// [collection] : Nombre de la subcolección en Firestore ('markets', 'loans', 'physicals').
/// [assetId]    : Identificador del documento a eliminar.
final class DeleteAssetEvent extends PortfolioEvent {
  const DeleteAssetEvent({
    required this.uid,
    required this.collection,
    required this.assetId,
  });

  final String uid;
  final String collection;
  final String assetId;

  @override
  List<Object?> get props => [uid, collection, assetId];
}

/// Registra un pago sobre un préstamo (intereses o abono a capital).
///
/// [uid]         : UID del usuario autenticado.
/// [loanId]      : ID del préstamo en Firestore.
/// [amount]      : Monto pagado (en COP).
/// [paymentType] : 'interest' para cobro de intereses, 'principal' para abono a capital.
final class RegisterLoanPaymentEvent extends PortfolioEvent {
  const RegisterLoanPaymentEvent({
    required this.uid,
    required this.loanId,
    required this.amount,
    required this.paymentType,
  });

  final String uid;
  final String loanId;
  final double amount;

  /// 'interest' | 'principal'
  final String paymentType;

  @override
  List<Object?> get props => [uid, loanId, amount, paymentType];
}
