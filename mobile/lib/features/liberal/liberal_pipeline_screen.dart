import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'pipeline_api.dart';
import 'pipeline_cubit.dart';
import 'pipeline_model.dart';

const Color _kLiberal = Color(0xFF5E35B1);

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN LISTE — Pipeline des prospects
// ═══════════════════════════════════════════════════════════════════════════════

class LiberalPipelineScreen extends StatelessWidget {
  const LiberalPipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PipelineCubit()..load(),
      child: const _PipelineView(),
    );
  }
}

class _PipelineView extends StatelessWidget {
  const _PipelineView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pipeline'),
        centerTitle: false,
      ),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          backgroundColor: _kLiberal,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
          onPressed: () => _openCreateSheet(ctx),
        ),
      ),
      body: BlocBuilder<PipelineCubit, PipelineState>(
        builder: (context, state) {
          if (state is PipelineLoading || state is PipelineInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PipelineError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<PipelineCubit>().load(),
            );
          }
          if (state is PipelineLoaded) {
            if (state.items.isEmpty) {
              return const _EmptyView();
            }
            return RefreshIndicator(
              onRefresh: () => context.read<PipelineCubit>().refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ProspectCard(
                  prospect: state.items[i],
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
    final cubit = context.read<PipelineCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProspectDetailScreen(prospectId: id)),
    );
    cubit.refresh();
  }

  void _openCreateSheet(BuildContext context) {
    final cubit = context.read<PipelineCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateProspectSheet(cubit: cubit),
    );
  }
}

// ─── Carte prospect ────────────────────────────────────────────────────────────

class _ProspectCard extends StatelessWidget {
  final ProspectListItem prospect;
  final VoidCallback onTap;

  const _ProspectCard({required this.prospect, required this.onTap});

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
              _ProbabilityRing(probability: prospect.probability),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prospect.companyName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prospect.contactPerson,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_note_rounded,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${prospect.eventCount} événement(s)',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProbabilityRing extends StatelessWidget {
  final int probability;
  const _ProbabilityRing({required this.probability});

