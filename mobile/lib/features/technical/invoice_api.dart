import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'invoice_model.dart';

/// API Factures Techniques — aligné sur TechnicalInvoicesController.
class InvoiceApi {
  final Dio _dio = ApiClient().dio;

  Future<InvoiceListResponse> list({int page = 1, String? status}) async {
    try {
      final r = await _dio.get('/api/technical/invoices', queryParameters: {
        'page': page,
        if (status != null) 'status': status,
      });
      return InvoiceListResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<InvoiceDetail> getById(String id) async {
    try {
      final r = await _dio.get('/api/technical/invoices/$id');
      return InvoiceDetail.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> create({
    required String clientId,
    required String description,
    required double actualHours,
    required double hourlyRate,
    double materialsCost = 0,
    double advancePayment = 0,
    String? notes,
  }) async {
    try {
      await _dio.post('/api/technical/invoices', data: {
        'clientId': clientId,
        'description': description,
        'actualHours': actualHours,
        'hourlyRateXAF': hourlyRate,
        'materialsCost': materialsCost,
        'advancePayment': advancePayment,
        'notes': notes,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> recordPayment(
    String invoiceId, {
    required double amount,
    String? paymentMethod,
    String? reference,
    String? notes,
  }) async {
    try {
      await _dio.post('/api/technical/invoices/$invoiceId/payment', data: {
        'amountXAF': amount,
        'paymentMethod': paymentMethod,
        'reference': reference,
        'paidAt': DateTime.now().toIso8601String(),
        'notes': notes,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> updateStatus(String invoiceId, String status) async {
    try {
      await _dio.patch('/api/technical/invoices/$invoiceId/status',
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
      if (e.response!.statusCode == 404) {
        return Exception('Facture introuvable.');
      }
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
