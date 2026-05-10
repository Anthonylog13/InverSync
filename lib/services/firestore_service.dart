import 'package:cloud_firestore/cloud_firestore.dart';

/// Repositorio de datos contra Cloud Firestore.
///
/// Estructura de colecciones:
///   users/{uid}/markets
///   users/{uid}/loans
///   users/{uid}/physicals
///   users/{uid}/movements
///
/// SOLID — Inversión de Dependencias:
/// [FirebaseFirestore] se inyecta por constructor; la clase nunca llama a
/// [FirebaseFirestore.instance] internamente, facilitando tests con Fakes.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ---------------------------------------------------------------------------
  // Helpers internos
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _col(
          String uid, String collection) =>
      _db.collection('users').doc(uid).collection(collection);

  Future<List<Map<String, dynamic>>> _getDocs(
      String uid, String collection) async {
    final snapshot = await _col(uid, collection).get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Lecturas
  // ---------------------------------------------------------------------------

  /// Retorna todos los activos de mercado del usuario [uid].
  Future<List<Map<String, dynamic>>> getMarkets(String uid) =>
      _getDocs(uid, 'markets');

  /// Retorna todos los préstamos del usuario [uid].
  Future<List<Map<String, dynamic>>> getLoans(String uid) =>
      _getDocs(uid, 'loans');

  /// Retorna todos los bienes físicos del usuario [uid].
  Future<List<Map<String, dynamic>>> getPhysicals(String uid) =>
      _getDocs(uid, 'physicals');

  /// Retorna todos los movimientos del usuario [uid].
  Future<List<Map<String, dynamic>>> getMovements(String uid) =>
      _getDocs(uid, 'movements');

  // ---------------------------------------------------------------------------
  // Escrituras
  // ---------------------------------------------------------------------------

  /// Agrega un nuevo activo en la subcolección [collectionPath] del usuario.
  ///
  /// [collectionPath] debe ser: 'markets', 'loans' o 'physicals'.
  Future<void> saveAsset(
    String uid,
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    await _col(uid, collectionPath).add(data);
  }

  /// Agrega un nuevo movimiento en la subcolección `movements` del usuario.
  Future<void> saveMovement(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _col(uid, 'movements').add(data);
  }
}