  @override
  Widget build(BuildContext context) {
    final pct = (probability.clamp(0, 100)) / 100;
    final color = probability >= 70
        ? const Color(0xFF2E7D32)
        : probability >= 40
            ? const Color(0xFFF57C00)
            : Colors.grey.shade500;
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '$probability%',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── États vides / erreur ──────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Aucun prospect',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Appuyez sur « Nouveau » pour commencer.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
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
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET — Création d'un prospect
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateProspectSheet extends StatefulWidget {
  final PipelineCubit cubit;
  const _CreateProspectSheet({required this.cubit});

  @override
  State<_CreateProspectSheet> createState() => _CreateProspectSheetState();
}

class _CreateProspectSheetState extends State<_CreateProspectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _company = TextEditingController();
  final _contact = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  double _probability = 20;
  bool _saving = false;

  @override
  void dispose() {
    _company.dispose();
    _contact.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.cubit.createProspect(
        companyName: _company.text.trim(),
        contactPerson: _contact.text.trim(),
        phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        probability: _probability.round(),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouveau prospect',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _company,
              decoration: const InputDecoration(
                labelText: 'Entreprise *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contact,
              decoration: const InputDecoration(
                labelText: 'Personne de contact *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Probabilité : ${_probability.round()}%',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Slider(
              value: _probability,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: _kLiberal,
              label: '${_probability.round()}%',
              onChanged: (v) => setState(() => _probability = v),
            ),
            const SizedBox(height: 8),
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
                    : const Text('Créer le prospect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN DÉTAIL — Prospect + événements + probabilité
// ═══════════════════════════════════════════════════════════════════════════════

class ProspectDetailScreen extends StatefulWidget {
  final String prospectId;
  const ProspectDetailScreen({super.key, required this.prospectId});

  @override
  State<ProspectDetailScreen> createState() => _ProspectDetailScreenState();
}

class _ProspectDetailScreenState extends State<ProspectDetailScreen> {
  final _api = PipelineApi();
  late Future<ProspectDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getById(widget.prospectId);
  }

  void _reload() {
    setState(() {
      _future = _api.getById(widget.prospectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail prospect')),
      body: FutureBuilder<ProspectDetail>(
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
              _DetailHeader(prospect: p),
              const SizedBox(height: 20),
              _ProbabilitySection(
                prospect: p,
                onUpdate: (newProba) async {
                  await _api.updateProbability(p.id, newProba);
                  _reload();
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Événements',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton.icon(
                    onPressed: () => _openAddEvent(p.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter'),
                    style: TextButton.styleFrom(foregroundColor: _kLiberal),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (p.events.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Aucun événement enregistré.',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ),
                )
              else
                ...p.events.map((e) => _EventTile(event: e)),
            ],
          );
        },
      ),
    );
  }

  void _openAddEvent(String prospectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddEventSheet(
        api: _api,
        prospectId: prospectId,
        onAdded: _reload,
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final ProspectDetail prospect;
  const _DetailHeader({required this.prospect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kLiberal, Color(0xFF4527A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prospect.companyName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            prospect.contactPerson,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (prospect.phoneNumber != null && prospect.phoneNumber!.isNotEmpty)
            _InfoRow(icon: Icons.phone_rounded, text: prospect.phoneNumber!),
          if (prospect.email != null && prospect.email!.isNotEmpty)
            _InfoRow(icon: Icons.email_rounded, text: prospect.email!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
        ],
      ),
    );
  }
}

class _ProbabilitySection extends StatelessWidget {
  final ProspectDetail prospect;
  final Future<void> Function(int) onUpdate;

  const _ProbabilitySection({required this.prospect, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Probabilité de conversion : ${prospect.probability}%',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Glissez puis validez pour mettre à jour.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          _ProbabilitySlider(
            initial: prospect.probability,
            onCommit: onUpdate,
          ),
        ],
      ),
    );
  }
}

class _ProbabilitySlider extends StatefulWidget {
  final int initial;
  final Future<void> Function(int) onCommit;

  const _ProbabilitySlider({required this.initial, required this.onCommit});

  @override
  State<_ProbabilitySlider> createState() => _ProbabilitySliderState();
}

class _ProbabilitySliderState extends State<_ProbabilitySlider> {
  late double _value = widget.initial.toDouble();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _value,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: _kLiberal,
            label: '${_value.round()}%',
            onChanged: _saving ? null : (v) => setState(() => _value = v),
          ),
        ),
        if (_saving)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (_value.round() != widget.initial)
          IconButton(
            icon: const Icon(Icons.check_circle, color: _kLiberal),
            onPressed: () async {
              setState(() => _saving = true);
              try {
                await widget.onCommit(_value.round());
              } catch (e) {
                if (mounted) {
                  setState(() => _saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            e.toString().replaceFirst('Exception: ', ''))),
                  );
                }
              }
            },
          ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  final PipelineEvent event;
  const _EventTile({required this.event});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kLiberal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_rounded, size: 18, color: _kLiberal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.eventType,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  _formatDate(event.eventDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (event.notes != null && event.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(event.notes!,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ─── Bottom sheet : ajout d'événement ──────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  final PipelineApi api;
  final String prospectId;
  final VoidCallback onAdded;

  const _AddEventSheet({
    required this.api,
    required this.prospectId,
    required this.onAdded,
  });

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  static const _types = ['Appel', 'Réunion', 'Email', 'Proposition', 'Autre'];
  String _type = 'Appel';
  DateTime _date = DateTime.now();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.api.addEvent(
        widget.prospectId,
        eventType: _type,
        eventDate: _date,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
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
          const Text('Nouvel événement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'Appel'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              child: Text(
                '${_date.day.toString().padLeft(2, '0')}/'
                '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
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
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}
