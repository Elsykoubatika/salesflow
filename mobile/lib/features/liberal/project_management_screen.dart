import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../clients/client_model.dart';
import 'client_picker.dart';
import 'project_api.dart';
import 'project_cubit.dart';
import 'project_model.dart';

const Color _kLiberal = Color(0xFF6A1B9A);

class ProjectManagementScreen extends StatelessWidget {
  const ProjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProjectCubit()..load(),
      child: const _ProjectsView(),
    );
  }
}

class _ProjectsView extends StatelessWidget {
  const _ProjectsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projets')),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          backgroundColor: _kLiberal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
          onPressed: () => _openCreate(ctx),
        ),
      ),
      body: BlocBuilder<ProjectCubit, ProjectState>(
        builder: (context, state) {
          if (state is ProjectLoading || state is ProjectInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ProjectError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<ProjectCubit>().load(),
            );
          }
          if (state is ProjectLoaded) {
            if (state.items.isEmpty) {
              return const _EmptyView(
                  icon: Icons.folder_special_rounded, title: 'Aucun projet');
            }
            return RefreshIndicator(
              onRefresh: () => context.read<ProjectCubit>().refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ProjectCard(
                  project: state.items[i],
                  onTap: () => _openDetail(context, state.items[i].id),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    final cubit = context.read<ProjectCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(projectId: id)),
    );
    cubit.refresh();
  }

  void _openCreate(BuildContext context) {
    final cubit = context.read<ProjectCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateProjectSheet(cubit: cubit),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectListItem project;
  final VoidCallback onTap;
  const _ProjectCard({required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(project.projectName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  _StatusChip(status: project.status),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (project.progress / 100).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(_kLiberal),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${project.progress.round()}% complété',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  Text(
                    'Budget : ${_money(project.budgetAmount)}',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Détail ────────────────────────────────────────────────────────────────────

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _api = ProjectApi();
  late Future<ProjectDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getById(widget.projectId);
  }

  void _reload() {
    setState(() => _future = _api.getById(widget.projectId));
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail projet')),
      body: FutureBuilder<ProjectDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }
          final p = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kLiberal, Color(0xFF8E24AA)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.projectName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    if (p.description != null && p.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(p.description!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (p.progress / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${p.progress.round()}% complété',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _StatBox(
                          label: 'Budget', value: _money(p.budgetAmount))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatBox(
                          label: 'Facturé', value: _money(p.totalInvoiced))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatBox(
                          label: 'Payé', value: _money(p.totalPaid))),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Livrables',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () => _openAddDeliverable(p.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: TextButton.styleFrom(foregroundColor: _kLiberal),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (p.deliverables.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Aucun livrable.',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ...p.deliverables.map((d) => _DeliverableTile(
                      deliverable: d,
                      onComplete: d.isCompleted
                          ? null
                          : () async {
                              try {
                                await _api.completeDeliverable(p.id, d.id);
                                _reload();
                              } catch (e) {
                                _snack(e);
                              }
                            },
                    )),
              if (p.tasks.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Tâches',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ...p.tasks.map((t) => _TaskTile(task: t)),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openAddDeliverable(String projectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddDeliverableSheet(
        api: _api,
        projectId: projectId,
        onAdded: _reload,
      ),
    );
  }
}

// ─── Sheets ────────────────────────────────────────────────────────────────────

class _CreateProjectSheet extends StatefulWidget {
  final ProjectCubit cubit;
  const _CreateProjectSheet({required this.cubit});

  @override
  State<_CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<_CreateProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  Client? _client;
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _type = TextEditingController();
  final _budget = TextEditingController();
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;
  String? _clientError;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _type.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_client == null) {
      setState(() => _clientError = 'Sélectionnez un client');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.cubit.createProject(
        clientId: _client!.id,
        projectName: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        projectType: _type.text.trim().isEmpty ? null : _type.text.trim(),
        startDate: _start,
        endDate: _end,
        budgetAmount: double.tryParse(_budget.text.trim()) ?? 0,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding:
          EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomInset + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouveau projet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ClientPickerField(
                selected: _client,
                onSelected: (c) => setState(() {
                  _client = c;
                  _clientError = null;
                }),
              ),
              if (_clientError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(_clientError!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nom du projet *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _type,
                decoration: const InputDecoration(
                  labelText: 'Type (Consulting, Formation…)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budget,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget (XAF)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Début',
                      date: _start,
                      onPick: (d) => setState(() => _start = d),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateField(
                      label: 'Fin',
                      date: _end,
                      onPick: (d) => setState(() => _end = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kLiberal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Créer le projet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDeliverableSheet extends StatefulWidget {
  final ProjectApi api;
  final String projectId;
  final VoidCallback onAdded;

  const _AddDeliverableSheet({
    required this.api,
    required this.projectId,
    required this.onAdded,
  });

  @override
  State<_AddDeliverableSheet> createState() => _AddDeliverableSheetState();
}

class _AddDeliverableSheetState extends State<_AddDeliverableSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  DateTime _due = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.api.addDeliverable(
        widget.projectId,
        title: _title.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        dueDate: _due,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding:
          EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nouveau livrable',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Titre *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _DateField(
            label: 'Échéance',
            date: _due,
            onPick: (d) => setState(() => _due = d),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _kLiberal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Ajouter'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets partagés ──────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Completed' => const Color(0xFF2E7D32),
      'InProgress' => const Color(0xFF1565C0),
      'Archived' => Colors.grey,
      _ => const Color(0xFFF57C00),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _DeliverableTile extends StatelessWidget {
  final Deliverable deliverable;
  final VoidCallback? onComplete;
  const _DeliverableTile({required this.deliverable, this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            deliverable.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: deliverable.isCompleted ? const Color(0xFF2E7D32) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deliverable.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: deliverable.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: deliverable.isCompleted
                          ? Colors.grey
                          : Colors.black87,
                    )),
                if (deliverable.dueDate != null)
                  Text('Échéance : ${_fmt(deliverable.dueDate!)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          if (onComplete != null)
            TextButton(
              onPressed: onComplete,
              child: const Text('Terminer'),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _TaskTile extends StatelessWidget {
  final ProjectTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.task_alt_rounded, size: 18, color: _kLiberal),
          const SizedBox(width: 10),
          Expanded(child: Text(task.title)),
          Text(task.status,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  const _DateField(
      {required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}',
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  const _EmptyView({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Appuyez sur « Nouveau » pour commencer.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: Colors.redAccent),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: _kLiberal),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

String _money(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf XAF';
}
