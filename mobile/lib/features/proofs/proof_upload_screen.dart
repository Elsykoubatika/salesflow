import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../clients/client_model.dart';
import '../sales/client_picker_sheet.dart';
import '../sales/sales_order_model.dart';
import 'proof_model.dart';
import 'proofs_api.dart';
import 'sales_order_picker_sheet.dart';

/// Écran de saisie des champs métier après prise/sélection d'une image.
/// Pop avec `true` après upload réussi.
class ProofUploadScreen extends StatefulWidget {
  final String imagePath;
  const ProofUploadScreen({super.key, required this.imagePath});

  @override
  State<ProofUploadScreen> createState() => _ProofUploadScreenState();
}

class _ProofUploadScreenState extends State<ProofUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ProofsApi();

  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  MobileMoneyOperator _operator = MobileMoneyOperator.other;
  DateTime? _transactionDate = DateTime.now();
  Client? _client;
  SalesOrderListItemDto? _order;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle preuve'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Aperçu de l'image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 240,
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 48)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Opérateur ──────────────────────────────────────────
            Text('Opérateur', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<MobileMoneyOperator>(
              segments: const [
                ButtonSegment(value: MobileMoneyOperator.mtnMomo, label: Text('MTN'), icon: Icon(Icons.phone_android)),
                ButtonSegment(value: MobileMoneyOperator.airtelMoney, label: Text('Airtel')),
                ButtonSegment(value: MobileMoneyOperator.other, label: Text('Autre')),
              ],
              selected: {_operator},
              onSelectionChanged: (s) => setState(() => _operator = s.first),
            ),
            const SizedBox(height: 16),

            // ─── Montant ────────────────────────────────────────────
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(
                labelText: 'Montant',
                suffixText: 'XAF',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final parsed = num.tryParse(v.replaceAll(',', '.'));
                if (parsed == null || parsed < 0) return 'Montant invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ─── Référence transaction ──────────────────────────────
            TextFormField(
              controller: _refCtrl,
              decoration: const InputDecoration(
                labelText: 'Référence transaction',
                hintText: 'Ex: MP240507.1432.B45612',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Date transaction ───────────────────────────────────
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de la transaction',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _transactionDate != null ? dateFmt.format(_transactionDate!) : 'Sélectionner',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Client (optionnel) ─────────────────────────────────
            _LinkTile(
              icon: Icons.person_outline,
              label: 'Client (optionnel)',
              value: _client?.fullName,
              onPick: () async {
                final c = await pickClient(context);
                if (c != null) setState(() => _client = c);
              },
              onClear: _client == null ? null : () => setState(() => _client = null),
            ),
            const SizedBox(height: 12),

            // ─── Devis lié (optionnel) ──────────────────────────────
            _LinkTile(
              icon: Icons.receipt_long_outlined,
              label: 'Devis/Commande (optionnel)',
              value: _order != null ? '${_order!.orderNumber} · ${_order!.clientName}' : null,
              onPick: () async {
                final o = await pickSalesOrder(context);
                if (o != null) {
                  setState(() {
                    _order = o;
                    // Auto-remplissage du montant si vide
                    if (_amountCtrl.text.trim().isEmpty) {
                      _amountCtrl.text = o.total.toString();
                    }
                  });
                }
              },
              onClear: _order == null ? null : () => setState(() => _order = null),
            ),
            const SizedBox(height: 16),

            // ─── Notes ──────────────────────────────────────────────
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_saving ? 'Envoi en cours...' : 'Enregistrer la preuve'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _transactionDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_transactionDate ?? now),
    );
    if (!mounted) return;

    setState(() {
      _transactionDate = DateTime(
        date.year, date.month, date.day,
        time?.hour ?? 0, time?.minute ?? 0,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final amount = _amountCtrl.text.trim().isEmpty
          ? null
          : num.parse(_amountCtrl.text.replaceAll(',', '.'));

      await _api.create(
        filePath: widget.imagePath,
        amount: amount,
        currency: 'XAF',
        transactionReference: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        operator: _operator,
        transactionDate: _transactionDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        clientId: _client?.id,
        salesOrderId: _order?.id,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preuve enregistrée'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.close), onPressed: onClear)
              : null,
        ),
        child: Text(
          value ?? 'Sélectionner',
          style: TextStyle(
            color: value == null ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ),
    );
  }
}
