import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'sales_order_model.dart';

/// Représente une ligne à créer (envoyée à POST /api/sales-orders).
class CreateOrderItemPayload {
  final String? productId;
  final String description;
  final num unitPrice;
  final num quantity;
  final String? notes;

  CreateOrderItemPayload({
    this.productId,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'description': description,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'notes': notes,
      };
}

class SalesApi {
  final Dio _dio = ApiClient().dio;

  Future<SalesOrderListResponse> list({
    int page = 1,
    int pageSize = 50,
    SalesOrderStatus? status,
    String? clientId,
  }) async {
    try {
      final response = await _dio.get('/api/sales-orders', queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status.value,
        if (clientId != null) 'clientId': clientId,
      });
      return SalesOrderListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<SalesOrder> getById(String id) async {
    try {
      final response = await _dio.get('/api/sales-orders/$id');
      return SalesOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<SalesOrder> create({
    required String clientId,
    String? currency,
    num taxAmount = 0,
    String? notes,
    DateTime? expiresAt,
    required List<CreateOrderItemPayload> items,
  }) async {
    try {
      final response = await _dio.post('/api/sales-orders', data: {
        'clientId': clientId,
        'currency': currency ?? 'XAF',
        'taxAmount': taxAmount,
        'notes': notes,
        'expiresAt': expiresAt?.toUtc().toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      });
      return SalesOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<SalesOrder> transition(String id, SalesOrderStatus newStatus, {String? reason}) async {
    try {
      final response = await _dio.post('/api/sales-orders/$id/transition', data: {
        'newStatus': newStatus.value,
        'reason': reason,
      });
      return SalesOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/sales-orders/$id');
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
      if (e.response!.statusCode == 404) return Exception('Document introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
