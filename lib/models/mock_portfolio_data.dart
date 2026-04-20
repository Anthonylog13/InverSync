import 'package:flutter/material.dart';

// ===========================================================================
// MODELOS
// ===========================================================================

class MarketAsset {
  const MarketAsset({
    required this.name,
    required this.ticker,
    required this.quantity,
    required this.price,
    required this.changePercent,
    required this.icon,
    required this.currency,
  });

  final String name;
  final String ticker;
  final double quantity;
  final double price;
  final double changePercent;
  final IconData icon;
  final String currency;
}

class LoanAsset {
  const LoanAsset({
    required this.label,
    required this.borrower,
    required this.amount,
    required this.monthlyRate,
    required this.monthsElapsed,
    required this.icon,
  });

  final String label;
  final String borrower;
  final double amount;
  final double monthlyRate;
  final int monthsElapsed;
  final IconData icon;
}

class PhysicalAsset {
  const PhysicalAsset({
    required this.name,
    required this.category,
    required this.estimatedValue,
    required this.acquisitionValue,
    required this.icon,
  });

  final String name;
  final String category;
  final double estimatedValue;
  final double acquisitionValue;
  final IconData icon;
}

// ===========================================================================
// DATOS MOCK
// ===========================================================================

const marketAssets = [
  MarketAsset(
    name: 'Bitcoin',
    ticker: 'BTC',
    quantity: 0.35,
    price: 62450.00,
    changePercent: 3.82,
    icon: Icons.currency_bitcoin_rounded,
    currency: 'USD',
  ),
  MarketAsset(
    name: 'Ecopetrol',
    ticker: 'ECO.CB',
    quantity: 150,
    price: 2340.00,
    changePercent: -1.15,
    icon: Icons.local_gas_station_rounded,
    currency: 'COP',
  ),
  MarketAsset(
    name: 'Alibaba',
    ticker: 'BABA',
    quantity: 20,
    price: 78.45,
    changePercent: 0.67,
    icon: Icons.shopping_bag_outlined,
    currency: 'USD',
  ),
  MarketAsset(
    name: 'Ethereum',
    ticker: 'ETH',
    quantity: 2.5,
    price: 3120.00,
    changePercent: 2.14,
    icon: Icons.diamond_outlined,
    currency: 'USD',
  ),
  MarketAsset(
    name: 'Bancolombia',
    ticker: 'BIC',
    quantity: 80,
    price: 32100.00,
    changePercent: -0.43,
    icon: Icons.account_balance_rounded,
    currency: 'COP',
  ),
  MarketAsset(
    name: 'Tencent',
    ticker: 'TCEHY',
    quantity: 35,
    price: 42.10,
    changePercent: 1.29,
    icon: Icons.games_outlined,
    currency: 'USD',
  ),
];

const loanAssets = [
  LoanAsset(
    label: 'Prestamo Tio Carlos',
    borrower: 'Carlos Gutierrez',
    amount: 100000,
    monthlyRate: 2.0,
    monthsElapsed: 3,
    icon: Icons.person_outline_rounded,
  ),
  LoanAsset(
    label: 'Prestamo Vecino Juan',
    borrower: 'Juan Perez',
    amount: 250000,
    monthlyRate: 1.5,
    monthsElapsed: 5,
    icon: Icons.handshake_outlined,
  ),
  LoanAsset(
    label: 'Prestamo Amiga Sofia',
    borrower: 'Sofia Ramirez',
    amount: 50000,
    monthlyRate: 0,
    monthsElapsed: 1,
    icon: Icons.favorite_border_rounded,
  ),
];

const physicalAssets = [
  PhysicalAsset(
    name: 'Moto TVS 200',
    category: 'Vehiculo',
    estimatedValue: 6500000,
    acquisitionValue: 8200000,
    icon: Icons.two_wheeler_rounded,
  ),
  PhysicalAsset(
    name: 'Lote Afueras',
    category: 'Finca Raiz',
    estimatedValue: 45000000,
    acquisitionValue: 30000000,
    icon: Icons.landscape_rounded,
  ),
  PhysicalAsset(
    name: 'Computador Setup',
    category: 'Tecnologia',
    estimatedValue: 4200000,
    acquisitionValue: 5800000,
    icon: Icons.computer_rounded,
  ),
];
