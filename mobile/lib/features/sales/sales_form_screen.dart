import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../catalog/format_money.dart';
import '../clients/client_model.dart';
import 'client_picker_sheet.dart';
import 'product_picker_sheet.dart';
import 'sales_api.dart';

/// Représente une ligne en cours d'édition dans le formulaire.
/// Garde les contrôleurs de texte pour permettre la saisie libre.
class _FormLine {
  final String? productId;
  final TextEditingController descriptionController;
  final TextEditingController unitPriceController;
  final TextEditingController quantityController;

  _FormLine({
    this.productId,
    required String description,
    required num unitPrice,
    num quantity = 1,
  })  : descriptionController = TextEditingController(text: description),
        unitPriceController = TextEditingController(text: _formatNum(unitPrice)),
        quantityController = TextEditingController(text: _formatNum(quantity));

  static String _formatNum(num n) {
    if (n == n.truncate()) return n.toInt().toString();
    return n.toString();
  }

  num get unitPrice => num.tryParse(unitPriceController.text.replaceAll(',', '.')) ?? 0;
  num get quantity => num.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0;
  num get lineTotal => unitPrice * quantity;

  void dispose() {
    descriptionController.dispose();
    unitPriceController.dispose();
    quantityController.dispose();
  }
}

class SalesFormScreen extends StatefulWidget {
  const SalesFormScreen({super.key});

  @override
  State<SalesFormScreen> createState() => _SalesFormScreenState();
}

class _SalesFormScreenState extends State<SalesFormScreen> {
  final _api = SalesApi();
  final _notesController = TextEditingController();

  Client? _client;
  final List<_FormLine> _lines = [];
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _selectClient() async {
    final selected = await pickClient(context);
    if (selected != null) setState(() => _client = selected);
  }

  Future<void> _addProductLine() async {
    final selected = await pickProduct(context);
    if (selected == null) return;
    setState(() {
      _lines.add(_FormLine(
        productId: selected.id,
        description: selected.name,
        unitPrice: selected.price,
      ));
    });
  }

  void _addFreeLine() {
    setState(() {
      _lines.add(_FormLine(description: '', unitPrice: 0));
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines[index].dispose();
      _lines.removeAt(index);
    });
  }

  // ─── Sauvegarde ────────────────────────────────────────────────────────────

  String? _validateForm() {
    if (_client == null) return 'Sélectionnez un client.';
    if (_lines.isEmpty) return 'Ajoutez au moins une ligne.';
    for (var i = 0; i < _lines.length; i++) {
      final l = _lines[i];
      if (l.descriptionController.text.trim().isEmpty) {
        return 'La description de la ligne ${i + 1} est requise.';
      }
      if (l.unitPrice < 0) return 'Prix unitaire négatif (ligne ${i + 1}).';
      if (l.quantity <= 0) return 'Quantité doit être > 0 (ligne ${i + 1}).';
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validateForm();
    if (error != null) {
      _showError(error);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final payload = _lines
          .map((l) => CreateOrderItemPayload(
                productId: l.productId,
                description: l.descriptionController.text.trim(),
                unitPrice: l.unitPrice,
                quantity: l.quantity,
              ))
          .toList();

      await _api.create(
        clientId: _client!.id,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: payload,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
        setState(() => _saving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = _lines.fold<num>(0, (sum, l) => sum + l.lineTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau devis')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Client ────────────────────────────────────────────────────
            Text('CLIENT', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const Icon(Icons.person_outline),
                title: Text(_client?.fullName ?? 'Aucun client sélectionné'),
                subtitle: _client?.phoneNumber != null && _client!.phoneNumber!.isNotEmpty
                    ? Text(_client!.phoneNumber!)
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectClient,
              ),
            ),

            const SizedBox(height: 24),

            // ─── Lignes ────────────────────────────────────────────────────
            Row(
              children: [
                Text('LIGNES', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5)),
                const Spacer(),
                Text('${_lines.length} ligne${_lines.length > 1 ? 's' : ''}',
                    style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _lines.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LineCard(
                  line: _lines[i],
                  index: i,
                  onChanged: () => setState(() {}),
                  onRemove: () => _removeLine(i),
                ),
              ),

            // Boutons d'ajout de ligne
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addProductLine,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Produit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addFreeLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Ligne libre'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── Notes ─────────────────────────────────────────────────────
            Text('NOTES', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Conditions, mentions, validité...',
              ),
            ),

            const SizedBox(height: 24),

            // ─── Total ─────────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Sous-total', style: theme.textTheme.bodyMedium),
                        const Spacer(),
                        Text(formatMoney(subtotal, 'XAF'), style: theme.textTheme.bodyLarge),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Text('TOTAL',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          formatMoney(subtotal, 'XAF'),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Créer le devis'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final _FormLine line;
  final int index;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _LineCard({
    required this.line,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProduct = line.productId != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasProduct ? Icons.shopping_bag_outlined : Icons.text_snippet_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  hasProduct ? 'Produit catalogue' : 'Ligne libre',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onRemove,
                  tooltip: 'Retirer la ligne',
                ),
              ],
            ),
            TextField(
              controller: line.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: line.unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: const InputDecoration(
                      labelText: 'Prix unitaire',
                      isDense: true,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: line.quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      isDense: true,
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatMoney(line.lineTotal, 'XAF'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
