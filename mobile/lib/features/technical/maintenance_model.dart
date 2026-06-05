/// Modèles Maintenance — alignés sur TechnicalMaintenanceController (style _db).
library;

class MaintenanceListItem {
  final String id;
  final String planName;
  final String frequency;
  final String status;
  final int taskCount;

  MaintenanceListItem({
    required this.id,
    required this.planName,
    required this.frequency,
    required this.status,
    required this.taskCount,
  });

  factory MaintenanceListItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceListItem(
      id: json['id'] as String? ?? '',
      planName: json['planName'] as String? ?? 'Plan',
      frequency: json['frequency'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      taskCount: (json['taskCount'] as num? ?? 0).toInt(),
    );
  }
}

class MaintenanceListResponse {
  final List<MaintenanceListItem> items;
  final int total;

  MaintenanceListResponse({required this.items, required this.total});

  factory MaintenanceListResponse.fromJson(Map<String, dynamic> json) {
    return MaintenanceListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => MaintenanceListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}

class MaintenanceTask {
  final String id;
  final String title;
  final String status;
  final DateTime? dueDate;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.status,
    this.dueDate,
  });

  bool get isCompleted => status == 'Completed';

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
    );
  }
}

class MaintenanceDetail {
  final String id;
  final String planName;
  final String? description;
  final String frequency;
  final String status;
  final List<MaintenanceTask> tasks;

  MaintenanceDetail({
    required this.id,
    required this.planName,
    this.description,
    required this.frequency,
    required this.status,
    required this.tasks,
  });

  factory MaintenanceDetail.fromJson(Map<String, dynamic> json) {
    return MaintenanceDetail(
      id: json['id'] as String? ?? '',
      planName: json['planName'] as String? ?? 'Plan',
      description: json['description'] as String?,
      frequency: json['frequency'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      tasks: (json['tasks'] as List? ?? [])
          .map((e) => MaintenanceTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
