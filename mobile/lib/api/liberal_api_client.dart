import 'package:dio/dio.dart';
import 'api_client.dart';

/// API Module Libéral — aligné sur le backend DealFlow Pro.
///
/// Routes backend confirmées :
///   /api/liberal/contracts   (LiberalContractsController)
///   /api/liberal/pipeline    (LiberalPipelineController)
///   /api/liberal/projects    (LiberalProjectsController)
///   /api/liberal/finance     (LiberalFinanceController)
class LiberalApiClient {
  final Dio _dio = ApiClient().dio;

  // ─── CONTRACTS — /api/liberal/contracts ────────────────────────────────────
  Future<dynamic> getContracts({int page = 1, int pageSize = 20, String? status}) async {
    final r = await _dio.get('/api/liberal/contracts', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
    });
    return r.data;
  }

  Future<dynamic> getContract(String id) async =>
      (await _dio.get('/api/liberal/contracts/$id')).data;

  Future<dynamic> createContract({
    required String clientId,
    required String contractName,
    String? serviceDescription,
    required String pricingModel, // Hourly, Daily, Project, Retainer
    double? rate,
    required DateTime startDate,
    DateTime? endDate,
    required String engagementType,
    bool isRecurring = false,
    String? recurrencePattern,
    bool autoRenew = false,
    String? notes,
  }) async {
    final r = await _dio.post('/api/liberal/contracts', data: {
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
      'notes': notes,
    });
    return r.data;
  }

  Future<dynamic> signContract(String id, {required DateTime signDate}) async {
    final r = await _dio.patch('/api/liberal/contracts/$id/sign',
        data: {'signDate': signDate.toIso8601String()});
    return r.data;
  }

  Future<dynamic> renewContract(String id, {
    required String recurrencePattern,
    required DateTime nextRenewalDate,
  }) async {
    final r = await _dio.patch('/api/liberal/contracts/$id/renew', data: {
      'recurrencePattern': recurrencePattern,
      'nextRenewalDate': nextRenewalDate.toIso8601String(),
    });
    return r.data;
  }

  // ─── PIPELINE — /api/liberal/pipeline ──────────────────────────────────────
  Future<dynamic> getProspects({int page = 1, int pageSize = 20, String? stage}) async {
    final r = await _dio.get('/api/liberal/pipeline', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (stage != null) 'stage': stage,
    });
    return r.data;
  }

  Future<dynamic> getProspect(String id) async =>
      (await _dio.get('/api/liberal/pipeline/$id')).data;

  Future<dynamic> createProspect({
    required String companyName,
    required String contactPerson,
    String? email,
    String? phoneNumber,
    String? source,
    required double estimatedValue,
    String? notes,
  }) async {
    final r = await _dio.post('/api/liberal/pipeline', data: {
      'companyName': companyName,
      'contactPerson': contactPerson,
      'email': email,
      'phoneNumber': phoneNumber,
      'source': source,
      'estimatedValue': estimatedValue,
      'notes': notes,
    });
    return r.data;
  }

  Future<dynamic> logEvent(String prospectId, {
    required String eventType,
    required DateTime eventDate,
    String? notes,
    bool isRenewalEvent = false,
    DateTime? nextFollowUp,
  }) async {
    final r = await _dio.post('/api/liberal/pipeline/$prospectId/event', data: {
      'eventType': eventType,
      'eventDate': eventDate.toIso8601String(),
      'notes': notes,
      'isRenewalEvent': isRenewalEvent,
      'nextFollowUp': nextFollowUp?.toIso8601String(),
    });
    return r.data;
  }

  /// Met à jour l'étape (stage) du prospect.
  Future<dynamic> updateProspectStage(String prospectId, {
    required String stage,
    String? notes,
  }) async {
    final r = await _dio.patch('/api/liberal/pipeline/$prospectId/probability',
        data: {'stage': stage, 'notes': notes});
    return r.data;
  }

  // ─── PROJECTS — /api/liberal/projects ──────────────────────────────────────
  Future<dynamic> getProjects({int page = 1, int pageSize = 20, String? status}) async {
    final r = await _dio.get('/api/liberal/projects', queryParameters: {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
    });
    return r.data;
  }

  Future<dynamic> getProject(String id) async =>
      (await _dio.get('/api/liberal/projects/$id')).data;

  Future<dynamic> createProject({
    required String clientId,
    required String projectName,
    String? description,
    String? projectType,
    required DateTime startDate,
    required DateTime endDate,
    double budgetAmount = 0,
    double estimatedHours = 0,
    double hourlyRate = 0,
    String? notes,
  }) async {
    final r = await _dio.post('/api/liberal/projects', data: {
      'clientId': clientId,
      'projectName': projectName,
      'description': description,
      'projectType': projectType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budgetAmount': budgetAmount,
      'estimatedHours': estimatedHours,
      'hourlyRate': hourlyRate,
      'notes': notes,
    });
    return r.data;
  }

  Future<dynamic> addDeliverable(String projectId, {
    required String title,
    String? description,
    required DateTime dueDate,
  }) async {
    final r = await _dio.post('/api/liberal/projects/$projectId/deliverable', data: {
      'projectId': projectId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
    });
    return r.data;
  }

  Future<dynamic> completeDeliverable(String projectId, String deliverableId) async =>
      (await _dio.patch('/api/liberal/projects/$projectId/deliverable/$deliverableId')).data;

  Future<dynamic> updateProjectStatus(String projectId, {required String status}) async {
    final r = await _dio.patch('/api/liberal/projects/$projectId/status',
        data: {'status': status});
    return r.data;
  }

  // ─── FINANCE — /api/liberal/finance ────────────────────────────────────────
  Future<dynamic> getAccounts({int page = 1, int pageSize = 20}) async {
    final r = await _dio.get('/api/liberal/finance/accounts',
        queryParameters: {'page': page, 'pageSize': pageSize});
    return r.data;
  }

  Future<dynamic> createAccount({
    required String accountName,
    String? description,
    required String accountType,
    double openingBalance = 0,
  }) async {
    final r = await _dio.post('/api/liberal/finance/accounts', data: {
      'accountName': accountName,
      'description': description,
      'accountType': accountType,
      'openingBalance': openingBalance,
    });
    return r.data;
  }

  Future<dynamic> recordTransaction(String accountId, {
    required String transactionType, // Income, Expense, Transfer
    required double amount,
    String? category,
    String? description,
    required DateTime transactionDate,
  }) async {
    final r = await _dio.post('/api/liberal/finance/accounts/$accountId/transaction', data: {
      'accountId': accountId,
      'transactionType': transactionType,
      'amount': amount,
      'category': category,
      'description': description,
      'transactionDate': transactionDate.toIso8601String(),
    });
    return r.data;
  }

  Future<dynamic> createBudget(String accountId, {
    required String budgetName,
    String? category,
    required double plannedAmount,
    required String period, // Weekly, Monthly, Yearly
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final r = await _dio.post('/api/liberal/finance/accounts/$accountId/budget', data: {
      'accountId': accountId,
      'budgetName': budgetName,
      'category': category,
      'plannedAmount': plannedAmount,
      'period': period,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    });
    return r.data;
  }
}
