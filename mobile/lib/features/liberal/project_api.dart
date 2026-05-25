import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'project_model.dart';

/// API Projets (Libéral) — aligné sur LiberalProjectsController.
class ProjectApi {
  final Dio _dio = ApiClient().dio;

  Future<ProjectListResponse> list({int page = 1}) async {
    try {
      final r = await _dio.get('/api/liberal/projects',
          queryParameters: {'page': page});
      return ProjectListResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<ProjectDetail> getById(String id) async {
    try {
      final r = await _dio.get('/api/liberal/projects/$id');
      return ProjectDetail.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> create({
    required String clientId,
    required String projectName,
    String? description,
    String? projectType,
    required DateTime startDate,
    required DateTime endDate,
    double budgetAmount = 0,
  }) async {
    try {
      await _dio.post('/api/liberal/projects', data: {
        'clientId': clientId,
        'projectName': projectName,
        'description': description,
        'projectType': projectType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'budgetAmount': budgetAmount,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> addDeliverable(
    String projectId, {
    required String title,
    String? description,
    required DateTime dueDate,
  }) async {
    try {
      await _dio.post('/api/liberal/projects/$projectId/deliverable', data: {
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> completeDeliverable(String projectId, String deliverableId) async {
    try {
      await _dio.patch(
          '/api/liberal/projects/$projectId/deliverable/$deliverableId');
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> updateStatus(String projectId, String status) async {
    try {
      await _dio.patch('/api/liberal/projects/$projectId/status',
          data: {'status': status});
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
      if (e.response!.statusCode == 404) return Exception('Projet introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
