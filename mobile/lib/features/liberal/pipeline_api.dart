import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'pipeline_model.dart';

/// API Pipeline (Libéral) — aligné sur LiberalPipelineController.
///
/// Routes backend :
///   GET   /api/liberal/pipeline?page=1
///   GET   /api/liberal/pipeline/{id}
///   POST  /api/liberal/pipeline
///   POST  /api/liberal/pipeline/{id}/event
///   PATCH /api/liberal/pipeline/{id}/probability
class PipelineApi {
  final Dio _dio = ApiClient().dio;

  Future<ProspectListResponse> list({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/api/liberal/pipeline',
        queryParameters: {'page': page},
      );
      return ProspectListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<ProspectDetail> getById(String id) async {
    try {
      final response = await _dio.get('/api/liberal/pipeline/$id');
      return ProspectDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<void> create({
    required String companyName,
    required String contactPerson,
    String? phoneNumber,
    String? email,
    int probability = 0,
  }) async {
    try {
      await _dio.post('/api/liberal/pipeline', data: {
        'companyName': companyName,
        'contactPerson': contactPerson,
        'phoneNumber': phoneNumber,
        'email': email,
        'probability': probability,
      });
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<void> addEvent(
    String prospectId, {
    required String eventType,
    required DateTime eventDate,
    String? notes,
  }) async {
    try {
      await _dio.post('/api/liberal/pipeline/$prospectId/event', data: {
        'eventType': eventType,
        'eventDate': eventDate.toIso8601String(),
        'notes': notes,
      });
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<void> updateProbability(String prospectId, int probability) async {
    try {
      await _dio.patch('/api/liberal/pipeline/$prospectId/probability', data: {
        'probability': probability,
      });
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Exception _toReadable(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('Impossible de joindre le serveur.');
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['error'] != null) {
        return Exception(data['error'].toString());
      }
      if (e.response!.statusCode == 404) return Exception('Prospect introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
