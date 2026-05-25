import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'quote_model.dart';

/// API Devis Technique — aligné sur TechnicalQuotesController.
class QuoteApi {
  final Dio _dio = ApiClient().dio;

  Future<QuoteListResponse> list({int page = 1, String? status}) async {
    try {
      final r = await _dio.get('/api/technical/quotes', queryParameters: {
        'page': page,
        if (status != null) 'status': status,
      });
      return QuoteListResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<QuoteDetail> getById(String id) async {
    try {
      final r = await _dio.get('/api/technical/quotes/$id');
      return QuoteDetail.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> create({
    required String clientId,
    required String title,
    String? description,
    String? serviceLocation,
    required double estimatedHours,
    required double hourlyRate,
  }) async {
    try {
      await _dio.post('/api/technical/quotes', data: {
        'clientId': clientId,
        'title': title,
        'description': description,
        'serviceLocation': serviceLocation,
        'estimatedHours': estimatedHours,
        'hourlyRate': hourlyRate,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> addItem(
    String quoteId, {
    required String itemName,
    String itemType = 'Material',
    double quantity = 1,
    String unit = 'pcs',
    double unitPrice = 0,
  }) async {
    try {
      await _dio.post('/api/technical/quotes/$quoteId/items', data: {
        'itemName': itemName,
        'itemType': itemType,
        'quantity': quantity,
        'unit': unit,
        'unitPrice': unitPrice,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> send(String id) async {
    try {
      await _dio.patch('/api/technical/quotes/$id/send');
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> accept(String id) async {
    try {
      await _dio.patch('/api/technical/quotes/$id/accept');
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/technical/quotes/$id');
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Exception _err(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return Exception('Impossible de joindre le serveur.');
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['error'] != null) {
        return Exception(data['error'].toString());
      }
      if (e.response!.statusCode == 404) return Exception('Devis introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
