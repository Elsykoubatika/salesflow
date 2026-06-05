/// Modèles Devis Technique — alignés sur TechnicalQuoteResponse (DTOs backend).
library;

class QuoteListItem {
  final String id;
  final String quoteNumber;
  final String title;
  final String clientName;
  final double total;
  final String status;
  final int itemCount;

  QuoteListItem({
    required this.id,
    required this.quoteNumber,
    required this.title,
    required this.clientName,
    required this.total,
    required this.status,
    required this.itemCount,
  });

  factory QuoteListItem.fromJson(Map<String, dynamic> json) {
    return QuoteListItem(
      id: json['id'] as String? ?? '',
      quoteNumber: json['quoteNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      total: (json['total'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? 'Draft',
      itemCount: (json['itemCount'] as num? ?? 0).toInt(),
    );
  }
}

class QuoteListResponse {
  final List<QuoteListItem> items;
  final int total;
  final int acceptedCount;

  QuoteListResponse({
    required this.items,
    required this.total,
    required this.acceptedCount,
  });

  factory QuoteListResponse.fromJson(Map<String, dynamic> json) {
    return QuoteListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => QuoteListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
      acceptedCount: (json['acceptedCount'] as num? ?? 0).toInt(),
    );
  }
}

class QuoteDetail {
  final String id;
  final String quoteNumber;
  final String title;
  final String? description;
  final String? serviceLocation;
  final String clientName;
  final double estimatedHours;
  final double hourlyRate;
  final double materialsCost;
  final double laborCost;
  final double total;
  final String currency;
  final String status;
  final int itemCount;

  QuoteDetail({
    required this.id,
    required this.quoteNumber,
    required this.title,
    this.description,
    this.serviceLocation,
    required this.clientName,
    required this.estimatedHours,
    required this.hourlyRate,
    required this.materialsCost,
    required this.laborCost,
    required this.total,
    required this.currency,
    required this.status,
    required this.itemCount,
  });

  factory QuoteDetail.fromJson(Map<String, dynamic> json) {
    return QuoteDetail(
      id: json['id'] as String? ?? '',
      quoteNumber: json['quoteNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      serviceLocation: json['serviceLocation'] as String?,
      clientName: json['clientName'] as String? ?? '',
      estimatedHours: (json['estimatedHours'] as num? ?? 0).toDouble(),
      hourlyRate: (json['hourlyRate'] as num? ?? 0).toDouble(),
      materialsCost: (json['materialsCost'] as num? ?? 0).toDouble(),
      laborCost: (json['laborCost'] as num? ?? 0).toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'XAF',
      status: json['status'] as String? ?? 'Draft',
      itemCount: (json['itemCount'] as num? ?? 0).toInt(),
    );
  }
}
