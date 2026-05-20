import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'inventory_api.dart';
import 'inventory_model.dart';

/// Affiche la sheet d'ajustement de stock pour un article donné.
/// Retourne true si un ajustement a été effectué.
Future<bool?> showAdjustStockSheet(BuildContext context, InventoryItem item) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AdjustStockSheet(item: item),
  );
}

class _AdjustStockSheet extends StatefulWidget {
  final InventoryItem item;
  const _AdjustStockSheet({required this.item});

  @override
  State<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends State<_AdjustStockSheet> {
  final _api = InventoryApi();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isOutgoing = false; // false = entrée, true = sortie
  MovementReason _reason = MovementReason.restock;
  bool _saving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Filtre les raisons selon le sens (entrée/sortie) du mouvement.
  List<MovementReason> get _availableReasons {
    return MovementReason.values.where((r) {
      if (r == MovementReason.initialStock) return false; // jamais en manuel
      if (r.isPositive == null) return true; // ajustement = OK pour les deux
      return r.isPositive == !_isOutgoing;
    }).toList();
  }

  Future<void> _submit() async {
    final qty = num.tryParse(_quantityController.text.replaceAll(',', '.').replaceAll(' ', ''));
    if (qty == null || qty <= 0) {
      _showError('Saisissez une quantité positive.');
      return;
    }

    final delta = _isOutgoing ? -qty : qty;
    setState(() => _saving = true);

    try {
      await _api.adjust(
        widget.item.id,
        delta: delta,
        reason: _reason,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Ajuster le stock', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${widget.item.name} • ${widget.item.quantity} ${widget.item.unit} en stock',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // Switch entrée/sortie
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Entrée'), icon: Icon(Icons.add)),
                  ButtonSegment(value: true, label: Text('Sortie'), icon: Icon(Icons.remove)),
                ],
                selected: {_isOutgoing},
                onSelectionChanged: (s) {
                  setState(() {
                    _isOutgoing = s.first;
                    // Reset à une raison valide pour le nouveau sens
                    _reason = _availableReasons.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Quantité
              TextField(
                controller: _quantityController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  suffixText: widget.item.unit,
                  prefixIcon: Icon(_isOutgoing ? Icons.remove : Icons.add),
                ),
              ),
              const SizedBox(height: 16),

              // Raison
              DropdownButtonFormField<MovementReason>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'Motif',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                items: _availableReasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) => setState(() => _reason = v ?? _reason),
              ),
              const SizedBox(height: 16),

              // Note
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (optionnel)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  hintText: 'BL #4521, casse magasin, etc.',
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isOutgoing ? 'Enregistrer la sortie' : 'Enregistrer l\'entrée'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
