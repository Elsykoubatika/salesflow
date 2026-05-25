import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../clients/client_model.dart';
import '../liberal/client_picker.dart';
import 'quote_api.dart';
import 'quote_cubit.dart';
import 'quote_model.dart';
import 'tech_shared.dart';

const Color _kTech = Color(0xFF00838F);

class TechnicalQuoteFormScreen extends StatelessWidget {
  const TechnicalQuoteFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuoteCubit()..load(),
      child: const _QuotesView(),
    );
  }
}

class _QuotesView extends StatelessWidget {
  const _QuotesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devis Tech')),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          backgroundColor: _kTech,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
          onPressed: () => _openCreate(ctx),
        ),
      ),
      body: BlocBuilder<QuoteCubit, QuoteState>(
        builder: (context, state) {
          if (state is QuoteLoading || state is QuoteInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is QuoteError) {
            return TechErrorView(
              message: state.message,
              color: _kTech,
              onRetry: () => context.read<QuoteCubit>().load(),
            );
          }
          if (state is QuoteLoaded) {
            if (state.items.isEmpty) {
              return const TechEmptyView(
                  icon: Icons.calculate_rounded, title: 'Aucun devis');
            }
            return RefreshIndicator(
              onRefresh: () => context.read<QuoteCubit>().refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _QuoteCard(
                  quote: state.items[i],
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
    final cubit = context.read<QuoteCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuoteDetailScreen(quoteId: id)),
    );
    cubit.refresh();
  }

  void _openCreate(BuildContext context) {
    final cubit = context.read<QuoteCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateQuoteSheet(cubit: cubit),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final QuoteListItem quote;
  final VoidCallback onTap;
  const _QuoteCard({required this.quote, required this.onTap});

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
                    child: Text(quote.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  TechStatusChip(status: quote.status),
                ],
              ),
              const SizedBox(height: 4),
              Text('${quote.quoteNumber} · ${quote.clientName}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${quote.itemCount} ligne(s)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                  Text(techMoney(quote.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: _kTech)),
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

class QuoteDetailScreen extends StatefulWidget {
  final String quoteId;
  const QuoteDetailScreen({super.key, required this.quoteId});

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen> {
  final _api = QuoteApi();
  late Future<QuoteDetail> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getById(widget.quoteId);
  }

  void _reload() {
    setState(() => _future = _api.getById(widget.quoteId));
  }

  void _snack(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(techError(e))));
  }

  Future<void> _action(Future<void> Function() fn) async {
    setState(() => _busy = true);
    try {
      await fn();
      _reload();
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail devis')),
      body: FutureBuilder<QuoteDetail>(
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
          final q = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kTech, Color(0xFF006064)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${q.quoteNumber} · ${q.clientName}',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13)),
                    const SizedBox(height: 10),
                    Text(techMoney(q.total),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TechInfoTile(label: 'Statut', value: q.status),
              if (q.serviceLocation != null && q.serviceLocation!.isNotEmpty)
                TechInfoTile(label: 'Lieu', value: q.serviceLocation!),
              TechInfoTile(
                  label: 'Heures estimées',
                  value: '${q.estimatedHours.toStringAsFixed(1)} h'),
              TechInfoTile(
                  label: 'Taux horaire',
                  value: techMoney(q.hourlyRate)),
              TechInfoTile(
                  label: 'Main d\'œuvre', value: techMoney(q.laborCost)),
              TechInfoTile(
                  label: 'Matériaux', value: techMoney(q.materialsCost)),
              TechInfoTile(
                  label: 'Lignes d\'articles',
                  value: '${q.itemCount}'),
              if (q.description != null && q.description!.isNotEmpty)
                TechInfoTile(label: 'Description', value: q.description!),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _openAddItem(q.id),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une ligne'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kTech,
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
              const SizedBox(height: 8),
              if (q.status == 'Draft')
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _action(() => _api.send(q.id)),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Envoyer le devis'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              if (q.status == 'Sent')
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _action(() => _api.accept(q.id)),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Marquer comme accepté'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              if (q.status == 'Draft') ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          await _action(() => _api.delete(q.id));
                          if (mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Supprimer',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openAddItem(String quoteId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddItemSheet(
        api: _api,
        quoteId: quoteId,
        onAdded: _reload,
      ),
    );
  }
}

// ─── Sheets ────────────────────────────────────────────────────────────────────

class _CreateQuoteSheet extends StatefulWidget {
  final QuoteCubit cubit;
  const _CreateQuoteSheet({required this.cubit});

  @override
  State<_CreateQuoteSheet> createState() => _CreateQuoteSheetState();
}

class _CreateQuoteSheetState extends State<_CreateQuoteSheet> {
  final _formKey = GlobalKey<FormState>();
  Client? _client;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _hours = TextEditingController();
  final _rate = TextEditingController();
  bool _saving = false;
  String? _clientError;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _location.dispose();
    _hours.dispose();
    _rate.dispose();
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
      await widget.cubit.createQuote(
        clientId: _client!.id,
        title: _title.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        serviceLocation:
            _location.text.trim().isEmpty ? null : _location.text.trim(),
        estimatedHours: double.tryParse(_hours.text.trim()) ?? 0,
        hourlyRate: double.tryParse(_rate.text.trim()) ?? 0,
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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nouveau devis',
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
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Titre du devis *',
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
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Lieu du service',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hours,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Heures *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _rate,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Taux/h *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
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
                      : const Text('Créer le devis'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final QuoteApi api;
  final String quoteId;
  final VoidCallback onAdded;

  const _AddItemSheet({
    required this.api,
    required this.quoteId,
    required this.onAdded,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  static const _itemTypes = ['Material', 'Labor', 'Equipment', 'Other'];
  final _name = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _unit = TextEditingController(text: 'pcs');
  final _price = TextEditingController();
  String _type = 'Material';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _unit.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.api.addItem(
        widget.quoteId,
        itemName: _name.text.trim(),
        itemType: _type,
        quantity: double.tryParse(_qty.text.trim()) ?? 1,
        unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
        unitPrice: double.tryParse(_price.text.trim()) ?? 0,
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
          const Text('Ajouter une ligne',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Désignation *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: _itemTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'Material'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Unité',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Prix unitaire (XAF)',
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
                  : const Text('Ajouter la ligne'),
            ),
          ),
        ],
      ),
    );
  }
}
