import 'package:dio/dio.dart';
import '../../api/api_client.dart';
import 'public_catalog_model.dart';

/// Client API pour les endpoints PUBLICS.
///
/// Important : ces endpoints n'exigent PAS de token JWT.
/// On utilise un Dio "nu" (sans intercepteur Authorization) pour éviter
/// d'envoyer un token expiré qui pourrait poser problème.
class PublicCatalogApi {
  final ApiClient _client;
  PublicCatalogApi(this._client);

  /// Liste paginée des produits publics.
  Future<PublicCatalogPage> list({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String sort = 'recent',
    int page = 1,
    int pageSize = 24,
  }) async {
    try {
      final response = await _client.dio.get(
        '/api/public/catalog',
        queryParameters: {
          if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
          if (category != null && category != 'all') 'category': category,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
          'sort': sort,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Réponse catalogue invalide.');
      }
      return PublicCatalogPage.fromJson(data);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  /// Détail d'un produit + infos vendeur.
  Future<PublicProductDetail> getDetail(String id) async {
    try {
      final response = await _client.dio.get('/api/public/catalog/$id');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Réponse produit invalide.');
      }
      return PublicProductDetail.fromJson(data);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  /// Liste des catégories disponibles.
  Future<List<CategoryItem>> getCategories() async {
    try {
      final response = await _client.dio.get('/api/public/catalog/categories');
      final list = response.data as List? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(CategoryItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  /// Passe une commande SANS compte. Crée auto un compte léger.
  Future<GuestOrderResult> placeGuestOrder({
    required String fullName,
    required String phoneNumber,
    required String deliveryAddress,
    String? region,
    required List<({String productId, int quantity})> items,
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/public/guest-orders',
        data: {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'deliveryAddress': deliveryAddress,
          if (region != null) 'region': region,
          'items': items
              .map((i) => {'productId': i.productId, 'quantity': i.quantity})
              .toList(),
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Réponse commande invalide.');
      }
      return GuestOrderResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        final err = (e.response!.data as Map)['error']?.toString();
        if (err != null) throw Exception(err);
      }
      throw _err(e);
    }
  }

  /// Signaler un produit (modération communautaire).
  Future<void> reportProduct({
    required String productId,
    required String reason,
    String? details,
    String? reporterContact,
  }) async {
    try {
      await _client.dio.post(
        '/api/public/reports',
        data: {
          'productId': productId,
          'reason': reason,
          if (details != null) 'details': details,
          if (reporterContact != null) 'reporterContact': reporterContact,
        },
      );
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  // ─── Erreurs ─────────────────────────────────────────────────────────────
  Exception _err(DioException e) {
    final code = e.response?.statusCode;
    if (code == 404) return Exception('Ressource introuvable.');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Connexion au serveur impossible.');
    }
    return Exception('Erreur inattendue.');
  }
}
