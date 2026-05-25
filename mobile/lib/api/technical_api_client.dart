import 'package:dio/dio.dart';
import 'api_client.dart';

/// API Module Technique — aligné sur le backend DealFlow Pro.
///
/// Routes backend confirmées :
///   /api/technical/quotes          (TechnicalQuotesController)
///   /api/technical/interventions   (TechnicalInterventionsController)
///   /api/technical/invoices        (TechnicalInvoicesController)
///   /api/technical/maintenance     (TechnicalMaintenanceController)
class TechnicalApiClient {
  final Dio _dio = ApiClient().dio;

  // ─── QUOTES — /api/technical/quotes ────────────────────────────────────────
  Future<dynamic> getQuotes({int page = 1, int pageSize = 20, String? status}) async {
    final r = await _dio.get('/api/technical/quotes', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
    });
    return r.data;
  }

  Future<dynamic> getQuote(String id) async {
    final r = await _dio.get('/api/technical/quotes/$id');
    return r.data;
  }

  Future<dynamic> createQuote({
    required String clientId,
    required String title,
    String? description,
    String? serviceLocation,
    required double estimatedHours,
    required double hourlyRate,
    List<Map<String, dynamic>>? items,
  }) async {
    final r = await _dio.post('/api/technical/quotes', data: {
      'clientId': clientId,
      'title': title,
      'description': description,
      'serviceLocation': serviceLocation,
      'estimatedHours': estimatedHours,
      'hourlyRate': hourlyRate,
      'items': items,
    });
    return r.data;
  }

  Future<dynamic> addQuoteItem(String quoteId, {
    required String itemName,
    String itemType = 'Material',
    double quantity = 1,
    String unit = 'pcs',
    double unitPrice = 0,
  }) async {
    final r = await _dio.post('/api/technical/quotes/$quoteId/items', data: {
      'itemName': itemName,
      'itemType': itemType,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
    });
    return r.data;
  }

  Future<dynamic> sendQuote(String id) async =>
      (await _dio.patch('/api/technical/quotes/$id/send')).data;

  Future<dynamic> acceptQuote(String id) async =>
      (await _dio.patch('/api/technical/quotes/$id/accept')).data;

  Future<void> deleteQuote(String id) async =>
      await _dio.delete('/api/technical/quotes/$id');

  // ─── INTERVENTIONS — /api/technical/interventions ──────────────────────────
  Future<dynamic> getInterventions({int page = 1, int pageSize = 20, String? status}) async {
    final r = await _dio.get('/api/technical/interventions', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
    });
    return r.data;
  }

  Future<dynamic> getIntervention(String id) async =>
      (await _dio.get('/api/technical/interventions/$id')).data;

  Future<dynamic> createIntervention({
    required String clientId,
    required String title,
    required String location,
    required DateTime startTime,
    String? technicalQuoteId,
  }) async {
    final r = await _dio.post('/api/technical/interventions', data: {
      'clientId': clientId,
      'title': title,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'technicalQuoteId': technicalQuoteId,
    });
    return r.data;
  }

  Future<dynamic> completeIntervention(String id) async =>
      (await _dio.patch('/api/technical/interventions/$id/complete')).data;

  Future<dynamic> addChecklistItem(String interventionId, {
    required String title,
    required String task,
  }) async {
    final r = await _dio.post(
      '/api/technical/interventions/$interventionId/checklist-items',
      data: {'title': title, 'task': task},
    );
    return r.data;
  }

  Future<dynamic> completeChecklistItem(String interventionId, String itemId) async =>
      (await _dio.post(
        '/api/technical/interventions/$interventionId/checklist-items/$itemId/complete',
      )).data;

  // ─── INVOICES — /api/technical/invoices ────────────────────────────────────
  Future<dynamic> getInvoices({int page = 1, int pageSize = 20, String? status}) async {
    final r = await _dio.get('/api/technical/invoices', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
    });
    return r.data;
  }

  Future<dynamic> getInvoice(String id) async =>
      (await _dio.get('/api/technical/invoices/$id')).data;

  Future<dynamic> createInvoice({
    required String clientId,
    required DateTime workStartDate,
    required DateTime workEndDate,
    required String serviceDescription,
    required String locationOfWork,
    required double hourlyRate,
    required double actualHours,
    double materialsCost = 0,
    double advancePayment = 0,
    String? technicalInterventionId,
    String? technicalQuoteId,
  }) async {
    final r = await _dio.post('/api/technical/invoices', data: {
      'clientId': clientId,
      'workStartDate': workStartDate.toIso8601String(),
      'workEndDate': workEndDate.toIso8601String(),
      'serviceDescription': serviceDescription,
      'locationOfWork': locationOfWork,
      'hourlyRate': hourlyRate,
      'actualHours': actualHours,
      'materialsCost': materialsCost,
      'advancePayment': advancePayment,
      'technicalInterventionId': technicalInterventionId,
      'technicalQuoteId': technicalQuoteId,
    });
    return r.data;
  }

  Future<dynamic> recordInvoicePayment(String invoiceId, {required double amountPaid}) async {
    final r = await _dio.post('/api/technical/invoices/$invoiceId/payment',
        data: {'amountPaid': amountPaid});
    return r.data;
  }

  Future<dynamic> updateInvoiceStatus(String invoiceId, {required String status}) async {
    final r = await _dio.patch('/api/technical/invoices/$invoiceId/status',
        data: {'status': status});
    return r.data;
  }

  // ─── MAINTENANCE — /api/technical/maintenance ──────────────────────────────
  Future<dynamic> getMaintenancePlans({bool activeOnly = true}) async {
    final r = await _dio.get('/api/technical/maintenance',
        queryParameters: {'activeOnly': activeOnly});
    return r.data;
  }

  Future<dynamic> getMaintenancePlan(String id) async =>
      (await _dio.get('/api/technical/maintenance/$id')).data;

  Future<dynamic> createMaintenancePlan({
    required String clientId,
    required String planName,
    required String assetName,
    String? assetModel,
    String? description,
    required String frequency,
    required double estimatedCost,
    required double estimatedDuration,
    required DateTime nextScheduledDate,
  }) async {
    final r = await _dio.post('/api/technical/maintenance', data: {
      'clientId': clientId,
      'planName': planName,
      'assetName': assetName,
      'assetModel': assetModel,
      'description': description,
      'frequency': frequency,
      'estimatedCost': estimatedCost,
      'estimatedDuration': estimatedDuration,
      'nextScheduledDate': nextScheduledDate.toIso8601String(),
    });
    return r.data;
  }

  Future<dynamic> addMaintenanceTask(String planId, {
    required String title,
    required DateTime dueDate,
    required double estimatedHours,
  }) async {
    final r = await _dio.post('/api/technical/maintenance/$planId/task', data: {
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'estimatedHours': estimatedHours,
    });
    return r.data;
  }

  Future<dynamic> completeMaintenanceTask(String planId, String taskId) async =>
      (await _dio.patch('/api/technical/maintenance/$planId/task/$taskId')).data;
}
