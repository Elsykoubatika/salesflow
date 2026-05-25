import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'intervention_model.dart';

/// API Interventions — aligné sur TechnicalInterventionsController.
class InterventionApi {
  final Dio _dio = ApiClient().dio;

  Future<InterventionListResponse> list({int page = 1}) async {
    try {
      final r = await _dio.get('/api/technical/interventions',
          queryParameters: {'page': page});
      return InterventionListResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<InterventionDetail> getById(String id) async {
    try {
      final r = await _dio.get('/api/technical/interventions/$id');
      return InterventionDetail.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> create({
    required String clientId,
    String? notes,
    required DateTime startTime,
  }) async {
    try {
      await _dio.post('/api/technical/interventions', data: {
        'clientId': clientId,
        'notes': notes,
        'startTime': startTime.toIso8601String(),
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> complete(String id, {String? notes}) async {
    try {
      await _dio.patch('/api/technical/interventions/$id/complete',
          data: {'notes': notes});
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> addChecklistItem(String interventionId, String title) async {
    try {
      await _dio.post(
          '/api/technical/interventions/$interventionId/checklist-items',
          data: {'title': title});
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  /// Coche / décoche un point de contrôle.
  /// PATCH /api/technical/interventions/{id}/checklist-items/{itemId}
  Future<void> toggleChecklistItem(
    String interventionId,
    String itemId, {
    required bool isCompleted,
  }) async {
    try {
      await _dio.patch(
        '/api/technical/interventions/$interventionId/checklist-items/$itemId',
        data: {'isCompleted': isCompleted},
      );
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
      if (e.response!.statusCode == 404) {
        return Exception('Intervention introuvable.');
      }
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
