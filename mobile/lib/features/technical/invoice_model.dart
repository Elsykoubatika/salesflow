/// Modèles Factures Techniques — alignés sur TechnicalInvoicesController (style _db).

class InvoiceItem {
  final String id;
  final String invoiceNumber;
  final String clientName;
  final String status;
  final double total;
  final double amountDue;
  final DateTime invoiceDate;
  final DateTime dueDate;

  InvoiceItem({
    required this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.status,
    required this.total,
    required this.amountDue,
    required this.invoiceDate,
    required this.dueDate,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      status: json['status'] as String? ?? 'Draft',
      total: (json['total'] as num? ?? 0).toDouble(),
      amountDue: (json['amountDue'] as num? ?? 0).toDouble(),
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'] as String)
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : DateTime.now(),
    );
  }
}

class InvoiceListResponse {
  final List<InvoiceItem> items;
  final int total;

  InvoiceListResponse({required this.items, required this.total});

  factory InvoiceListResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}

class InvoiceDetail {
  final String id;
  final String invoiceNumber;
  final String clientName;
  final String? serviceDescription;
  final double laborCost;
  final double actualHours;
  final double materialsCost;
  final double total;
  final double amountDue;
  final double advancePayment;
  final String status;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String currency;
  final String? notes;

  InvoiceDetail({
    required this.id,
    required this.invoiceNumber,
    required this.clientName,
    this.serviceDescription,
    required this.laborCost,
    required this.actualHours,
    required this.materialsCost,
    required this.total,
    required this.amountDue,
    required this.advancePayment,
    required this.status,
    required this.invoiceDate,
    required this.dueDate,
    this.paidDate,
    required this.currency,
    this.notes,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceDetail(
      id: json['id'] as String? ?? '',
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      serviceDescription: json['serviceDescription'] as String?,
      laborCost: (json['laborCost'] as num? ?? 0).toDouble(),
      actualHours: (json['actualHours'] as num? ?? 0).toDouble(),
      materialsCost: (json['materialsCost'] as num? ?? 0).toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      amountDue: (json['amountDue'] as num? ?? 0).toDouble(),
      advancePayment: (json['advancePayment'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? 'Draft',
      invoiceDate: json['invoiceDate'] != null
          ? DateTime.parse(json['invoiceDate'] as String)
          : DateTime.now(),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : DateTime.now(),
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'] as String)
          : null,
      currency: json['currency'] as String? ?? 'XAF',
      notes: json['notes'] as String?,
    );
  }
}
