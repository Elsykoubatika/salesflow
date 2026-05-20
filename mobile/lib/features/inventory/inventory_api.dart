import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'inventory_model.dart';

class InventoryApi {
  final Dio _dio = ApiClient().dio;

  Future<InventoryListResponse> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? lowStockOnly,
    bool? activeOnly,
  }) async {
    try {
      final response = await _dio.get('/api/inventory', queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (lowStockOnly != null) 'lowStockOnly': lowStockOnly,
        if (activeOnly != null) 'activeOnly': activeOnly,
      });
      return InventoryListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<InventoryItemDetail> getById(String id) async {
    try {
      final response = await _dio.get('/api/inventory/$id');
      return InventoryItemDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<InventoryItem> create({
    required String name,
    String? sku,
    String? description,
    String unit = 'pcs',
    required num initialQuantity,
    num? reorderThreshold,
    num? cost,
    String? productId,
  }) async {
    try {
      final response = await _dio.post('/api/inventory', data: {
        'name': name,
        'sku': sku,
        'description': description,
        'unit': unit,
        'initialQuantity': initialQuantity,
        'reorderThreshold': reorderThreshold,
        'cost': cost,
        'productId': productId,
      });
      return InventoryItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<InventoryItem> update(
    String id, {
    required String name,
    String? sku,
    String? description,
    String? unit,
    num? reorderThreshold,
    num? cost,
    String? productId,
  }) async {
    try {
      final response = await _dio.put('/api/inventory/$id', data: {
        'name': name,
        'sku': sku,
        'description': description,
        'unit': unit,
        'reorderThreshold': reorderThreshold,
        'cost': cost,
        'productId': productId,
      });
      return InventoryItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<InventoryItem> adjust(
    String id, {
    required num delta,
    required MovementReason reason,
    String? note,
  }) async {
    try {
      final response = await _dio.post('/api/inventory/$id/adjust', data: {
        'delta': delta,
        'reason': reason.value,
        'note': note,
      });
      return InventoryItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/inventory/$id');
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
      if (e.response!.statusCode == 404) return Exception('Article introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
