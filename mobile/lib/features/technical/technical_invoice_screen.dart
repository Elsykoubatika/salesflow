import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../clients/client_model.dart';
import '../liberal/client_picker.dart';
import 'invoice_api.dart';
import 'invoice_cubit.dart';
import 'invoice_model.dart';
import 'tech_shared.dart';

const Color _kTech = Color(0xFF0D6B4F);

class TechnicalInvoiceScreen extends StatelessWidget {
  const TechnicalInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InvoiceCubit()..load(),
      child: const _InvoicesView(),
    );
  }
}

class _InvoicesView extends StatelessWidget {
  const _InvoicesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Factures Tech')),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          backgroundColor: _kTech,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
          onPressed: () => _openCreate(ctx),
        ),
      ),
      body: BlocBuilder<InvoiceCubit, InvoiceState>(
        builder: (context, state) {
          if (state is InvoiceLoading || state is InvoiceInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is InvoiceError) {
            return TechErrorView(
              message: state.message,
              color: _kTech,
              onRetry: () => context.read<InvoiceCubit>().load(),
            );
          }
          if (state is InvoiceLoaded) {
            if (state.items.isEmpty) {
              return const TechEmptyView(
                  icon: Icons.description_rounded, title: 'Aucune facture');
            }
            return RefreshIndicator(
              onRefresh: () => context.read<InvoiceCubit>().refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _InvoiceCard(
                  invoice: state.items[i],
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
    final cubit = context.read<InvoiceCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: id)),
    );
    cubit.refresh();
  }

  void _openCreate(BuildContext context) {
    final cubit = context.read<InvoiceCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateInvoiceSheet(cubit: cubit),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceItem invoice;
  final VoidCallback onTap;
  const _InvoiceCard({required this.invoice, required this.onTap});

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
                    child: Text(invoice.invoiceNumber,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                  TechStatusChip(status: invoice.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(invoice.clientName,
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total : ${techMoney(invoice.total)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  Text(
                    'Reste : ${techMoney(invoice.amountDue)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: invoice.amountDue > 0
                          ? const Color(0xFFF57C00)
                          : const Color(0xFF2E7D32),
                    ),
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

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _api = InvoiceApi();
  late Future<InvoiceDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getById(widget.invoiceId);
  }

  void _reload() {
    setState(() => _future = _api.getById(widget.invoiceId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail facture')),
      body: FutureBuilder<InvoiceDetail>(
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
          final inv = snapshot.data!;
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
                    Text(inv.invoiceNumber,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    Text(inv.clientName,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13)),
                    const SizedBox(height: 10),
                    Text('Reste à payer : ${techMoney(inv.amountDue)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TechInfoTile(label: 'Statut', value: inv.status),
              if (inv.serviceDescription != null &&
                  inv.serviceDescription!.isNotEmpty)
                TechInfoTile(
                    label: 'Service', value: inv.serviceDescription!),
              TechInfoTile(
                  label: 'Heures', value: inv.actualHours.toStringAsFixed(1)),
              TechInfoTile(
                  label: 'Main d\'œuvre', value: techMoney(inv.laborCost)),
              TechInfoTile(
                  label: 'Matériaux', value: techMoney(inv.materialsCost)),
              TechInfoTile(label: 'Total', value: techMoney(inv.total)),
              TechInfoTile(
                  label: 'Acompte', value: techMoney(inv.advancePayment)),
              TechInfoTile(
                  label: 'Échéance', value: techDate(inv.dueDate)),
              if (inv.paidDate != null)
                TechInfoTile(
                    label: 'Payée le', value: techDate(inv.paidDate!)),
              const SizedBox(height: 16),
              if (inv.status != 'Paid' && inv.amountDue > 0)
                FilledButton.icon(
                  onPressed: () => _openPayment(inv),
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Enregistrer un paiement'),
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

  void _openPayment(InvoiceDetail inv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentSheet(
        api: _api,
        invoiceId: inv.invoiceId,
        amountDue: inv.amountDue,
        onPaid: _reload,
      ),
    );
  }
}

extension on InvoiceDetail {
  String get invoiceId => id;
}

// ─── Sheets ────────────────────────────────────────────────────────────────────

class _CreateInvoiceSheet extends StatefulWidget {
  final InvoiceCubit cubit;
  const _CreateInvoiceSheet({required this.cubit});

  @override
  State<_CreateInvoiceSheet> createState() => _CreateInvoiceSheetState();
}

class _CreateInvoiceSheetState extends State<_CreateInvoiceSheet> {
  final _formKey = GlobalKey<FormState>();
  Client? _client;
  final _desc = TextEditingController();
  final _hours = TextEditingController();
  final _rate = TextEditingController(text: '50000');
  final _materials = TextEditingController(text: '0');
  final _advance = TextEditingController(text: '0');
  bool _saving = false;
  String? _clientError;

  @override
  void dispose() {
    _desc.dispose();
    _hours.dispose();
    _rate.dispose();
    _materials.dispose();
    _advance.dispose();
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
      await widget.cubit.createInvoice(
        clientId: _client!.id,
        description: _desc.text.trim(),
        actualHours: double.tryParse(_hours.text.trim()) ?? 0,
        hourlyRate: double.tryParse(_rate.text.trim()) ?? 50000,
        materialsCost: double.tryParse(_materials.text.trim()) ?? 0,
        advancePayment: double.tryParse(_advance.text.trim()) ?? 0,
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
              const Text('Nouvelle facture',
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
                controller: _desc,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description du service *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
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
                        labelText: 'Taux/h',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _materials,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Matériaux',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _advance,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Acompte',
                        border: OutlineInputBorder(),
                      ),
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
                      : const Text('Créer la facture'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final InvoiceApi api;
  final String invoiceId;
  final double amountDue;
  final VoidCallback onPaid;

  const _PaymentSheet({
    required this.api,
    required this.invoiceId,
    required this.amountDue,
    required this.onPaid,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  static const _methods = ['Cash', 'MobileMoney', 'Bank', 'Card'];
  late final TextEditingController _amount =
      TextEditingController(text: widget.amountDue.toStringAsFixed(0));
  final _reference = TextEditingController();
  String _method = 'Cash';
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.recordPayment(
        widget.invoiceId,
        amount: amount,
        paymentMethod: _method,
        reference:
            _reference.text.trim().isEmpty ? null : _reference.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onPaid();
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
          const Text('Enregistrer un paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Reste dû : ${techMoney(widget.amountDue)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant (XAF) *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(
              labelText: 'Mode de paiement',
              border: OutlineInputBorder(),
            ),
            items: _methods
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _method = v ?? 'Cash'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reference,
            decoration: const InputDecoration(
              labelText: 'Référence (Mobile Money…)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Valider le paiement'),
            ),
          ),
        ],
      ),
    );
  }
}
