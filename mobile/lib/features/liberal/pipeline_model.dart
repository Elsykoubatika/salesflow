/// Modèles du module Pipeline (Libéral).
/// Alignés EXACTEMENT sur LiberalPipelineController du backend.
library;

/// Élément de la liste GET /api/liberal/pipeline
class ProspectListItem {
  final String id;
  final String companyName;
  final String contactPerson;
  final int probability; // 0–100
  final int eventCount;

  ProspectListItem({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.probability,
    required this.eventCount,
  });

  factory ProspectListItem.fromJson(Map<String, dynamic> json) {
    return ProspectListItem(
      id: json['id'] as String? ?? '',
      companyName: json['companyName'] as String? ?? 'Sans nom',
      contactPerson: json['contactPerson'] as String? ?? '',
      probability: (json['probability'] as num? ?? 0).toInt(),
      eventCount: (json['eventCount'] as num? ?? 0).toInt(),
    );
  }
}

/// Réponse paginée de GET /api/liberal/pipeline
class ProspectListResponse {
  final List<ProspectListItem> items;
  final int total;

  ProspectListResponse({required this.items, required this.total});

  factory ProspectListResponse.fromJson(Map<String, dynamic> json) {
    return ProspectListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => ProspectListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}

/// Événement du pipeline (appel, réunion, etc.)
class PipelineEvent {
  final String id;
  final String eventType;
  final String? notes;
  final DateTime eventDate;

  PipelineEvent({
    required this.id,
    required this.eventType,
    this.notes,
    required this.eventDate,
  });

  factory PipelineEvent.fromJson(Map<String, dynamic> json) {
    return PipelineEvent(
      id: json['id'] as String? ?? '',
      eventType: json['eventType'] as String? ?? '',
      notes: json['notes'] as String?,
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'] as String)
          : DateTime.now(),
    );
  }
}

/// Détail complet d'un prospect — GET /api/liberal/pipeline/{id}
class ProspectDetail {
  final String id;
  final String companyName;
  final String contactPerson;
  final String? phoneNumber;
  final String? email;
  final int probability;
  final List<PipelineEvent> events;

  ProspectDetail({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    this.phoneNumber,
    this.email,
    required this.probability,
    required this.events,
  });

  factory ProspectDetail.fromJson(Map<String, dynamic> json) {
    return ProspectDetail(
      id: json['id'] as String? ?? '',
      companyName: json['companyName'] as String? ?? 'Sans nom',
      contactPerson: json['contactPerson'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      probability: (json['probability'] as num? ?? 0).toInt(),
      events: (json['events'] as List? ?? [])
          .map((e) => PipelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
