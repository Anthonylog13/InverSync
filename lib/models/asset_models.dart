import 'package:flutter/material.dart';


class IconMapper {
  IconMapper._();

  static const Map<String, IconData> _map = {
    'currency_bitcoin_rounded': Icons.currency_bitcoin_rounded,
    'local_gas_station_rounded': Icons.local_gas_station_rounded,
    'shopping_bag_outlined': Icons.shopping_bag_outlined,
    'diamond_outlined': Icons.diamond_outlined,
    'account_balance_rounded': Icons.account_balance_rounded,
    'games_outlined': Icons.games_outlined,
    'person_outline_rounded': Icons.person_outline_rounded,
    'handshake_outlined': Icons.handshake_outlined,
    'favorite_border_rounded': Icons.favorite_border_rounded,
    'two_wheeler_rounded': Icons.two_wheeler_rounded,
    'landscape_rounded': Icons.landscape_rounded,
    'computer_rounded': Icons.computer_rounded,
    'help_outline_rounded': Icons.help_outline_rounded,
  };

  static IconData fromString(String name) =>
      _map[name] ?? Icons.help_outline_rounded;
}


class MarketAsset {
  const MarketAsset({
    this.id = '',
    required this.name,
    required this.ticker,
    required this.quantity,
    required this.price,
    required this.changePercent,
    required this.iconKey,
    required this.currency,
  });

  /// Identificador del documento en Firestore (inyectado al leer).
  final String id;
  final String name;
  final String ticker;
  final double quantity;
  final double price;
  final double changePercent;

  final String iconKey;
  final String currency;


  IconData get icon => IconMapper.fromString(iconKey);

  /// Clona el activo reemplazando solo los campos indicados.
  MarketAsset copyWith({
    String? id,
    String? name,
    String? ticker,
    double? quantity,
    double? price,
    double? changePercent,
    String? iconKey,
    String? currency,
  }) =>
      MarketAsset(
        id: id ?? this.id,
        name: name ?? this.name,
        ticker: ticker ?? this.ticker,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
        changePercent: changePercent ?? this.changePercent,
        iconKey: iconKey ?? this.iconKey,
        currency: currency ?? this.currency,
      );

  factory MarketAsset.fromJson(Map<String, dynamic> json) => MarketAsset(
        id: (json['id'] as String?) ?? '',
        name: json['name'] as String,
        ticker: json['ticker'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        changePercent: (json['changePercent'] as num).toDouble(),
        iconKey: json['icon'] as String,
        currency: json['currency'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'ticker': ticker,
        'quantity': quantity,
        'price': price,
        'changePercent': changePercent,
        'icon': iconKey,
        'currency': currency,
      };
}

class LoanAsset {
  const LoanAsset({
    this.id = '',
    required this.label,
    required this.borrower,
    required this.amount,
    required this.monthlyRate,
    required this.iconKey,
    this.cuotas,
    double? outstandingPrincipal,
    this.paymentDay,
  }) : outstandingPrincipal = outstandingPrincipal ?? amount;

  /// Identificador del documento en Firestore.
  final String id;
  final String label;
  final String borrower;
  final double amount;
  final double monthlyRate;

  /// Número de cuotas pactadas. Opcional.
  final int? cuotas;

  /// Capital pendiente de cobro. Por defecto igual a [amount].
  final double outstandingPrincipal;

  final String iconKey;

  /// Día del mes (1–31) en que se cobra la cuota. Nulo si no está definido.
  final int? paymentDay;

  IconData get icon => IconMapper.fromString(iconKey);

  LoanAsset copyWith({
    String? id,
    String? label,
    String? borrower,
    double? amount,
    double? monthlyRate,
    int? cuotas,
    double? outstandingPrincipal,
    String? iconKey,
    int? paymentDay,
  }) =>
      LoanAsset(
        id: id ?? this.id,
        label: label ?? this.label,
        borrower: borrower ?? this.borrower,
        amount: amount ?? this.amount,
        monthlyRate: monthlyRate ?? this.monthlyRate,
        cuotas: cuotas ?? this.cuotas,
        outstandingPrincipal: outstandingPrincipal ?? this.outstandingPrincipal,
        iconKey: iconKey ?? this.iconKey,
        paymentDay: paymentDay ?? this.paymentDay,
      );

  factory LoanAsset.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num).toDouble();
    return LoanAsset(
      id: (json['id'] as String?) ?? '',
      label: json['label'] as String,
      borrower: json['borrower'] as String,
      amount: amount,
      monthlyRate: (json['monthlyRate'] as num).toDouble(),
      cuotas: (json['cuotas'] as num?)?.toInt(),
      outstandingPrincipal: (json['outstandingPrincipal'] as num?)?.toDouble() ?? amount,
      iconKey: json['icon'] as String,
      paymentDay: (json['paymentDay'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'borrower': borrower,
        'amount': amount,
        'monthlyRate': monthlyRate,
        'outstandingPrincipal': outstandingPrincipal,
        'icon': iconKey,
        if (cuotas != null) 'cuotas': cuotas,
        if (paymentDay != null) 'paymentDay': paymentDay,
      };
}


class PhysicalAsset {
  const PhysicalAsset({
    this.id = '',
    required this.name,
    required this.category,
    required this.estimatedValue,
    required this.acquisitionValue,
    required this.iconKey,
    this.hasRent = false,
    this.rentPaymentDay,
    this.rentAmount,
  });

  /// Identificador del documento en Firestore.
  final String id;
  final String name;
  final String category;
  final double estimatedValue;
  final double acquisitionValue;
  final String iconKey;

  /// Indica si el bien genera ingreso por arriendo.
  final bool hasRent;

  /// Día del mes (1–31) en que se cobra el arriendo. Nulo si [hasRent] es false.
  final int? rentPaymentDay;

  /// Valor mensual del arriendo. Nulo si [hasRent] es false.
  final double? rentAmount;

  IconData get icon => IconMapper.fromString(iconKey);

  PhysicalAsset copyWith({
    String? id,
    String? name,
    String? category,
    double? estimatedValue,
    double? acquisitionValue,
    String? iconKey,
    bool? hasRent,
    int? rentPaymentDay,
    double? rentAmount,
  }) =>
      PhysicalAsset(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        estimatedValue: estimatedValue ?? this.estimatedValue,
        acquisitionValue: acquisitionValue ?? this.acquisitionValue,
        iconKey: iconKey ?? this.iconKey,
        hasRent: hasRent ?? this.hasRent,
        rentPaymentDay: rentPaymentDay ?? this.rentPaymentDay,
        rentAmount: rentAmount ?? this.rentAmount,
      );

  factory PhysicalAsset.fromJson(Map<String, dynamic> json) => PhysicalAsset(
        id: (json['id'] as String?) ?? '',
        name: json['name'] as String,
        category: json['category'] as String,
        estimatedValue: (json['estimatedValue'] as num).toDouble(),
        acquisitionValue: (json['acquisitionValue'] as num).toDouble(),
        iconKey: json['icon'] as String,
        hasRent: (json['hasRent'] as bool?) ?? false,
        rentPaymentDay: (json['rentPaymentDay'] as num?)?.toInt(),
        rentAmount: (json['rentAmount'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'estimatedValue': estimatedValue,
        'acquisitionValue': acquisitionValue,
        'icon': iconKey,
        'hasRent': hasRent,
        if (rentPaymentDay != null) 'rentPaymentDay': rentPaymentDay,
        if (rentAmount != null) 'rentAmount': rentAmount,
      };
}
