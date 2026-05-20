import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'product_model.dart';

class CatalogApi {
  final Dio _dio = ApiClient().dio;

  Future<ProductListResponse> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? activeOnly,
  }) async {
    try {
      final response = await _dio.get('/api/Products', queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (activeOnly != null) 'activeOnly': activeOnly,
      });
      return ProductListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<Product> getById(String id) async {
    try {
      final response = await _dio.get('/api/Products/$id');
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<Product> create({
    required String name,
    required num price,
    String? description,
    String? currency,
    String? sku,
    String? imageUrl,
    String? variantsJson,
  }) async {
    try {
      final response = await _dio.post('/api/Products', data: {
        'name': name,
        'description': description,
        'price': price,
        'currency': currency ?? 'XAF',
        'sku': sku,
        'imageUrl': imageUrl,
        'variantsJson': variantsJson,
      });
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<Product> update(
    String id, {
    required String name,
    required num price,
    required bool isActive,
    String? description,
    String? currency,
    String? sku,
    String? imageUrl,
    String? variantsJson,
  }) async {
    try {
      final response = await _dio.put('/api/Products/$id', data: {
        'name': name,
        'description': description,
        'price': price,
        'currency': currency ?? 'XAF',
        'sku': sku,
        'imageUrl': imageUrl,
        'variantsJson': variantsJson,
        'isActive': isActive,
      });
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/Products/$id');
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  /// Génère un lien WhatsApp pré-rempli pour un produit donné.
  /// L'API utilise le numéro de téléphone du marchand connecté.
  Future<WhatsAppLink> getWhatsAppLink(String productId, {String? customMessage}) async {
    try {
      final response = await _dio.get(
        '/api/Products/$productId/whatsapp-link',
        queryParameters: {
          if (customMessage != null && customMessage.trim().isNotEmpty) 'customMessage': customMessage.trim(),
        },
      );
      return WhatsAppLink.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Exception _toReadable(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
      return Exception('Impossible de joindre le serveur.');
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['error'] != null) {
        return Exception(data['error'].toString());
      }
      if (e.response!.statusCode == 404) return Exception('Produit introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée. Reconnectez-vous.');
    }
    return Exception('Erreur inattendue.');
  }
}
