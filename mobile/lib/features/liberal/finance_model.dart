/// Modèles du module Finance (Libéral).
/// Alignés sur LiberalFinanceController (style _db).

class FinanceAccount {
  final String id;
  final String accountName;
  final double currentBalance;
  final String accountType;

  FinanceAccount({
    required this.id,
    required this.accountName,
    required this.currentBalance,
    required this.accountType,
  });

  factory FinanceAccount.fromJson(Map<String, dynamic> json) {
    return FinanceAccount(
      id: json['id'] as String? ?? '',
      accountName: json['accountName'] as String? ?? 'Compte',
      currentBalance: (json['currentBalance'] as num? ?? 0).toDouble(),
      accountType: json['accountType'] as String? ?? '',
    );
  }
}

class FinanceAccountListResponse {
  final List<FinanceAccount> items;
  final int total;

  FinanceAccountListResponse({required this.items, required this.total});

  factory FinanceAccountListResponse.fromJson(Map<String, dynamic> json) {
    return FinanceAccountListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => FinanceAccount.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}

/// Résultat d'une transaction — retour de POST .../transaction
class TransactionResult {
  final String id;
  final double newBalance;
  final String transactionType;

  TransactionResult({
    required this.id,
    required this.newBalance,
    required this.transactionType,
  });

  factory TransactionResult.fromJson(Map<String, dynamic> json) {
    return TransactionResult(
      id: json['id'] as String? ?? '',
      newBalance: (json['newBalance'] as num? ?? 0).toDouble(),
      transactionType: json['transactionType'] as String? ?? '',
    );
  }
}
