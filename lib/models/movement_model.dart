/// Tipo de movimiento para clasificar el flujo de dinero.
enum MovementType {
  /// Compra de un activo de mercado (cripto, acción, etc.)
  investment,

  /// Ingreso de dinero (venta, dividendo, retorno de préstamo)
  income,

  /// Gasto / salida de dinero (comisión, retiro, etc.)
  expense,
}

/// Extiende [MovementType] con helpers de serialización.
extension MovementTypeX on MovementType {
  String get value => name; // 'investment' | 'income' | 'expense'

  static MovementType fromString(String raw) {
    return MovementType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => MovementType.investment,
    );
  }
}

/// Representa un movimiento (transacción) del libro mayor del usuario.
class Movement {
  const Movement({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.currency,
  });

  /// Identificador único del movimiento.
  final String id;

  /// Descripción breve, p.ej. "Compra Ecopetrol" o "Préstamo Tío Carlos".
  final String title;

  /// Valor absoluto de la transacción.
  final double amount;

  /// Fecha y hora en que ocurrió el movimiento.
  final DateTime date;

  /// Clasificación: [MovementType.investment], [MovementType.income] o
  /// [MovementType.expense].
  final MovementType type;

  /// 'COP' o 'USD'.
  final String currency;

  // ---------------------------------------------------------------------------
  // Serialización
  // ---------------------------------------------------------------------------

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        type: MovementTypeX.fromString(json['type'] as String),
        currency: json['currency'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.value,
        'currency': currency,
      };
}
