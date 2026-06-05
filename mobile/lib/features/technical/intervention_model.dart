/// Modèles Interventions Techniques — alignés sur TechnicalInterventionsController (style _db).
library;

/// Point de contrôle d'une intervention.
class ChecklistItem {
  final String id;
  final String title;
  final bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

/// Élément de liste — GET /api/technical/interventions
class InterventionItem {
  final String id;
  final String clientName;
  final String? notes;
  final DateTime startTime;
  final String status;

  InterventionItem({
    required this.id,
    required this.clientName,
    this.notes,
    required this.startTime,
    required this.status,
  });

  factory InterventionItem.fromJson(Map<String, dynamic> json) {
    return InterventionItem(
      id: json['id'] as String? ?? '',
      clientName: json['clientName'] as String? ?? 'Client',
      notes: json['notes'] as String?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'Scheduled',
    );
  }
}

class InterventionListResponse {
  final List<InterventionItem> items;
  final int total;

  InterventionListResponse({required this.items, required this.total});

  factory InterventionListResponse.fromJson(Map<String, dynamic> json) {
    return InterventionListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => InterventionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}

/// Détail complet — GET /api/technical/interventions/{id}
/// Inclut désormais la checklist (le backend la renvoie).
class InterventionDetail {
  final String id;
  final String clientName;
  final String? notes;
  final DateTime startTime;
  final String status;
  final List<ChecklistItem> checklistItems;

  InterventionDetail({
    required this.id,
    required this.clientName,
    this.notes,
    required this.startTime,
    required this.status,
    required this.checklistItems,
  });

  factory InterventionDetail.fromJson(Map<String, dynamic> json) {
    return InterventionDetail(
      id: json['id'] as String? ?? '',
      clientName: json['clientName'] as String? ?? 'Client',
      notes: json['notes'] as String?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'Scheduled',
      checklistItems: (json['checklistItems'] as List? ?? [])
          .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
