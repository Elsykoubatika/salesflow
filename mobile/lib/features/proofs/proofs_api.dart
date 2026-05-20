import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'proof_model.dart';

class ProofsApi {
  final Dio _dio = ApiClient().dio;

  Future<ProofListResponse> list({
    int page = 1,
    int pageSize = 50,
    ProofStatus? status,
    String? clientId,
    String? salesOrderId,
  }) async {
    try {
      final response = await _dio.get('/api/proofs', queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status.value,
        if (clientId != null) 'clientId': clientId,
        if (salesOrderId != null) 'salesOrderId': salesOrderId,
      });
      return ProofListResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<Proof> getById(String id) async {
    try {
      final response = await _dio.get('/api/proofs/$id');
      return Proof.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  /// Récupère les bytes de l'image (utilisé pour l'affichage en plein écran).
  Future<Uint8List> getImage(String id) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/proofs/$id/image',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  /// Upload multipart : champ `file` (image) + champ `data` (JSON).
  Future<Proof> create({
    required String filePath,
    required num? amount,
    required String currency,
    required String? transactionReference,
    required MobileMoneyOperator operator,
    required DateTime? transactionDate,
    required String? notes,
    required String? clientId,
    required String? salesOrderId,
  }) async {
    try {
      final metadata = {
        'amount': amount,
        'currency': currency,
        'transactionReference': transactionReference,
        'operator': operator.value,
        'transactionDate': transactionDate?.toUtc().toIso8601String(),
        'notes': notes,
        'clientId': clientId,
        'salesOrderId': salesOrderId,
      };

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'data': jsonEncode(metadata),
      });

      // Timeout plus long pour upload (image jusqu'à 5 MB sur connexion 3G).
      final response = await _dio.post(
        '/api/proofs',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return Proof.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<Proof> update(
    String id, {
    required num? amount,
    required String currency,
    required String? transactionReference,
    required MobileMoneyOperator operator,
    required DateTime? transactionDate,
    required String? notes,
    required String? clientId,
    required String? salesOrderId,
    required ProofStatus status,
    required String? errorMessage,
  }) async {
    try {
      final response = await _dio.put('/api/proofs/$id', data: {
        'amount': amount,
        'currency': currency,
        'transactionReference': transactionReference,
        'operator': operator.value,
        'transactionDate': transactionDate?.toUtc().toIso8601String(),
        'notes': notes,
        'clientId': clientId,
        'salesOrderId': salesOrderId,
        'status': status.value,
        'errorMessage': errorMessage,
      });
      return Proof.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/api/proofs/$id');
    } on DioException catch (e) {
      throw _toReadable(e);
    }
  }

  Exception _toReadable(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connexion impossible. Vérifiez votre réseau.');
    }
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data['error'] != null) {
        return Exception(data['error'].toString());
      }
      if (e.response!.statusCode == 404) return Exception('Preuve introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
      if (e.response!.statusCode == 413) return Exception('Image trop volumineuse.');
    }
    return Exception('Erreur inattendue.');
  }
}
