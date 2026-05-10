import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/asset_models.dart';
import '../../models/movement_model.dart';
import '../../services/firestore_service.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

/// BLoC central de portafolio.
///
/// SOLID — Inversión de Dependencias:
/// [FirestoreService] se inyecta por constructor; el BLoC nunca instancia
/// colaboradores directamente.
class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  PortfolioBloc({required FirestoreService firestoreService})
      : _firestore = firestoreService,
        super(const PortfolioInitial()) {
    on<LoadPortfolioData>(_onLoad);
    on<AddAssetEvent>(_onAddAsset);
    on<ToggleCurrencyEvent>(_onToggleCurrency);
  }

  final FirestoreService _firestore;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  /// Carga todas las listas en paralelo desde Firestore y emite [PortfolioLoaded].
  Future<void> _onLoad(
    LoadPortfolioData event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(const PortfolioLoading());
    try {
      List<Map<String, dynamic>> marketsJson = [];
      List<Map<String, dynamic>> loansJson = [];
      List<Map<String, dynamic>> physicalsJson = [];
      List<Map<String, dynamic>> movementsJson = [];

      await Future.wait([
        _firestore.getMarkets(event.uid).then((v) => marketsJson = v),
        _firestore.getLoans(event.uid).then((v) => loansJson = v),
        _firestore.getPhysicals(event.uid).then((v) => physicalsJson = v),
        _firestore.getMovements(event.uid).then((v) => movementsJson = v),
      ]);

      emit(PortfolioLoaded(
        markets: marketsJson.map(MarketAsset.fromJson).toList(),
        loans: loansJson.map(LoanAsset.fromJson).toList(),
        physicals: physicalsJson.map(PhysicalAsset.fromJson).toList(),
        movements: movementsJson.map(Movement.fromJson).toList(),
      ));
    } catch (e) {
      emit(PortfolioError(message: e.toString()));
    }
  }

  /// Optimistic Update: persiste en Firestore y actualiza el estado local
  /// sin esperar un nuevo GET completo. También registra el movimiento.
  Future<void> _onAddAsset(
    AddAssetEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    final current = state;
    if (current is! PortfolioLoaded) return;

    try {
      Movement? newMovement;

      switch (event.type) {
        case 'Prestamo P2P':
          await _firestore.saveAsset(event.uid, 'loans', event.assetData);
          final newLoan = LoanAsset.fromJson(event.assetData);
          newMovement = Movement(
            id: 'mov-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Préstamo ${newLoan.borrower}',
            amount: newLoan.amount,
            date: DateTime.now(),
            type: MovementType.income,
            currency: 'COP',
          );
          await _firestore.saveMovement(event.uid, newMovement.toJson());
          emit(current.copyWith(
            loans: [...current.loans, newLoan],
            movements: [newMovement, ...current.movements],
          ));

        case 'Bien Fisico':
          await _firestore.saveAsset(event.uid, 'physicals', event.assetData);
          final newPhysical = PhysicalAsset.fromJson(event.assetData);
          newMovement = Movement(
            id: 'mov-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Compra ${newPhysical.name}',
            amount: newPhysical.acquisitionValue,
            date: DateTime.now(),
            type: MovementType.investment,
            currency: 'COP',
          );
          await _firestore.saveMovement(event.uid, newMovement.toJson());
          emit(current.copyWith(
            physicals: [...current.physicals, newPhysical],
            movements: [newMovement, ...current.movements],
          ));

        default: // 'Accion/Cripto'
          await _firestore.saveAsset(event.uid, 'markets', event.assetData);
          final newMarket = MarketAsset.fromJson(event.assetData);
          newMovement = Movement(
            id: 'mov-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Compra ${newMarket.name}',
            amount: newMarket.price * newMarket.quantity,
            date: DateTime.now(),
            type: MovementType.investment,
            currency: newMarket.currency,
          );
          await _firestore.saveMovement(event.uid, newMovement.toJson());
          emit(current.copyWith(
            markets: [...current.markets, newMarket],
            movements: [newMovement, ...current.movements],
          ));
      }
    } catch (e) {
      addError(e);
    }
  }

  /// Invierte el flag de moneda y recalcula el balance mediante [copyWith].
  void _onToggleCurrency(
    ToggleCurrencyEvent event,
    Emitter<PortfolioState> emit,
  ) {
    final current = state;
    if (current is! PortfolioLoaded) return;

    emit(current.copyWith(isCopCurrency: !current.isCopCurrency));
  }
}
