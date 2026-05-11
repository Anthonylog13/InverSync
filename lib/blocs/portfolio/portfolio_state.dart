import 'package:equatable/equatable.dart';

import '../../models/asset_models.dart';
import '../../models/movement_model.dart';

/// Jerarquía sellada de estados del PortfolioBloc.
sealed class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de cualquier carga.
final class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

/// El BLoC está cargando datos desde la API.
final class PortfolioLoading extends PortfolioState {
  const PortfolioLoading();
}

/// Datos listos para mostrarse.
///
/// Las listas son inmutables (List.unmodifiable).
/// [isCopCurrency]        indica si la moneda base es COP (true) o USD (false).
/// [totalBalance]         suma del valor actual de todos los activos en USD.
/// [totalInvested]        capital total aportado (movimientos de tipo investment).
/// [totalIncomeReceived]  ingresos totales cobrados (intereses + rentas + devoluciones).
/// [roiPercent]           rentabilidad global = (balance + income - invested) / invested * 100.
final class PortfolioLoaded extends PortfolioState {
  PortfolioLoaded({
    required List<MarketAsset> markets,
    required List<LoanAsset> loans,
    required List<PhysicalAsset> physicals,
    List<Movement> movements = const [],
    this.isCopCurrency = true,
    this.totalInvested = 0.0,
  })  : markets = List.unmodifiable(markets),
        loans = List.unmodifiable(loans),
        physicals = List.unmodifiable(physicals),
        movements = List.unmodifiable(movements),
        totalBalance = _calcBalance(markets, loans, physicals),
        totalIncomeReceived = _calcIncome(movements),
        roiPercent = _calcRoi(
          _calcBalance(markets, loans, physicals),
          totalInvested,
          _calcIncome(movements),
        );

  final List<MarketAsset> markets;
  final List<LoanAsset> loans;
  final List<PhysicalAsset> physicals;
  final List<Movement> movements;
  final bool isCopCurrency;

  /// Valor de mercado actual de todos los activos en USD.
  final double totalBalance;

  /// Capital total invertido / aportado por el usuario (en USD).
  final double totalInvested;

  /// Ingresos cobrados acumulados en USD (intereses, rentas, abonos recibidos).
  final double totalIncomeReceived;

  /// Rentabilidad global en porcentaje.
  /// Fórmula: (balance + ingresos - invertido) / invertido × 100.
  final double roiPercent;

  static const double _usdToCop = 4200;

  /// Calcula el balance total en USD sumando el valor actual de cada categoría.
  /// Usa [outstandingPrincipal] (no [amount]) para los préstamos: refleja el
  /// capital pendiente real, no el monto original del préstamo.
  static double _calcBalance(
    List<MarketAsset> markets,
    List<LoanAsset> loans,
    List<PhysicalAsset> physicals,
  ) {
    double total = 0.0;

    for (final m in markets) {
      final valueInUsd = m.currency == 'COP'
          ? (m.price * m.quantity) / _usdToCop
          : m.price * m.quantity;
      total += valueInUsd;
    }

    // Usa outstandingPrincipal: a medida que se abona capital el balance baja.
    for (final l in loans) {
      total += l.outstandingPrincipal / _usdToCop;
    }

    for (final p in physicals) {
      total += p.estimatedValue / _usdToCop;
    }

    return total;
  }

  /// Suma todos los ingresos recibidos (type == income) en USD.
  /// Estos flujos de caja aumentan la rentabilidad real del portafolio.
  static double _calcIncome(List<Movement> movements) {
    double total = 0.0;
    for (final m in movements) {
      if (m.type == MovementType.income) {
        total += m.currency == 'COP' ? m.amount / _usdToCop : m.amount;
      }
    }
    return total;
  }

  /// ROI real: considera tanto la apreciación de activos como los ingresos cobrados.
  /// ((balance + ingresos - invertido) / invertido) × 100.
  /// Protege contra división por cero.
  static double _calcRoi(double balance, double invested, double income) {
    if (invested == 0.0) return 0.0;
    return ((balance + income - invested) / invested) * 100.0;
  }

  /// Crea una copia del estado modificando sólo los campos especificados.
  /// Recalcula [totalBalance], [totalIncomeReceived] y [roiPercent] automáticamente.
  PortfolioLoaded copyWith({
    List<MarketAsset>? markets,
    List<LoanAsset>? loans,
    List<PhysicalAsset>? physicals,
    List<Movement>? movements,
    bool? isCopCurrency,
    double? totalInvested,
  }) {
    return PortfolioLoaded(
      markets: markets ?? this.markets,
      loans: loans ?? this.loans,
      physicals: physicals ?? this.physicals,
      movements: movements ?? this.movements,
      isCopCurrency: isCopCurrency ?? this.isCopCurrency,
      totalInvested: totalInvested ?? this.totalInvested,
    );
  }

  @override
  List<Object?> get props => [
        markets,
        loans,
        physicals,
        movements,
        isCopCurrency,
        totalBalance,
        totalInvested,
        totalIncomeReceived,
        roiPercent,
      ];
}

/// Error irrecuperable durante la carga de datos.
final class PortfolioError extends PortfolioState {
  const PortfolioError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
