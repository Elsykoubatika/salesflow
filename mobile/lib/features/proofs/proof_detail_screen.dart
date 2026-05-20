import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../catalog/format_money.dart';
import 'proof_model.dart';
import 'proof_status_visual.dart';
import 'proofs_api.dart';

class ProofDetailScreen extends StatefulWidget {
  final String proofId;
  const ProofDetailScreen({super.key, required this.proofId});

  @override
  State<ProofDetailScreen> createState() => _ProofDetailScreenState();
}

class _ProofDetailScreenState extends State<ProofDetailScreen> {
  final _api = ProofsApi();

  Proof? _proof;
  Uint8List? _imageBytes;
  String? _error;
  bool _busy = false;
  bool _changed = false; // pour signaler à la liste qu'il faut rafraîchir

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final proof = await _api.getById(widget.proofId);
      if (!mounted) return;
      setState(() => _proof = proof);

      // Charger l'image en parallèle (peut prendre du temps)
      final bytes = await _api.getImage(widget.proofId);
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_proof?.transactionReference ?? 'Preuve'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          actions: [
            if (_proof != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _busy ? null : _confirmDelete,
              ),
          ],
        ),
        body: _build(),
      ),
    );
  }

  Widget _build() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() => _error = null);
                  _load();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }
    if (_proof == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _DetailBody(
      proof: _proof!,
      imageBytes: _imageBytes,
      busy: _busy,
      onUpdateStatus: _updateStatus,
    );
  }

  Future<void> _updateStatus(ProofStatus newStatus) async {
    final p = _proof!;
    setState(() => _busy = true);
    try {
      final updated = await _api.update(
        p.id,
        amount: p.amount,
        currency: p.currency,
        transactionReference: p.transactionReference,
        operator: p.operator,
        transactionDate: p.transactionDate,
        notes: p.notes,
        clientId: p.clientId,
        salesOrderId: p.salesOrderId,
        status: newStatus,
        errorMessage: newStatus == ProofStatus.error ? 'Marquée en erreur manuellement' : null,
      );
      if (!mounted) return;
      setState(() {
        _proof = updated;
        _busy = false;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut : ${newStatus.label}'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la preuve ?'),
        content: const Text('Cette action est irréversible. L\'image sera définitivement effacée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _api.delete(widget.proofId);
      if (!mounted) return;
      Navigator.pop(context, true); // signaler à la liste de rafraîchir
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _DetailBody extends StatelessWidget {
  final Proof proof;
  final Uint8List? imageBytes;
  final bool busy;
  final ValueChanged<ProofStatus> onUpdateStatus;

  const _DetailBody({
    required this.proof,
    required this.imageBytes,
    required this.busy,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy à HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Image ──────────────────────────────────────────────────
        GestureDetector(
          onTap: imageBytes != null ? () => _openFullscreen(context) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 280,
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest,
              child: imageBytes == null
                  ? const Center(child: CircularProgressIndicator())
                  : Image.memory(imageBytes!, fit: BoxFit.contain),
            ),
          ),
        ),
        if (imageBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Center(
              child: Text(
                'Toucher pour zoomer',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
        const SizedBox(height: 24),

        // ─── Statut + actions rapides ──────────────────────────────
        Row(
          children: [
            ProofStatusBadge(status: proof.status),
            const Spacer(),
            OperatorChip(operator: proof.operator),
          ],
        ),
        const SizedBox(height: 16),

        if (proof.status == ProofStatus.pending) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : () => onUpdateStatus(ProofStatus.validated),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Valider'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => onUpdateStatus(ProofStatus.error),
                  icon: const Icon(Icons.error_outline),
                  label: const Text('Erreur'),
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else
          OutlinedButton.icon(
            onPressed: busy ? null : () => onUpdateStatus(ProofStatus.pending),
            icon: const Icon(Icons.replay),
            label: const Text('Repasser en attente'),
          ),

        const SizedBox(height: 8),
        const Divider(),

        // ─── Métadonnées ───────────────────────────────────────────
        _Field(
          label: 'Montant',
          value: proof.amount != null
              ? formatMoney(proof.amount!, proof.currency)
              : '—',
        ),
        if (proof.transactionReference != null)
          _Field(label: 'Référence', value: proof.transactionReference!, monospace: true),
        if (proof.transactionDate != null)
          _Field(label: 'Date transaction', value: dateFmt.format(proof.transactionDate!)),
        if (proof.clientName != null)
          _Field(label: 'Client', value: proof.clientName!),
        if (proof.orderNumber != null)
          _Field(label: 'Devis lié', value: proof.orderNumber!),
        if (proof.notes != null && proof.notes!.isNotEmpty)
          _Field(label: 'Notes', value: proof.notes!),
        if (proof.errorMessage != null && proof.errorMessage!.isNotEmpty)
          _Field(label: 'Erreur', value: proof.errorMessage!, color: theme.colorScheme.error),

        const Divider(),
        _Field(
          label: 'Taille image',
          value: '${(proof.imageSizeBytes / 1024).toStringAsFixed(0)} KB · ${proof.imageContentType}',
          color: theme.colorScheme.onSurfaceVariant,
        ),
        _Field(
          label: 'Créée le',
          value: dateFmt.format(proof.createdAt),
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenImageView(bytes: imageBytes!),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool monospace;

  const _Field({
    required this.label,
    required this.value,
    this.color,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontFamily: monospace ? 'monospace' : null,
                fontWeight: monospace ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenImageView extends StatelessWidget {
  final Uint8List bytes;
  const _FullscreenImageView({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Aperçu'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.memory(bytes),
        ),
      ),
    );
  }
}
