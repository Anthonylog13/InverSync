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
    required this.name,
    required this.ticker,
    required this.quantity,
    required this.price,
    required this.changePercent,
    required this.iconKey,
    required this.currency,
  });

  final String name;
  final String ticker;
  final double quantity;
  final double price;
  final double changePercent;

  final String iconKey;
  final String currency;


  IconData get icon => IconMapper.fromString(iconKey);

  factory MarketAsset.fromJson(Map<String, dynamic> json) => MarketAsset(
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
    required this.label,
    required this.borrower,
    required this.amount,
    required this.monthlyRate,
    required this.monthsElapsed,
    required this.iconKey,
  });

  final String label;
  final String borrower;
  final double amount;
  final double monthlyRate;
  final int monthsElapsed;
  final String iconKey;

  IconData get icon => IconMapper.fromString(iconKey);

  factory LoanAsset.fromJson(Map<String, dynamic> json) => LoanAsset(
        label: json['label'] as String,
        borrower: json['borrower'] as String,
        amount: (json['amount'] as num).toDouble(),
        monthlyRate: (json['monthlyRate'] as num).toDouble(),
        monthsElapsed: json['monthsElapsed'] as int,
        iconKey: json['icon'] as String,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'borrower': borrower,
        'amount': amount,
        'monthlyRate': monthlyRate,
        'monthsElapsed': monthsElapsed,
        'icon': iconKey,
      };
}


class PhysicalAsset {
  const PhysicalAsset({
    required this.name,
    required this.category,
    required this.estimatedValue,
    required this.acquisitionValue,
    required this.iconKey,
  });

  final String name;
  final String category;
  final double estimatedValue;
  final double acquisitionValue;
  final String iconKey;

  IconData get icon => IconMapper.fromString(iconKey);

  factory PhysicalAsset.fromJson(Map<String, dynamic> json) => PhysicalAsset(
        name: json['name'] as String,
        category: json['category'] as String,
        estimatedValue: (json['estimatedValue'] as num).toDouble(),
        acquisitionValue: (json['acquisitionValue'] as num).toDouble(),
        iconKey: json['icon'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'estimatedValue': estimatedValue,
        'acquisitionValue': acquisitionValue,
        'icon': iconKey,
      };
}
