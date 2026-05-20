import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'client_model.dart';

class ClientsApi {
  final Dio _dio = ApiClient().dio;

  Future<ClientListResponse> list({int page = 1, int pageSize = 50, String? search}) async {
    try {
      final response = await _dio.get('/api/Clients', queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      });
      return ClientListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<Client> getById(String id) async {
    try {
      final response = await _dio.get('/api/Clients/$id');
      return Client.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<Client> create({
    required String fullName,
    String? phoneNumber,
    String? email,
    String? address,
    String? region,
    String? notes,
  }) async {
    try {
      final response = await _dio.post('/api/Clients', data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'address': address,
        'region': region,
        'notes': notes,
      });
      return Client.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<Client> update(
    String id, {
    required String fullName,
    String? phoneNumber,
    String? email,
    String? address,
    String? region,
    String? notes,
  }) async {
    try {
      final response = await _dio.put('/api/Clients/$id', data: {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'address': address,
        'region': region,
        'notes': notes,
      });
      return Client.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/Clients/$id');
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
      if (e.response!.statusCode == 404) return Exception('Client introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée. Reconnectez-vous.');
    }
    return Exception('Erreur inattendue.');
  }
}
