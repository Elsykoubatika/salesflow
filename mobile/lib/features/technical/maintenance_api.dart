import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'maintenance_model.dart';

/// API Maintenance — aligné sur TechnicalMaintenanceController.
class MaintenanceApi {
  final Dio _dio = ApiClient().dio;

  Future<MaintenanceListResponse> list({int page = 1}) async {
    try {
      final r = await _dio.get('/api/technical/maintenance',
          queryParameters: {'page': page});
      return MaintenanceListResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<MaintenanceDetail> getById(String id) async {
    try {
      final r = await _dio.get('/api/technical/maintenance/$id');
      return MaintenanceDetail.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> create({
    required String planName,
    String? description,
    required String frequency,
  }) async {
    try {
      await _dio.post('/api/technical/maintenance', data: {
        'planName': planName,
        'description': description,
        'frequency': frequency,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> addTask(
    String planId, {
    required String title,
    String? description,
    required DateTime dueDate,
    double estimatedHours = 0,
  }) async {
    try {
      await _dio.post('/api/technical/maintenance/$planId/task', data: {
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'estimatedHours': estimatedHours,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> completeTask(
    String planId,
    String taskId, {
    double actualHours = 0,
    double costPerHour = 0,
  }) async {
    try {
      await _dio.patch(
        '/api/technical/maintenance/$planId/task/$taskId',
        data: {'actualHours': actualHours, 'costPerHour': costPerHour},
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
      if (e.response!.statusCode == 404) return Exception('Plan introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
