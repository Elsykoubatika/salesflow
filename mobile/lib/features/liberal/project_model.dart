/// Modèles du module Projets (Libéral).
/// Alignés sur LiberalProjectsController (style _db).

class ProjectListItem {
  final String id;
  final String projectName;
  final String status;
  final double budgetAmount;
  final double totalInvoiced;
  final double progress; // 0–100

  ProjectListItem({
    required this.id,
    required this.projectName,
    required this.status,
    required this.budgetAmount,
    required this.totalInvoiced,
    required this.progress,
  });

  factory ProjectListItem.fromJson(Map<String, dynamic> json) {
    return ProjectListItem(
      id: json['id'] as String? ?? '',
      projectName: json['projectName'] as String? ?? 'Sans nom',
      status: json['status'] as String? ?? 'Planning',
      budgetAmount: (json['budgetAmount'] as num? ?? 0).toDouble(),
      totalInvoiced: (json['totalInvoiced'] as num? ?? 0).toDouble(),
      progress: (json['progress'] as num? ?? 0).toDouble(),
    );
  }
}

class ProjectListResponse {
  final List<ProjectListItem> items;
  final int total;

  ProjectListResponse({required this.items, required this.total});

  factory ProjectListResponse.fromJson(Map<String, dynamic> json) {
    return ProjectListResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => ProjectListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
    );
  }
}

class Deliverable {
  final String id;
  final String title;
  final DateTime? dueDate;
  final bool isCompleted;

  Deliverable({
    required this.id,
    required this.title,
    this.dueDate,
    required this.isCompleted,
  });

  factory Deliverable.fromJson(Map<String, dynamic> json) {
    return Deliverable(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class ProjectTask {
  final String id;
  final String title;
  final String status;
  final String priority;

  ProjectTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Medium',
    );
  }
}

class ProjectDetail {
  final String id;
  final String projectName;
  final String? description;
  final String status;
  final double budgetAmount;
  final double totalInvoiced;
  final double totalPaid;
  final double progress;
  final List<Deliverable> deliverables;
  final List<ProjectTask> tasks;

  ProjectDetail({
    required this.id,
    required this.projectName,
    this.description,
    required this.status,
    required this.budgetAmount,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.progress,
    required this.deliverables,
    required this.tasks,
  });

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    return ProjectDetail(
      id: json['id'] as String? ?? '',
      projectName: json['projectName'] as String? ?? 'Sans nom',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'Planning',
      budgetAmount: (json['budgetAmount'] as num? ?? 0).toDouble(),
      totalInvoiced: (json['totalInvoiced'] as num? ?? 0).toDouble(),
      totalPaid: (json['totalPaid'] as num? ?? 0).toDouble(),
      progress: (json['progress'] as num? ?? 0).toDouble(),
      deliverables: (json['deliverables'] as List? ?? [])
          .map((e) => Deliverable.fromJson(e as Map<String, dynamic>))
          .toList(),
      tasks: (json['tasks'] as List? ?? [])
          .map((e) => ProjectTask.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
