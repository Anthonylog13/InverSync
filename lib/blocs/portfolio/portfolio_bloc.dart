import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/asset_models.dart';
import '../../models/movement_model.dart';
import '../../services/firestore_service.dart';
import '../../services/market_data_service.dart';
import '../../services/notification_service.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

/// BLoC central de portafolio.
///
/// SOLID — Inversión de Dependencias:
/// [FirestoreService], [MarketDataService] y [NotificationService] se inyectan
/// por constructor.
class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  PortfolioBloc({
    required FirestoreService firestoreService,
    required MarketDataService marketDataService,
    required NotificationService notificationService,
  })  : _firestore = firestoreService,
        _market = marketDataService,
        _notifications = notificationService,
        super(const PortfolioInitial()) {
    on<LoadPortfolioData>(_onLoad);
    on<AddAssetEvent>(_onAddAsset);
    on<ToggleCurrencyEvent>(_onToggleCurrency);
  }

  final FirestoreService _firestore;
  final MarketDataService _market;
  final NotificationService _notifications;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  /// Carga todas las listas en paralelo desde Firestore, enriquece los precios
  /// de mercado con Yahoo Finance y emite [PortfolioLoaded].
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

      // Construir lista base desde Firestore
      final List<MarketAsset> baseMarkets =
          marketsJson.map(MarketAsset.fromJson).toList();

      // Obtener tickers únicos y enriquecer con precios en vivo
      final tickers =
          baseMarkets.map((a) => a.ticker).toSet().toList();
      final Map<String, double> livePrices =
          await _market.fetchLivePrices(tickers);

      final List<MarketAsset> enrichedMarkets = baseMarkets.map((asset) {
        final livePrice = livePrices[asset.ticker];
        return livePrice != null ? asset.copyWith(price: livePrice) : asset;
      }).toList();

      final loans = loansJson.map(LoanAsset.fromJson).toList();
      final physicals = physicalsJson.map(PhysicalAsset.fromJson).toList();
      final movements = movementsJson.map(Movement.fromJson).toList();

      // Programar recordatorios antes de emitir el estado
      unawaited(_scheduleAllReminders(loans, physicals));

      emit(PortfolioLoaded(
        markets: enrichedMarkets,
        loans: loans,
        physicals: physicals,
        movements: movements,
        totalInvested: _calculateInvestedCapital(movements),
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
          final updatedMovementsLoan = [newMovement, ...current.movements];
          final updatedLoans = [...current.loans, newLoan];
          unawaited(_scheduleAllReminders(updatedLoans, current.physicals));
          emit(current.copyWith(
            loans: updatedLoans,
            movements: updatedMovementsLoan,
            totalInvested:
                _calculateInvestedCapital(updatedMovementsLoan),
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
          final updatedMovementsPhysical = [newMovement, ...current.movements];
          final updatedPhysicals = [...current.physicals, newPhysical];
          unawaited(_scheduleAllReminders(current.loans, updatedPhysicals));
          emit(current.copyWith(
            physicals: updatedPhysicals,
            movements: updatedMovementsPhysical,
            totalInvested:
                _calculateInvestedCapital(updatedMovementsPhysical),
          ));

        default: // 'Accion/Cripto'
          final baseMarket = MarketAsset.fromJson(event.assetData);

          // Guardar en Firestore y consultar precio de mercado en paralelo.
          // El precio de compra actúa como fallback si Yahoo no responde.
          final results = await Future.wait([
            _firestore.saveAsset(event.uid, 'markets', event.assetData),
            _market.fetchLivePrices([baseMarket.ticker]),
          ]);

          final livePrices = results[1] as Map<String, double>;
          final livePrice = livePrices[baseMarket.ticker];
          final enrichedMarket = livePrice != null
              ? baseMarket.copyWith(price: livePrice)
              : baseMarket; // fallback = precio de compra del form

          // El movimiento siempre usa el precio de compra para reflejar
          // el coste real de la inversión, independiente del precio de mercado.
          newMovement = Movement(
            id: 'mov-${DateTime.now().millisecondsSinceEpoch}',
            title: 'Compra ${enrichedMarket.name}',
            amount: baseMarket.price * enrichedMarket.quantity,
            date: DateTime.now(),
            type: MovementType.investment,
            currency: enrichedMarket.currency,
          );
          await _firestore.saveMovement(event.uid, newMovement.toJson());
          final updatedMovements = [newMovement, ...current.movements];
          emit(current.copyWith(
            markets: [...current.markets, enrichedMarket],
            movements: updatedMovements,
            totalInvested: _calculateInvestedCapital(updatedMovements),
          ));
      }
    } catch (e) {
      addError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers de cálculo
  // ---------------------------------------------------------------------------

  /// Calcula la próxima fecha para un [paymentDay] dado.
  /// Si el día ya pasó en el mes actual, retorna el mismo día del mes siguiente.
  static DateTime _nextPaymentDate(int paymentDay) {
    final now = DateTime.now();
    // Clamp al último día del mes para evitar fechas inválidas (ej. 31 en febrero)
    final lastDayThisMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayThisMonth = paymentDay.clamp(1, lastDayThisMonth);
    final candidateThisMonth = DateTime(now.year, now.month, dayThisMonth);

    if (candidateThisMonth.isAfter(now)) return candidateThisMonth;

    // El día ya pasó este mes → ir al mes siguiente
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final lastDayNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    final dayNextMonth = paymentDay.clamp(1, lastDayNextMonth);
    return DateTime(nextYear, nextMonth, dayNextMonth);
  }

  /// Cancela todas las notificaciones previas y reprograma los recordatorios
  /// de todos los [loans] con [paymentDay] y todos los [physicals] con arriendo.
  Future<void> _scheduleAllReminders(
    List<LoanAsset> loans,
    List<PhysicalAsset> physicals,
  ) async {
    await _notifications.cancelAllNotifications();

    int notifId = 1000; // base de IDs para notificaciones de recordatorio

    for (final loan in loans) {
      final day = loan.paymentDay;
      if (day == null) continue;
      final scheduledDate = _nextPaymentDate(day);
      await _notifications.schedulePaymentReminder(
        id: notifId++,
        title: 'Cobro pendiente',
        body: 'Hoy es el día de pago del préstamo de ${loan.borrower}.',
        scheduledDate: scheduledDate,
      );
    }

    for (final physical in physicals) {
      if (!physical.hasRent) continue;
      final day = physical.rentPaymentDay;
      if (day == null) continue;
      final scheduledDate = _nextPaymentDate(day);
      await _notifications.schedulePaymentReminder(
        id: notifId++,
        title: 'Cobro de arriendo',
        body: 'Hoy corresponde cobrar el arriendo de ${physical.name}.',
        scheduledDate: scheduledDate,
      );
    }
  }

  /// Suma el capital que el usuario ha invertido partiendo de los movimientos.
  /// Considera `investment` (compras) e `income` (préstamos otorgados) como
  /// entradas de capital al portafolio.
  double _calculateInvestedCapital(List<Movement> movements) {
    double total = 0.0;
    for (final m in movements) {
      if (m.type == MovementType.investment ||
          m.type == MovementType.income) {
        // Normalizar a USD: si la moneda es COP, dividir entre TRM
        final amountUsd =
            m.currency == 'COP' ? m.amount / 4200.0 : m.amount;
        total += amountUsd;
      }
    }
    return total;
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
