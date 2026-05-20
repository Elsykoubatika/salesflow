/// Statuts du pipeline (mappent les valeurs int de l'API).
enum SalesOrderStatus {
  draft(0, 'Brouillon'),
  sent(1, 'Envoyé'),
  accepted(2, 'Accepté'),
  delivered(3, 'Livré'),
  paid(4, 'Payé'),
  rejected(5, 'Refusé'),
  cancelled(6, 'Annulé');

  final int value;
  final String label;
  const SalesOrderStatus(this.value, this.label);

  static SalesOrderStatus fromValue(int v) => SalesOrderStatus.values
      .firstWhere((s) => s.value == v, orElse: () => SalesOrderStatus.draft);
}

class SalesOrderItem {
  final String id;
  final String? productId;
  final String description;
  final num unitPrice;
  final num quantity;
  final num lineTotal;
  final String? notes;

  SalesOrderItem({
    required this.id,
    this.productId,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.notes,
  });

  factory SalesOrderItem.fromJson(Map<String, dynamic> json) {
    return SalesOrderItem(
      id: json['id'] as String,
      productId: json['productId'] as String?,
      description: json['description'] as String,
      unitPrice: json['unitPrice'] as num,
      quantity: json['quantity'] as num,
      lineTotal: json['lineTotal'] as num,
      notes: json['notes'] as String?,
    );
  }
}

class SalesOrder {
  final String id;
  final String orderNumber;
  final SalesOrderStatus status;
  final String clientId;
  final String clientName;
  final String currency;
  final num subtotal;
  final num taxAmount;
  final num total;
  final String? notes;
  final DateTime? expiresAt;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<SalesOrderItem> items;
  final List<SalesOrderStatus> allowedNextStatuses;

  SalesOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.clientId,
    required this.clientName,
    required this.currency,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.notes,
    this.expiresAt,
    this.sentAt,
    this.acceptedAt,
    this.deliveredAt,
    this.paidAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    this.updatedAt,
    required this.items,
    required this.allowedNextStatuses,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: SalesOrderStatus.fromValue(json['status'] as int),
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      currency: json['currency'] as String,
      subtotal: json['subtotal'] as num,
      taxAmount: json['taxAmount'] as num,
      total: json['total'] as num,
      notes: json['notes'] as String?,
      expiresAt: _parseDate(json['expiresAt']),
      sentAt: _parseDate(json['sentAt']),
      acceptedAt: _parseDate(json['acceptedAt']),
      deliveredAt: _parseDate(json['deliveredAt']),
      paidAt: _parseDate(json['paidAt']),
      cancelledAt: _parseDate(json['cancelledAt']),
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: _parseDate(json['updatedAt']),
      items: (json['items'] as List)
          .map((e) => SalesOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      allowedNextStatuses: (json['allowedNextStatuses'] as List)
          .map((v) => SalesOrderStatus.fromValue(v as int))
          .toList(),
    );
  }
}

DateTime? _parseDate(dynamic date) {
  if (date == null) return null;
  return DateTime.parse(date as String);
}

class SalesOrderListItemDto {
  final String id;
  final String? clientId;
  final String orderNumber;
  final SalesOrderStatus status;
  final String clientName;
  final String currency;
  final num total;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;

  SalesOrderListItemDto({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.clientName,
    required this.currency,
    required this.total,
    required this.createdAt,
    this.sentAt,
    this.acceptedAt,
    this.deliveredAt,
    this.paidAt,
    this.cancelledAt,
    this.clientId,
  });

  factory SalesOrderListItemDto.fromJson(Map<String, dynamic> json) {
    return SalesOrderListItemDto(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      status: SalesOrderStatus.fromValue(json['status'] as int),
      clientName: json['clientName'] as String,
      currency: json['currency'] as String,
      total: json['total'] as num,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sentAt: _parseDate(json['sentAt']),
      acceptedAt: _parseDate(json['acceptedAt']),
      deliveredAt: _parseDate(json['deliveredAt']),
      paidAt: _parseDate(json['paidAt']),
      cancelledAt: _parseDate(json['cancelledAt']),
      clientId: json['clientId'] as String?,
    );
  }
}

class SalesOrderListResponse {
  final List<SalesOrderListItemDto> items;
  final int total;
  final int page;
  final int pageSize;

  SalesOrderListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory SalesOrderListResponse.fromJson(Map<String, dynamic> json) {
    return SalesOrderListResponse(
      items: (json['items'] as List)
          .map((e) => SalesOrderListItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}
