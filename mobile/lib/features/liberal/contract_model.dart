/// Modèles du module Contrats (Libéral).
/// Alignés sur LiberalContractsController (style _db, objets anonymes).

/// Élément de liste — GET /api/liberal/contracts
class ContractListItem {
  final String id;
  final String contractNumber;
  final String engagementType;
  final int invoiceCount;

  ContractListItem({
    required this.id,
    required this.contractNumber,
    required this.engagementType,
    required this.invoiceCount,
  });

  factory ContractListItem.fromJson(Map<String, dynamic> json) {
    return ContractListItem(
      id: json['id'] as String? ?? '',
      contractNumber: json['contractNumber'] as String? ?? '',
      engagementType: json['engagementType'] as String? ?? '',
      invoiceCount: (json['invoiceCount'] as num? ?? 0).toInt(),
    );
  }
}

class ContractListResponse {
  final List<ContractListItem> items;
  final int total;

  ContractListResponse({required this.items, required this.total});

  factory ContractListResponse.fromJson(Map<String, dynamic> json) {
    return ContractListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => ContractListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}

/// Détail — GET /api/liberal/contracts/{id}
class ContractDetail {
  final String id;
  final String contractNumber;
  final String engagementType;
  final DateTime? signedDate;
  final String? notes;

  ContractDetail({
    required this.id,
    required this.contractNumber,
    required this.engagementType,
    this.signedDate,
    this.notes,
  });

  bool get isSigned => signedDate != null;

  factory ContractDetail.fromJson(Map<String, dynamic> json) {
    return ContractDetail(
      id: json['id'] as String? ?? '',
      contractNumber: json['contractNumber'] as String? ?? '',
      engagementType: json['engagementType'] as String? ?? '',
      signedDate: json['signedDate'] != null
          ? DateTime.parse(json['signedDate'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
