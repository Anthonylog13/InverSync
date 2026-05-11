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
/// [isCopCurrency] indica si la moneda base es COP (true) o USD (false).
/// [totalBalance]  suma de todos los valores de activos expresada en USD.
/// [totalInvested] capital total aportado por el usuario (suma de compras).
/// [roiPercent]    rentabilidad global ((balance-invested)/invested)*100.
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
        roiPercent = _calcRoi(
          _calcBalance(markets, loans, physicals),
          totalInvested,
        );

  final List<MarketAsset> markets;
  final List<LoanAsset> loans;
  final List<PhysicalAsset> physicals;
  final List<Movement> movements;
  final bool isCopCurrency;

  /// Suma de todos los valores de activos expresada en USD.
  final double totalBalance;

  /// Capital total invertido / aportado por el usuario (en USD).
  final double totalInvested;

  /// Rentabilidad global en porcentaje.
  final double roiPercent;

  static const double _usdToCop = 4200;

  /// Calcula el balance total en USD sumando las tres categorías.
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

    for (final l in loans) {
      total += l.amount / _usdToCop;
    }

    for (final p in physicals) {
      total += p.estimatedValue / _usdToCop;
    }

    return total;
  }

  /// Calcula el ROI: ((balance - invested) / invested) * 100.
  /// Devuelve 0.0 si el capital invertido es cero (evita ÷0).
  static double _calcRoi(double balance, double invested) {
    if (invested == 0.0) return 0.0;
    return ((balance - invested) / invested) * 100.0;
  }

  /// Crea una copia del estado modificando sólo los campos especificados.
  /// Recalcula [totalBalance] y [roiPercent] automáticamente.
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
