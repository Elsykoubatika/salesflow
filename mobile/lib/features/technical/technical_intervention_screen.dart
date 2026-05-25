import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../clients/client_model.dart';
import '../liberal/client_picker.dart';
import 'intervention_api.dart';
import 'intervention_cubit.dart';
import 'intervention_model.dart';
import 'tech_shared.dart';

const Color _kTech = Color(0xFF00695C);

class TechnicalInterventionsScreen extends StatelessWidget {
  const TechnicalInterventionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InterventionCubit()..load(),
      child: const _InterventionsView(),
    );
  }
}

class _InterventionsView extends StatelessWidget {
  const _InterventionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interventions')),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          backgroundColor: _kTech,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
          onPressed: () => _openCreate(ctx),
        ),
      ),
      body: BlocBuilder<InterventionCubit, InterventionState>(
        builder: (context, state) {
          if (state is InterventionLoading || state is InterventionInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InterventionError) {
            return TechErrorView(
              message: state.message,
              color: _kTech,
              onRetry: () => context.read<InterventionCubit>().load(),
            );
          }
          if (state is InterventionLoaded) {
            if (state.items.isEmpty) {
              return const TechEmptyView(
                  icon: Icons.build_rounded, title: 'Aucune intervention');
            }
            return RefreshIndicator(
              onRefresh: () => context.read<InterventionCubit>().refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _InterventionCard(
                  intervention: state.items[i],
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
    final cubit = context.read<InterventionCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => InterventionDetailScreen(interventionId: id)),
    );
    cubit.refresh();
  }

  void _openCreate(BuildContext context) {
    final cubit = context.read<InterventionCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateInterventionSheet(cubit: cubit),
    );
  }
}

class _InterventionCard extends StatelessWidget {
  final InterventionItem intervention;
  final VoidCallback onTap;
  const _InterventionCard({required this.intervention, required this.onTap});

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
                child: const Icon(Icons.build_rounded, color: _kTech),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(intervention.clientName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(techDate(intervention.startTime),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    if (intervention.notes != null &&
                        intervention.notes!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(intervention.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ],
                ),
              ),
              TechStatusChip(status: intervention.status),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Détail ────────────────────────────────────────────────────────────────────

class InterventionDetailScreen extends StatefulWidget {
  final String interventionId;
  const InterventionDetailScreen({super.key, required this.interventionId});

  @override
  State<InterventionDetailScreen> createState() =>
      _InterventionDetailScreenState();
}

class _InterventionDetailScreenState extends State<InterventionDetailScreen> {
  final _api = InterventionApi();
  late Future<InterventionDetail> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getById(widget.interventionId);
  }

  void _reload() {
    setState(() => _future = _api.getById(widget.interventionId));
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(techError(e))));
  }

  Future<void> _complete() async {
    setState(() => _busy = true);
    try {
      await _api.complete(widget.interventionId);
      _reload();
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleItem(ChecklistItem item) async {
    try {
      await _api.toggleChecklistItem(
        widget.interventionId,
        item.id,
        isCompleted: !item.isCompleted,
      );
      _reload();
    } catch (e) {
      _snack(e);
    }
  }

  Future<void> _addChecklist() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Point de contrôle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Intitulé du point'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      try {
        await _api.addChecklistItem(widget.interventionId, title);
        _reload();
      } catch (e) {
        _snack(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail intervention')),
      body: FutureBuilder<InterventionDetail>(
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
          final it = snapshot.data!;
          final done = it.checklistItems.where((c) => c.isCompleted).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kTech, Color(0xFF004D40)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(it.clientName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Début : ${techDate(it.startTime)}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TechInfoTile(label: 'Statut', value: it.status),
              if (it.notes != null && it.notes!.isNotEmpty)
                TechInfoTile(label: 'Notes', value: it.notes!),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Checklist  ($done/${it.checklistItems.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _addChecklist,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: TextButton.styleFrom(foregroundColor: _kTech),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (it.checklistItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Aucun point de contrôle.',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ...it.checklistItems.map((c) => _ChecklistTile(
                      item: c,
                      onToggle: () => _toggleItem(c),
                    )),
              const SizedBox(height: 16),
              if (it.status != 'Completed')
                FilledButton.icon(
                  onPressed: _busy ? null : _complete,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: const Text('Terminer l\'intervention'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onToggle;
  const _ChecklistTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: item.isCompleted,
                activeColor: const Color(0xFF2E7D32),
                onChanged: (_) => onToggle(),
              ),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: item.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color:
                        item.isCompleted ? Colors.grey : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Sheet création ────────────────────────────────────────────────────────────

class _CreateInterventionSheet extends StatefulWidget {
  final InterventionCubit cubit;
  const _CreateInterventionSheet({required this.cubit});

  @override
  State<_CreateInterventionSheet> createState() =>
      _CreateInterventionSheetState();
}

class _CreateInterventionSheetState extends State<_CreateInterventionSheet> {
  Client? _client;
  final _notes = TextEditingController();
  DateTime _start = DateTime.now();
  bool _saving = false;
  String? _clientError;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_client == null) {
      setState(() => _clientError = 'Sélectionnez un client');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.cubit.createIntervention(
        clientId: _client!.id,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        startTime: _start,
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
          const Text('Nouvelle intervention',
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
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          TechDateField(
            label: 'Date de début',
            date: _start,
            onPick: (d) => setState(() => _start = d),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes / description du travail',
              border: OutlineInputBorder(),
            ),
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
                  : const Text('Créer l\'intervention'),
            ),
          ),
        ],
      ),
    );
  }
}
