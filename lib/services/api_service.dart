import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/asset_models.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();


  static const String _baseUrl = 'http://localhost:3002';

  Future<List<MarketAsset>> getMarkets() async {
    final response = await http.get(Uri.parse('$_baseUrl/mercados'));
    _checkStatus(response);
    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((e) => MarketAsset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LoanAsset>> getLoans() async {
    final response = await http.get(Uri.parse('$_baseUrl/prestamos'));
    _checkStatus(response);
    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((e) => LoanAsset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PhysicalAsset>> getPhysicals() async {
    final response = await http.get(Uri.parse('$_baseUrl/bienes'));
    _checkStatus(response);
    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((e) => PhysicalAsset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAsset(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Error al guardar activo [${response.statusCode}]: ${response.body}',
      );
    }
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
