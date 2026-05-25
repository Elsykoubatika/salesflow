import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../clients/client_model.dart';
import 'client_picker.dart';
import 'contract_api.dart';
import 'contract_cubit.dart';
import 'contract_model.dart';

const Color _kLiberal = Color(0xFF4527A0);

class LiberalContractsScreen extends StatelessWidget {
  const LiberalContractsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ContractCubit()..load(),
      child: const _ContractsView(),
    );
  }
}

class _ContractsView extends StatelessWidget {
  const _ContractsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contrats')),
      floatingActionButton: Builder(
        builder: (ctx) => FloatingActionButton.extended(
          backgroundColor: _kLiberal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouveau', style: TextStyle(color: Colors.white)),
          onPressed: () => _openCreate(ctx),
        ),
      ),
      body: BlocBuilder<ContractCubit, ContractState>(
        builder: (context, state) {
          if (state is ContractLoading || state is ContractInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ContractError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<ContractCubit>().load(),
            );
          }
          if (state is ContractLoaded) {
            if (state.items.isEmpty) {
              return const _EmptyView(
                icon: Icons.handshake_rounded,
                title: 'Aucun contrat',
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<ContractCubit>().refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ContractCard(
                  contract: state.items[i],
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
    final cubit = context.read<ContractCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: id)),
    );
    cubit.refresh();
  }

  void _openCreate(BuildContext context) {
    final cubit = context.read<ContractCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateContractSheet(cubit: cubit),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractListItem contract;
  final VoidCallback onTap;
  const _ContractCard({required this.contract, required this.onTap});

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
                  color: _kLiberal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handshake_rounded, color: _kLiberal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contract.contractNumber,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      contract.engagementType.isEmpty
                          ? 'Type non défini'
                          : contract.engagementType,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text('${contract.invoiceCount} facture(s)',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
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

// ─── Détail ────────────────────────────────────────────────────────────────────

class ContractDetailScreen extends StatefulWidget {
  final String contractId;
  const ContractDetailScreen({super.key, required this.contractId});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  final _api = ContractApi();
  late Future<ContractDetail> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _api.getById(widget.contractId);
  }

  void _reload() {
    setState(() => _future = _api.getById(widget.contractId));
  }

  Future<void> _sign() async {
    setState(() => _busy = true);
    try {
      await _api.sign(widget.contractId);
      _reload();
    } catch (e) {
      _snack(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
      appBar: AppBar(title: const Text('Détail contrat')),
      body: FutureBuilder<ContractDetail>(
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
          final c = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kLiberal, Color(0xFF5E35B1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.contractNumber,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(c.engagementType,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile(
                label: 'Statut',
                value: c.isSigned ? 'Signé' : 'Non signé',
                valueColor:
                    c.isSigned ? const Color(0xFF2E7D32) : Colors.orange,
              ),
              if (c.signedDate != null)
                _InfoTile(
                  label: 'Date de signature',
                  value: _fmt(c.signedDate!),
                ),
              if (c.notes != null && c.notes!.isNotEmpty)
                _InfoTile(label: 'Notes', value: c.notes!),
              const SizedBox(height: 20),
              if (!c.isSigned)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _sign,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.draw_rounded),
                    label: const Text('Signer le contrat'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Sheet création ────────────────────────────────────────────────────────────

class _CreateContractSheet extends StatefulWidget {
  final ContractCubit cubit;
  const _CreateContractSheet({required this.cubit});

  @override
  State<_CreateContractSheet> createState() => _CreateContractSheetState();
}

class _CreateContractSheetState extends State<_CreateContractSheet> {
  static const _types = ['Project', 'Monthly', 'Yearly', 'Recurring'];
  Client? _client;
  String _type = 'Project';
  final _notes = TextEditingController();
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
      await widget.cubit.createContract(
        clientId: _client!.id,
        engagementType: _type,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nouveau contrat',
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
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Type d\'engagement',
              border: OutlineInputBorder(),
            ),
            items: _types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? 'Project'),
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
                  : const Text('Créer le contrat'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets partagés ──────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoTile({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
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
