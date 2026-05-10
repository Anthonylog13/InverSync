import 'package:flutter/foundation.dart';

import '../models/asset_models.dart';
import '../services/api_service.dart';

class PortfolioProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  List<MarketAsset> _markets = [];
  List<LoanAsset> _loans = [];
  List<PhysicalAsset> _physicals = [];

  bool _isLoading = false;
  String? _error;

  List<MarketAsset> get markets => List.unmodifiable(_markets);
  List<LoanAsset> get loans => List.unmodifiable(_loans);
  List<PhysicalAsset> get physicals => List.unmodifiable(_physicals);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<MarketAsset> markets = [];
      List<LoanAsset> loans = [];
      List<PhysicalAsset> physicals = [];

      await Future.wait([
        _api.getMarkets().then((v) => markets = v),
        _api.getLoans().then((v) => loans = v),
        _api.getPhysicals().then((v) => physicals = v),
      ]);

      _markets = markets;
      _loans = loans;
      _physicals = physicals;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


Future<void> addMarket(MarketAsset asset) async {
  await _api.saveAsset('mercados', asset.toJson());
  _markets = [..._markets, asset];
  notifyListeners();
}

Future<void> addLoan(LoanAsset asset) async {
  await _api.saveAsset('prestamos', asset.toJson());
  _loans = [..._loans, asset];
  notifyListeners();
}

Future<void> addPhysical(PhysicalAsset asset) async {
  await _api.saveAsset('bienes', asset.toJson());
  _physicals = [..._physicals, asset];
  notifyListeners();
}
}
