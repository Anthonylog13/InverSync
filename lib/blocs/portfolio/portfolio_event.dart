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
