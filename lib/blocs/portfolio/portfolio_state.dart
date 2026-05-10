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
final class PortfolioLoaded extends PortfolioState {
  PortfolioLoaded({
    required List<MarketAsset> markets,
    required List<LoanAsset> loans,
    required List<PhysicalAsset> physicals,
    List<Movement> movements = const [],
    this.isCopCurrency = true,
  })  : markets = List.unmodifiable(markets),
        loans = List.unmodifiable(loans),
        physicals = List.unmodifiable(physicals),
        movements = List.unmodifiable(movements),
        totalBalance = _calcBalance(markets, loans, physicals);

  final List<MarketAsset> markets;
  final List<LoanAsset> loans;
  final List<PhysicalAsset> physicals;
  final List<Movement> movements;
  final bool isCopCurrency;

  /// Suma de todos los valores de activos expresada en USD.
  final double totalBalance;

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

  /// Crea una copia del estado modificando sólo los campos especificados.
  /// Recalcula [totalBalance] automáticamente.
  PortfolioLoaded copyWith({
    List<MarketAsset>? markets,
    List<LoanAsset>? loans,
    List<PhysicalAsset>? physicals,
    List<Movement>? movements,
    bool? isCopCurrency,
  }) {
    return PortfolioLoaded(
      markets: markets ?? this.markets,
      loans: loans ?? this.loans,
      physicals: physicals ?? this.physicals,
      movements: movements ?? this.movements,
      isCopCurrency: isCopCurrency ?? this.isCopCurrency,
    );
  }

  @override
  List<Object?> get props =>
      [markets, loans, physicals, movements, isCopCurrency, totalBalance];
}

/// Error irrecuperable durante la carga de datos.
final class PortfolioError extends PortfolioState {
  const PortfolioError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
