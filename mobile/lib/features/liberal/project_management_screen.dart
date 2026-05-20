import 'package:flutter/material.dart';
import '../../theme.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  final _projects = [
    {
      'name': 'Audit Énergétique',
      'client': 'ECAB Sarl',
      'status': 'InProgress',
      'progress': 0.65,
      'budget': 1500000,
      'spent': 975000
    },
    {
      'name': 'Formation RH',
      'client': 'Impact Group',
      'status': 'Planning',
      'progress': 0.20,
      'budget': 2000000,
      'spent': 400000
    },
    {
      'name': 'Conseil Commercial',
      'client': 'TradeHub Congo',
      'status': 'Completed',
      'progress': 1.0,
      'budget': 800000,
      'spent': 800000
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Gestion de Projets'), centerTitle: false),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (ctx, i) {
          final p = _projects[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'].toString(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(p['client'].toString(),
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _getStatusColor(p['status'].toString()),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(p['status'].toString(),
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (p['progress'] as double),
                      minHeight: 6,
                      backgroundColor:
                          AppTheme.forestGreen.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(AppTheme.forestGreen),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      '${((p['progress'] as double) * 100).toStringAsFixed(0)}% complété',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Budget: ${(p['budget']).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF',
                          style: const TextStyle(fontSize: 12)),
                      Text(
                          'Dépensé: ${(p['spent']).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} XAF',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.forestGreen,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                          icon: const Icon(Icons.checklist, size: 16),
                          label: const Text('Tâches'),
                          onPressed: () {}),
                      OutlinedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 16),
                          label: const Text('Exporter PDF'),
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(
                                  const SnackBar(content: Text('PDF généré')))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Nouveau projet'))),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) => switch (status) {
        'Planning' => Colors.orange.shade700,
        'InProgress' => AppTheme.forestGreen,
        'Completed' => Colors.green.shade700,
        _ => Colors.grey,
      };
}
