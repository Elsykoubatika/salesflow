/// Opérateur Mobile Money — doit matcher l'enum backend MobileMoneyOperator.
enum MobileMoneyOperator {
  other(0, 'Autre'),
  mtnMomo(1, 'MTN MoMo'),
  airtelMoney(2, 'Airtel Money');

  final int value;
  final String label;
  const MobileMoneyOperator(this.value, this.label);

  static MobileMoneyOperator fromValue(int v) => MobileMoneyOperator.values
      .firstWhere((o) => o.value == v, orElse: () => MobileMoneyOperator.other);
}

/// Statut d'une preuve — doit matcher l'enum backend ProofStatus.
enum ProofStatus {
  pending(0, 'En attente'),
  validated(1, 'Validée'),
  error(2, 'Erreur');

  final int value;
  final String label;
  const ProofStatus(this.value, this.label);

  static ProofStatus fromValue(int v) => ProofStatus.values.firstWhere(
    (s) => s.value == v,
    orElse: () => ProofStatus.pending,
  );
}

class Proof {
  final String id;
  final String imageContentType;
  final int imageSizeBytes;
  final num? amount;
  final String currency;
  final String? transactionReference;
  final MobileMoneyOperator operator;
  final DateTime? transactionDate;
  final String? notes;
  final ProofStatus status;
  final String? errorMessage;
  final String? clientId;
  final String? clientName;
  final String? salesOrderId;
  final String? orderNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Proof({
    required this.id,
    required this.imageContentType,
    required this.imageSizeBytes,
    this.amount,
    required this.currency,
    this.transactionReference,
    required this.operator,
    this.transactionDate,
    this.notes,
    required this.status,
    this.errorMessage,
    this.clientId,
    this.clientName,
    this.salesOrderId,
    this.orderNumber,
    required this.createdAt,
    this.updatedAt,
  });

  factory Proof.fromJson(Map<String, dynamic> json) {
    return Proof(
      id: json['id'] as String,
      imageContentType: json['imageContentType'] as String,
      imageSizeBytes: json['imageSizeBytes'] as int,
      amount: json['amount'] as num?,
      currency: json['currency'] as String? ?? 'XAF',
      transactionReference: json['transactionReference'] as String?,
      operator: MobileMoneyOperator.fromValue(json['operator'] as int),
      transactionDate: _parseDate(json['transactionDate']),
      notes: json['notes'] as String?,
      status: ProofStatus.fromValue(json['status'] as int),
      errorMessage: json['errorMessage'] as String?,
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String?,
      salesOrderId: json['salesOrderId'] as String?,
      orderNumber: json['orderNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class ProofListResponse {
  final List<Proof> items;
  final int total;
  final int page;
  final int pageSize;
  final int pendingCount;

  ProofListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pendingCount,
  });

  factory ProofListResponse.fromJson(Map<String, dynamic> json) {
    return ProofListResponse(
      items: (json['items'] as List)
          .map((e) => Proof.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
      pendingCount: json['pendingCount'] as int,
    );
  }
}

DateTime? _parseDate(dynamic date) {
  if (date == null) return null;
  return DateTime.parse(date as String);
}
