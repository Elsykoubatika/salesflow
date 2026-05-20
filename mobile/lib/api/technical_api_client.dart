import 'package:dio/dio.dart';

class TechnicalApiClient {
  final Dio _dio;
  final String _baseUrl;

  TechnicalApiClient(this._dio, this._baseUrl);

  // Quotes
  Future<List<dynamic>> getQuotes() async {
    final response = await _dio.get('$_baseUrl/api/technical-quotes');
    return List.from(response.data);
  }

  Future<dynamic> getQuote(String id) async {
    final response = await _dio.get('$_baseUrl/api/technical-quotes/$id');
    return response.data;
  }

  Future<dynamic> createQuote({
    required String clientId,
    required String title,
    required String location,
    required double estimatedHours,
    required double hourlyRate,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/technical-quotes',
      data: {
        'clientId': clientId,
        'title': title,
        'serviceLocation': location,
        'estimatedHours': estimatedHours,
        'hourlyRate': hourlyRate,
        'items': items,
      },
    );
    return response.data;
  }

  // Intelligent Calculators
  Future<dynamic> calculateCementBags(String quoteId, double wallArea) async {
    final response = await _dio.post(
      '$_baseUrl/api/technical-quotes/$quoteId/calculate-cement',
      data: wallArea,
    );
    return response.data;
  }

  Future<dynamic> calculateOutlets(
    String quoteId, {
    required int bedrooms,
    required int bathrooms,
    required int kitchens,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/technical-quotes/$quoteId/calculate-outlets',
      data: {
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'kitchens': kitchens,
      },
    );
    return response.data;
  }

  Future<dynamic> calculateBreakers(
    String quoteId, {
    required double powerLoadKW,
    required String breakerType,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/technical-quotes/$quoteId/calculate-breakers',
      data: {
        'powerLoadKW': powerLoadKW,
        'breakerType': breakerType,
      },
    );
    return response.data;
  }

  Future<dynamic> calculatePlumbing(
    String quoteId, {
    required int bathrooms,
    required int kitchens,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/technical-quotes/$quoteId/calculate-plumbing',
      data: {
        'bathrooms': bathrooms,
        'kitchens': kitchens,
      },
    );
    return response.data;
  }

  // Invoices
  Future<List<dynamic>> getInvoices({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    
    final response = await _dio.get(
      '$_baseUrl/api/technical-invoices',
      queryParameters: params,
    );
    return List.from(response.data);
  }

  Future<dynamic> getInvoice(String id) async {
    final response = await _dio.get('$_baseUrl/api/technical-invoices/$id');
    return response.data;
  }

  Future<dynamic> createInvoice({
    required String interventionId,
    required String serviceDescription,
    required double hourlyRate,
    required double materialsCost,
    required double advancePayment,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/technical-invoices',
      data: {
        'interventionId': interventionId,
        'serviceDescription': serviceDescription,
        'hourlyRate': hourlyRate,
        'materialsCost': materialsCost,
        'advancePayment': advancePayment,
      },
    );
    return response.data;
  }

  // Payments
  Future<dynamic> recordPayment({
    required String invoiceId,
    required double amount,
    required String paymentMethod,
    String? mobileMoneyOperator,
    String? mobileMoneyReference,
    String? phoneNumber,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/technical-invoices/$invoiceId/record-payment',
      data: {
        'amount': amount,
        'paymentMethod': paymentMethod,
        'mobileMoneyOperator': mobileMoneyOperator,
        'mobileMoneyReference': mobileMoneyReference,
        'phoneNumber': phoneNumber,
      },
    );
    return response.data;
  }

  // PDF
  Future<String> generatePdf(String invoiceId) async {
    final response = await _dio.post(
      '$_baseUrl/api/technical-invoices/$invoiceId/generate-pdf',
    );
    return response.data['pdfUrl'];
  }

  Future<void> downloadPdf(String invoiceId, String filePath) async {
    await _dio.download(
      '$_baseUrl/api/technical-invoices/$invoiceId/download-pdf',
      filePath,
    );
  }
}
