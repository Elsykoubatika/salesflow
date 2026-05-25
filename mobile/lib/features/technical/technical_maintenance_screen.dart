import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'maintenance_api.dart';
import 'maintenance_cubit.dart';
import 'maintenance_model.dart';
import 'tech_shared.dart';

const Color _kTech = Color(0xFF2E7D32);

class TechnicalMaintenanceScreen extends StatelessWidget {
  const TechnicalMaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MaintenanceCubit()..load(),
      child: const _MaintenanceView(),
    );
  }
}

class _MaintenanceView extends StatelessWidget {
  const _MaintenanceView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          backgroundColor: _kTech,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
          onPressed: () => _openCreate(ctx),
        ),
      ),
      body: BlocBuilder<MaintenanceCubit, MaintenanceState>(
        builder: (context, state) {
          if (state is MaintenanceLoading || state is MaintenanceInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MaintenanceError) {
            return TechErrorView(
              message: state.message,
              color: _kTech,
              onRetry: () => context.read<MaintenanceCubit>().load(),
            );
          }
          if (state is MaintenanceLoaded) {
            if (state.items.isEmpty) {
              return const TechEmptyView(
                  icon: Icons.checklist_rounded, title: 'Aucun plan');
            }
            return RefreshIndicator(
              onRefresh: () => context.read<MaintenanceCubit>().refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PlanCard(
                  plan: state.items[i],
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
    final cubit = context.read<MaintenanceCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MaintenanceDetailScreen(planId: id)),
    );
    cubit.refresh();
  }

  void _openCreate(BuildContext context) {
    final cubit = context.read<MaintenanceCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreatePlanSheet(cubit: cubit),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final MaintenanceListItem plan;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.onTap});

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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kTech.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.checklist_rounded, color: _kTech),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.planName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.frequency.isEmpty ? "—" : plan.frequency} · '
                      '${plan.taskCount} tâche(s)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              TechStatusChip(status: plan.status),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Détail ────────────────────────────────────────────────────────────────────

class MaintenanceDetailScreen extends StatefulWidget {
  final String planId;
  const MaintenanceDetailScreen({super.key, required this.planId});

  @override
  State<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  final _api = MaintenanceApi();
  late Future<MaintenanceDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getById(widget.planId);
  }

  void _reload() {
    setState(() => _future = _api.getById(widget.planId));
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(techError(e))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du plan')),
      body: FutureBuilder<MaintenanceDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return TechErrorView(
              message: techError(snapshot.error!),
              color: _kTech,
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
                      colors: [_kTech, Color(0xFF1B5E20)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.planName,
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
                    const SizedBox(height: 8),
                    Text('Fréquence : ${p.frequency.isEmpty ? "—" : p.frequency}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tâches',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () => _openAddTask(p.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: TextButton.styleFrom(foregroundColor: _kTech),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (p.tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Aucune tâche.',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ...p.tasks.map((t) => _TaskTile(
                      task: t,
                      onComplete: t.isCompleted
                          ? null
                          : () async {
                              try {
                                await _api.completeTask(p.id, t.id);
                                _reload();
                              } catch (e) {
                                _snack(e);
                              }
                            },
                    )),
            ],
          );
        },
      ),
    );
  }

  void _openAddTask(String planId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddTaskSheet(
        api: _api,
        planId: planId,
        onAdded: _reload,
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final MaintenanceTask task;
  final VoidCallback? onComplete;
  const _TaskTile({required this.task, this.onComplete});

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
            task.isCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: task.isCompleted ? const Color(0xFF2E7D32) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color:
                          task.isCompleted ? Colors.grey : Colors.black87,
                    )),
                if (task.dueDate != null)
                  Text('Échéance : ${techDate(task.dueDate!)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          if (onComplete != null)
            TextButton(
                onPressed: onComplete, child: const Text('Terminer')),
        ],
      ),
    );
  }
}

// ─── Sheets ────────────────────────────────────────────────────────────────────

class _CreatePlanSheet extends StatefulWidget {
  final MaintenanceCubit cubit;
  const _CreatePlanSheet({required this.cubit});

  @override
  State<_CreatePlanSheet> createState() => _CreatePlanSheetState();
}

class _CreatePlanSheetState extends State<_CreatePlanSheet> {
  static const _freqs = ['Daily', 'Weekly', 'Monthly', 'Quarterly', 'Yearly'];
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _freq = 'Monthly';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.cubit.createPlan(
        planName: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        frequency: _freq,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(techError(e))));
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
          const Text('Nouveau plan de maintenance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nom du plan *',
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
          DropdownButtonFormField<String>(
            initialValue: _freq,
            decoration: const InputDecoration(
              labelText: 'Fréquence',
              border: OutlineInputBorder(),
            ),
            items: _freqs
                .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                .toList(),
            onChanged: (v) => setState(() => _freq = v ?? 'Monthly'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _kTech,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Créer le plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final MaintenanceApi api;
  final String planId;
  final VoidCallback onAdded;

  const _AddTaskSheet({
    required this.api,
    required this.planId,
    required this.onAdded,
  });

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _hours = TextEditingController(text: '1');
  DateTime _due = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.api.addTask(
        widget.planId,
        title: _title.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        dueDate: _due,
        estimatedHours: double.tryParse(_hours.text.trim()) ?? 0,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(techError(e))));
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
          const Text('Nouvelle tâche',
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
          TextField(
            controller: _hours,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Heures estimées',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TechDateField(
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
                backgroundColor: _kTech,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Ajouter la tâche'),
            ),
          ),
        ],
      ),
    );
  }
}
