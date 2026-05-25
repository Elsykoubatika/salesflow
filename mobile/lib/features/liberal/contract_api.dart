import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'contract_model.dart';

/// API Contrats (Libéral) — aligné sur LiberalContractsController.
///   GET   /api/liberal/contracts
///   GET   /api/liberal/contracts/{id}
///   POST  /api/liberal/contracts
///   PATCH /api/liberal/contracts/{id}/sign
///   PATCH /api/liberal/contracts/{id}/renew
class ContractApi {
  final Dio _dio = ApiClient().dio;

  Future<ContractListResponse> list({int page = 1}) async {
    try {
      final r = await _dio.get('/api/liberal/contracts',
          queryParameters: {'page': page});
      return ContractListResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<ContractDetail> getById(String id) async {
    try {
      final r = await _dio.get('/api/liberal/contracts/$id');
      return ContractDetail.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> create({
    required String clientId,
    required String engagementType,
    String? notes,
  }) async {
    try {
      await _dio.post('/api/liberal/contracts', data: {
        'clientId': clientId,
        'engagementType': engagementType,
        'notes': notes,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> sign(String id) async {
    try {
      await _dio.patch('/api/liberal/contracts/$id/sign');
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> renew(String id, String recurrencePattern) async {
    try {
      await _dio.patch('/api/liberal/contracts/$id/renew',
          data: {'recurrencePattern': recurrencePattern});
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
      if (e.response!.statusCode == 404) return Exception('Contrat introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
