import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import 'finance_model.dart';

/// API Finance (Libéral) — aligné sur LiberalFinanceController.
///   GET  /api/liberal/finance/accounts
///   POST /api/liberal/finance/accounts
///   POST /api/liberal/finance/accounts/{id}/transaction
///   POST /api/liberal/finance/accounts/{id}/budget
class FinanceApi {
  final Dio _dio = ApiClient().dio;

  Future<FinanceAccountListResponse> listAccounts({int page = 1}) async {
    try {
      final r = await _dio.get('/api/liberal/finance/accounts',
          queryParameters: {'page': page});
      return FinanceAccountListResponse.fromJson(
          r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> createAccount({
    required String accountName,
    required String accountType,
    double initialBalance = 0,
  }) async {
    try {
      await _dio.post('/api/liberal/finance/accounts', data: {
        'accountName': accountName,
        'accountType': accountType,
        'initialBalance': initialBalance,
      });
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  /// transactionType : "Credit" (entrée) ou "Debit" (sortie)
  Future<TransactionResult> addTransaction(
    String accountId, {
    required String transactionType,
    required double amount,
    required DateTime transactionDate,
    String? description,
  }) async {
    try {
      final r = await _dio.post(
        '/api/liberal/finance/accounts/$accountId/transaction',
        data: {
          'transactionType': transactionType,
          'amount': amount,
          'transactionDate': transactionDate.toIso8601String(),
          'description': description,
        },
      );
      return TransactionResult.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _err(e);
    }
  }

  Future<void> setBudget(
    String accountId, {
    required double plannedAmount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      await _dio.post('/api/liberal/finance/accounts/$accountId/budget', data: {
        'plannedAmount': plannedAmount,
        'period': period,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
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
      if (e.response!.statusCode == 404) return Exception('Compte introuvable.');
      if (e.response!.statusCode == 401) return Exception('Session expirée.');
    }
    return Exception('Erreur inattendue.');
  }
}
