import 'dart:convert';

import 'package:http/http.dart' as http;

/// Servicio de datos de mercado en tiempo real via Yahoo Finance.
///
/// SOLID — Responsabilidad Única: solo obtiene precios actuales de tickers.
/// SOLID — Inversión de Dependencias: recibe [http.Client] por constructor
/// para facilitar tests unitarios con mocks.
class MarketDataService {
  MarketDataService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://query1.finance.yahoo.com/v8/finance/chart';

  /// Obtiene los precios actuales de una lista de [tickers] en paralelo.
  ///
  /// Retorna un mapa `{ ticker_interno → precio }`.
  /// Si un ticker falla (no existe, timeout, etc.), se omite del resultado
  /// para no bloquear los demás.
  Future<Map<String, double>> fetchLivePrices(List<String> tickers) async {
    if (tickers.isEmpty) return {};

    // Traducir cada ticker interno al formato que Yahoo Finance reconoce,
    // conservando la asociación original para restaurarla en el resultado.
    final translated = {for (final t in tickers) t: _mapTickerForYahoo(t)};

    final results = await Future.wait(
      translated.values.map((yahooTicker) => _fetchSingle(yahooTicker)),
      eagerError: false, // un fallo no cancela los demás
    );

    final Map<String, double> prices = {};
    final internalKeys = translated.keys.toList();
    for (int i = 0; i < internalKeys.length; i++) {
      final price = results[i];
      // Clave = ticker interno (original de Firestore) para que el BLoC haga match
      if (price != null) prices[internalKeys[i]] = price;
    }
    return prices;
  }

  /// Busca instrumentos financieros en Yahoo Finance dado un [query] libre.
  ///
  /// Retorna hasta 8 resultados con `symbol`, `shortname` y `exchange`.
  /// En caso de error o sin resultados devuelve lista vacía.
  Future<List<Map<String, String>>> searchTicker(String query) async {
    try {
      final uri = Uri.parse(
        'https://query2.finance.yahoo.com/v1/finance/search'
        '?q=${Uri.encodeComponent(query)}&quotesCount=8&newsCount=0',
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final quotes = body['quotes'] as List<dynamic>? ?? [];

      return quotes
          .whereType<Map<String, dynamic>>()
          .where((q) => q['symbol'] != null)
          .map((q) => {
                'symbol': (q['symbol'] as String?) ?? '',
                'shortname': (q['shortname'] as String?) ??
                    (q['longname'] as String?) ??
                    '',
                'exchange': (q['exchange'] as String?) ?? '',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Traduce un ticker interno al símbolo que Yahoo Finance reconoce.
  ///
  /// Reglas:
  /// 1. Mapa explícito para acciones BVC con ADR conocido en NYSE/NASDAQ.
  /// 2. Fallback general: reemplaza el sufijo `.CB` por `.CN` (mercado
  ///    colombiano en Yahoo). Los tickers sin `.CB` se devuelven tal cual.
  String _mapTickerForYahoo(String internalTicker) {
    // Mapa de tickers internos (.CB) a sus símbolos exactos en Yahoo Finance.
    // Ampliar según los activos que manejen los usuarios.
    const Map<String, String> _explicitMap = {
      'ECO.CB': 'EC',       // Ecopetrol → ADR en NYSE
      'ECO.CL': 'EC',       // Ecopetrol BVC (sufijo .CL)
      'ECO': 'EC',           // Ecopetrol sin sufijo
      'BCOL.CB': 'CIB',    // Bancolombia → ADR en NYSE
      'BCOL': 'CIB',        // Bancolombia sin sufijo
      'ISA.CB': 'ISA.CN',  // ISA → Bolsa de Colombia en Yahoo
      'ISA': 'ISA.CN',      // ISA sin sufijo
      'PFBCOLOM.CB': 'CIB', // Bancolombia pref. → mismo ADR
      'PFBCOLOM': 'CIB',    // sin sufijo
      'BTC-USD': 'BTC-USD', // Bitcoin (sin cambio)
      'ETH-USD': 'ETH-USD', // Ethereum (sin cambio)
    };

    if (_explicitMap.containsKey(internalTicker)) {
      return _explicitMap[internalTicker]!;
    }

    // Fallback: .CB → .CN (sufijo general de Colombia en Yahoo)
    return internalTicker.replaceAll('.CB', '.CN');
  }

  /// Hace un GET individual para [yahooTicker] y parsea el JSON de Yahoo Finance.
  ///
  /// Estructura esperada:
  /// ```json
  /// { "chart": { "result": [ { "meta": { "regularMarketPrice": 150.0 } } ] } }
  /// ```
  ///
  /// Retorna `null` si la petición falla o el ticker no existe.
  Future<double?> _fetchSingle(String yahooTicker) async {
    try {
      final uri = Uri.parse('$_baseUrl/$yahooTicker');
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final chart = body['chart'] as Map<String, dynamic>?;
      final resultList = chart?['result'] as List<dynamic>?;
      if (resultList == null || resultList.isEmpty) return null;

      final meta = (resultList[0] as Map<String, dynamic>)['meta']
          as Map<String, dynamic>?;
      final price = (meta?['regularMarketPrice'] as num?)?.toDouble();

      return price;
    } catch (_) {
      // Red caída, ticker inválido o respuesta malformada → ignorar
      return null;
    }
  }
}
