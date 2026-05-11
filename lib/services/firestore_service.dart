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
    // El ID del documento de Firestore siempre gana sobre cualquier campo 'id'
    // almacenado en los datos. Esto garantiza que las eliminaciones por ID
    // funcionen tanto para datos nuevos como para datos legados.
    return snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
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

  /// Agrega un nuevo activo en la subcolección [collectionPath] del usuario
  /// y retorna el ID del documento creado en Firestore.
  ///
  /// [collectionPath] debe ser: 'markets', 'loans' o 'physicals'.
  Future<String> saveAsset(
    String uid,
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    final ref = await _col(uid, collectionPath).add(data);
    return ref.id;
  }

  /// Agrega un nuevo movimiento en la subcolección `movements` del usuario.
  /// Usa el campo 'id' del [data] como ID del documento para garantizar
  /// que las eliminaciones posteriores por ID funcionen correctamente.
  Future<void> saveMovement(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final customId = data['id'] as String?;
    if (customId != null && customId.isNotEmpty) {
      await _col(uid, 'movements').doc(customId).set(data);
    } else {
      await _col(uid, 'movements').add(data);
    }
  }

  /// Actualiza campos específicos de un activo existente.
  Future<void> updateAsset(
    String uid,
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _col(uid, collection).doc(docId).update(data);
  }

  /// Elimina un documento de la subcolección indicada.
  ///
  /// [collection] debe ser: 'markets', 'loans' o 'physicals'.
  Future<void> deleteAsset(
    String uid,
    String collection,
    String docId,
  ) async {
    await _col(uid, collection).doc(docId).delete();
  }

  /// Elimina un movimiento del historial por su ID.
  Future<void> deleteMovement(String uid, String movId) async {
    await _col(uid, 'movements').doc(movId).delete();
  }
}
