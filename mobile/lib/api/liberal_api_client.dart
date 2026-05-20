import 'package:dio/dio.dart';

class LiberalApiClient {
  final Dio _dio;
  final String _baseUrl;

  LiberalApiClient(this._dio, this._baseUrl);

  // Contracts
  Future<List<dynamic>> getContracts({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    
    final response = await _dio.get(
      '$_baseUrl/api/liberal-contracts',
      queryParameters: params,
    );
    return List.from(response.data);
  }

  Future<dynamic> createContract({
    required String clientId,
    required String contractName,
    required String serviceDescription,
    required String pricingModel, // Hourly, Daily, Project
    required double rate,
    required DateTime startDate,
    DateTime? endDate,
    required String engagementType,
    bool isRecurring = false,
    String? recurrencePattern,
    bool autoRenew = false,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/liberal-contracts',
      data: {
        'clientId': clientId,
        'contractName': contractName,
        'serviceDescription': serviceDescription,
        'pricingModel': pricingModel,
        'rate': rate,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'engagementType': engagementType,
        'isRecurring': isRecurring,
        'recurrencePattern': recurrencePattern,
        'autoRenew': autoRenew,
      },
    );
    return response.data;
  }

  Future<dynamic> signContract(String contractId) async {
    final response = await _dio.post(
      '$_baseUrl/api/liberal-contracts/$contractId/sign',
    );
    return response.data;
  }

  Future<dynamic> createInvoice({
    required String contractId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalHours,
    required double complexityMultiplier,
    required double advancePayment,
    String? deliverableDetails,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/liberal-contracts/$contractId/invoice',
      data: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'totalHours': totalHours,
        'complexityMultiplier': complexityMultiplier,
        'advancePayment': advancePayment,
        'deliverableDetails': deliverableDetails,
      },
    );
    return response.data;
  }

  // Prospects / Pipeline
  Future<List<dynamic>> getProspects({String? stage}) async {
    final params = <String, dynamic>{};
    if (stage != null) params['stage'] = stage;
    
    final response = await _dio.get(
      '$_baseUrl/api/prospects',
      queryParameters: params,
    );
    return List.from(response.data);
  }

  Future<dynamic> getPipelineStats() async {
    final response = await _dio.get('$_baseUrl/api/prospects/pipeline-stats');
    return response.data;
  }

  Future<dynamic> createProspect({
    required String companyName,
    required String contactPerson,
    required String email,
    required String phoneNumber,
    String? source,
    required double estimatedValue,
    String? notes,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/prospects',
      data: {
        'companyName': companyName,
        'contactPerson': contactPerson,
        'email': email,
        'phoneNumber': phoneNumber,
        'source': source,
        'estimatedValue': estimatedValue,
        'notes': notes,
      },
    );
    return response.data;
  }

  Future<dynamic> updateProspectStage({
    required String prospectId,
    required String stage,
    String? notes,
  }) async {
    final response = await _dio.put(
      '$_baseUrl/api/prospects/$prospectId/stage',
      data: {
        'stage': stage,
        'notes': notes,
      },
    );
    return response.data;
  }

  Future<dynamic> logEvent({
    required String prospectId,
    required String eventType,
    required DateTime eventDate,
    String? notes,
    bool isRenewalEvent = false,
    DateTime? nextFollowUp,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/prospects/$prospectId/event',
      data: {
        'eventType': eventType,
        'eventDate': eventDate.toIso8601String(),
        'notes': notes,
        'isRenewalEvent': isRenewalEvent,
        'nextFollowUp': nextFollowUp?.toIso8601String(),
      },
    );
    return response.data;
  }

  Future<dynamic> scheduleRenewal({
    required String prospectId,
    required DateTime renewalDate,
    bool addReminder = true,
  }) async {
    final response = await _dio.post(
      '$_baseUrl/api/prospects/$prospectId/schedule-renewal',
      data: {
        'renewalDate': renewalDate.toIso8601String(),
        'addReminder': addReminder,
      },
    );
    return response.data;
  }
}
