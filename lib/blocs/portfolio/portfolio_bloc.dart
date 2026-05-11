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
    on<DeleteAssetEvent>(_onDeleteAsset);
    on<RegisterLoanPaymentEvent>(_onRegisterLoanPayment);
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
  /// sin esperar un nuevo GET completo. También registra el movimiento de
  /// inversión asociado con el [assetId] para permitir limpieza al borrar.
  Future<void> _onAddAsset(
    AddAssetEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    final current = state;
    if (current is! PortfolioLoaded) return;

    try {
      Movement? newMovement;
      final now = DateTime.now();

      switch (event.type) {
        case 'Prestamo P2P':
          // Los préstamos otorgados son capital desplegado → MovementType.investment.
          final loanId =
              await _firestore.saveAsset(event.uid, 'loans', event.assetData);
          final newLoan = LoanAsset.fromJson({
            ...event.assetData,
            'id': loanId,
            'lastMovementDate': now.toIso8601String(),
          });
          newMovement = Movement(
            id: 'mov-${now.millisecondsSinceEpoch}',
            title: 'Préstamo ${newLoan.borrower}',
            amount: newLoan.amount,
            date: now,
            type: MovementType.investment, // capital desplegado, no ingreso
            currency: 'COP',
            assetId: loanId,
          );
          await _firestore.saveMovement(event.uid, newMovement.toJson());
          final updatedMovementsLoan = [newMovement, ...current.movements];
          final updatedLoans = [...current.loans, newLoan];
          unawaited(_scheduleAllReminders(updatedLoans, current.physicals));
          emit(current.copyWith(
            loans: updatedLoans,
            movements: updatedMovementsLoan,
            totalInvested: _calculateInvestedCapital(updatedMovementsLoan),
          ));

        case 'Bien Fisico':
          final physicalId = await _firestore.saveAsset(
              event.uid, 'physicals', event.assetData);
          final newPhysical = PhysicalAsset.fromJson(
              {...event.assetData, 'id': physicalId});
          newMovement = Movement(
            id: 'mov-${now.millisecondsSinceEpoch}',
            title: 'Compra ${newPhysical.name}',
            amount: newPhysical.acquisitionValue,
            date: now,
            type: MovementType.investment,
            currency: 'COP',
            assetId: physicalId,
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

          final marketId = results[0] as String;
          final livePrices = results[1] as Map<String, double>;
          final livePrice = livePrices[baseMarket.ticker];
          final enrichedMarket = baseMarket.copyWith(
            id: marketId,
            price: livePrice ?? baseMarket.price,
          );

          // El movimiento siempre usa el precio de compra para reflejar
          // el coste real de la inversión, independiente del precio de mercado.
          newMovement = Movement(
            id: 'mov-${now.millisecondsSinceEpoch}',
            title: 'Compra ${enrichedMarket.name}',
            amount: baseMarket.price * enrichedMarket.quantity,
            date: now,
            type: MovementType.investment,
            currency: enrichedMarket.currency,
            assetId: marketId,
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
  ///
  /// Por cada activo se programan hasta 3 alertas:
  ///   • 3 días antes  → aviso anticipado
  ///   • 1 día antes   → recordatorio urgente
  ///   • Día exacto    → alerta de cobro
  /// Solo se programan si la fecha de disparo es posterior a ahora.
  Future<void> _scheduleAllReminders(
    List<LoanAsset> loans,
    List<PhysicalAsset> physicals,
  ) async {
    await _notifications.cancelAllNotifications();

    // Genera 3 IDs únicos a partir del hashCode del activo.
    // El sufijo 0/1/2 garantiza que las 3 alertas del mismo activo
    // no se sobreescriban entre sí.
    (int, int, int) _ids(int hash) {
      final base = hash.abs() % 100000;
      return (base * 10, base * 10 + 1, base * 10 + 2);
    }

    Future<void> scheduleTriple({
      required int hash,
      required DateTime paymentDate,
      required String nameFor3Days,
      required String nameFor1Day,
      required String nameForToday,
    }) async {
      final ids = _ids(hash);
      final minus3 = paymentDate.subtract(const Duration(days: 3));
      final minus1 = paymentDate.subtract(const Duration(days: 1));

      await _notifications.schedulePaymentReminder(
        id: ids.$1,
        title: 'Cobro en 3 días',
        body: 'Se acerca el cobro de $nameFor3Days.',
        scheduledDate: minus3,
      );
      await _notifications.schedulePaymentReminder(
        id: ids.$2,
        title: '¡Cobro mañana!',
        body: '¡Mañana es el cobro de $nameFor1Day!',
        scheduledDate: minus1,
      );
      await _notifications.schedulePaymentReminder(
        id: ids.$3,
        title: 'Día de cobro',
        body: nameForToday,
        scheduledDate: paymentDate,
      );
    }

    for (final loan in loans) {
      final day = loan.paymentDay;
      if (day == null) continue;
      final paymentDate = _nextPaymentDate(day);
      await scheduleTriple(
        hash: loan.id.hashCode ^ loan.borrower.hashCode,
        paymentDate: paymentDate,
        nameFor3Days: 'préstamo de ${loan.borrower}',
        nameFor1Day: 'préstamo de ${loan.borrower}',
        nameForToday: 'Hoy es el día de pago del préstamo de ${loan.borrower}.',
      );
    }

    for (final physical in physicals) {
      if (!physical.hasRent) continue;
      final day = physical.rentPaymentDay;
      if (day == null) continue;
      final paymentDate = _nextPaymentDate(day);
      await scheduleTriple(
        hash: physical.id.hashCode ^ physical.name.hashCode,
        paymentDate: paymentDate,
        nameFor3Days: 'arriendo de ${physical.name}',
        nameFor1Day: 'arriendo de ${physical.name}',
        nameForToday: 'Hoy corresponde cobrar el arriendo de ${physical.name}.',
      );
    }
  }

  /// Suma el capital desplegado por el usuario a partir de los movimientos.
  /// Solo cuenta [MovementType.investment] (compras de activos, préstamos
  /// otorgados, compras de bienes). Los ingresos recibidos (intereses, rentas)
  /// se contabilizan por separado en [PortfolioLoaded.totalIncomeReceived].
  double _calculateInvestedCapital(List<Movement> movements) {
    double total = 0.0;
    for (final m in movements) {
      if (m.type == MovementType.investment) {
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

  /// Hard Delete consistente: elimina el activo Y sus movimientos de inversión
  /// inicial, garantizando que el ROI se restaure correctamente.
  ///
  /// Estrategia de matching de movimientos:
  ///   1. Por [assetId] (movimientos nuevos con el campo inyectado).
  ///   2. Por título (retrocompatibilidad con movimientos sin assetId).
  Future<void> _onDeleteAsset(
    DeleteAssetEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    final current = state;
    if (current is! PortfolioLoaded) return;

    // Encontrar el label del activo ANTES de filtrarlo (para retrocompat).
    String? assetLabel;
    switch (event.collection) {
      case 'markets':
        assetLabel = current.markets
            .where((a) => a.id == event.assetId)
            .firstOrNull
            ?.name;
      case 'loans':
        assetLabel = current.loans
            .where((a) => a.id == event.assetId)
            .firstOrNull
            ?.borrower;
      case 'physicals':
        assetLabel = current.physicals
            .where((a) => a.id == event.assetId)
            .firstOrNull
            ?.name;
    }

    // Identificar movimientos a eliminar (los vinculados a este activo).
    final movementsToDelete = current.movements.where((m) {
      // Matching primario: por assetId inyectado (datos nuevos).
      if (m.assetId == event.assetId) return true;
      // Matching secundario: por título (retrocompatibilidad datos antiguos).
      if (assetLabel != null &&
          m.assetId == null &&
          m.title.contains(assetLabel)) return true;
      return false;
    }).toList();

    final remainingMovements = current.movements
        .where((m) => !movementsToDelete.any((d) => d.id == m.id))
        .toList();

    final newTotalInvested = _calculateInvestedCapital(remainingMovements);

    // Optimistic update: eliminar activo + recalcular totalInvested.
    final newState = switch (event.collection) {
      'markets' => current.copyWith(
          markets: current.markets
              .where((a) => a.id != event.assetId)
              .toList(),
          movements: remainingMovements,
          totalInvested: newTotalInvested,
        ),
      'loans' => current.copyWith(
          loans: current.loans
              .where((a) => a.id != event.assetId)
              .toList(),
          movements: remainingMovements,
          totalInvested: newTotalInvested,
        ),
      'physicals' => current.copyWith(
          physicals: current.physicals
              .where((a) => a.id != event.assetId)
              .toList(),
          movements: remainingMovements,
          totalInvested: newTotalInvested,
        ),
      _ => current,
    };

    emit(newState);

    // Persistir borrado del activo + sus movimientos en segundo plano.
    unawaited(
      Future.wait([
        _firestore.deleteAsset(event.uid, event.collection, event.assetId),
        ...movementsToDelete
            .map((m) => _firestore.deleteMovement(event.uid, m.id)),
      ]).catchError((e) {
        addError(e);
        return <void>[];
      }),
    );
  }

  /// Motor de amortización de préstamos.
  ///
  /// Calcula el interés proporcional al período transcurrido desde el último
  /// movimiento y aplica el pago según su tipo:
  ///   - 'interest'  → cobra los intereses acumulados, actualiza lastMovementDate.
  ///   - 'principal' → abona al capital, actualiza outstandingPrincipal.
  ///     Si el capital llega a 0, el préstamo se considera liquidado y se elimina.
  Future<void> _onRegisterLoanPayment(
    RegisterLoanPaymentEvent event,
    Emitter<PortfolioState> emit,
  ) async {
    final current = state;
    if (current is! PortfolioLoaded) return;

    final loanIndex =
        current.loans.indexWhere((l) => l.id == event.loanId);
    if (loanIndex == -1) return;

    final loan = current.loans[loanIndex];
    final now = DateTime.now();

    // Interés proporcional al número de días transcurridos desde el último movimiento.
    // Protegido contra principal ≤ 0 y tasas nulas.
    final lastDate = loan.lastMovementDate ?? now;
    final daysDiff = now.difference(lastDate).inDays.clamp(0, 366);
    final interestRate = loan.monthlyRate > 0 ? loan.monthlyRate / 100.0 : 0.0;
    final accruedSinceLastPayment = loan.outstandingPrincipal > 0
        ? loan.outstandingPrincipal * interestRate * (daysDiff / 30.0)
        : 0.0;

    late final LoanAsset updatedLoan;
    late final Movement newMovement;

    if (event.paymentType == 'principal') {
      // Abono a capital: reduce outstandingPrincipal. Nunca puede ser negativo.
      final newPrincipal =
          (loan.outstandingPrincipal - event.amount).clamp(0.0, double.infinity);
      updatedLoan = loan.copyWith(
        outstandingPrincipal: newPrincipal,
        lastMovementDate: now,
        interestAccrued: loan.interestAccrued + accruedSinceLastPayment,
      );
      newMovement = Movement(
        id: 'mov-${now.millisecondsSinceEpoch}',
        title: 'Abono capital: ${loan.borrower}',
        amount: event.amount,
        date: now,
        type: MovementType.income,
        currency: 'COP',
        assetId: loan.id,
      );
    } else {
      // Cobro de intereses: no toca el capital. Reinicia el contador de intereses.
      updatedLoan = loan.copyWith(
        lastMovementDate: now,
        interestAccrued: 0.0,
      );
      newMovement = Movement(
        id: 'mov-${now.millisecondsSinceEpoch}',
        title: 'Cobro intereses: ${loan.borrower}',
        amount: event.amount,
        date: now,
        type: MovementType.income,
        currency: 'COP',
        assetId: loan.id,
      );
    }

    // Si el préstamo quedó totalmente liquidado, sacarlo de la lista.
    final isFullyPaid = updatedLoan.outstandingPrincipal == 0.0;
    final updatedLoans = List<LoanAsset>.from(current.loans);
    if (isFullyPaid) {
      updatedLoans.removeAt(loanIndex);
    } else {
      updatedLoans[loanIndex] = updatedLoan;
    }

    final updatedMovements = [newMovement, ...current.movements];
    emit(current.copyWith(loans: updatedLoans, movements: updatedMovements));

    // Persistir en segundo plano.
    final futures = <Future<void>>[
      _firestore.saveMovement(event.uid, newMovement.toJson()),
    ];
    if (isFullyPaid) {
      futures.add(_firestore.deleteAsset(event.uid, 'loans', loan.id));
    } else {
      futures.add(
        _firestore.updateAsset(event.uid, 'loans', loan.id, updatedLoan.toJson()),
      );
    }
    unawaited(Future.wait(futures).catchError((e) {
      addError(e);
      return <void>[];
    }));
  }
}
