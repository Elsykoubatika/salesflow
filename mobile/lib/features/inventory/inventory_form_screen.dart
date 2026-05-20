import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'inventory_api.dart';
import 'inventory_model.dart';

class InventoryFormScreen extends StatefulWidget {
  final InventoryItem? item;
  const InventoryFormScreen({super.key, this.item});

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = InventoryApi();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _initialQuantityController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _costController;
  String _unit = 'pcs';

  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.item != null;

  static const _units = ['pcs', 'kg', 'g', 'L', 'mL', 'm', 'h'];

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nameController = TextEditingController(text: i?.name ?? '');
    _skuController = TextEditingController(text: i?.sku ?? '');
    _descriptionController = TextEditingController(text: i?.description ?? '');
    _initialQuantityController = TextEditingController(text: i == null ? '0' : '');
    _thresholdController = TextEditingController(text: i?.reorderThreshold?.toString() ?? '');
    _costController = TextEditingController(text: i?.cost?.toString() ?? '');
    _unit = i?.unit ?? 'pcs';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _initialQuantityController.dispose();
    _thresholdController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final threshold = _parseNum(_thresholdController.text);
    final cost = _parseNum(_costController.text);

    try {
      if (_isEditing) {
        await _api.update(
          widget.item!.id,
          name: _nameController.text.trim(),
          sku: _nullIfEmpty(_skuController.text),
          description: _nullIfEmpty(_descriptionController.text),
          unit: _unit,
          reorderThreshold: threshold,
          cost: cost,
        );
      } else {
        final initialQty = _parseNum(_initialQuantityController.text) ?? 0;
        await _api.create(
          name: _nameController.text.trim(),
          sku: _nullIfEmpty(_skuController.text),
          description: _nullIfEmpty(_descriptionController.text),
          unit: _unit,
          initialQuantity: initialQty,
          reorderThreshold: threshold,
          cost: cost,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Désactiver cet article ?'),
        content: const Text(
          "L'article sera masqué mais l'historique des mouvements est préservé. "
          "Vous pourrez le réactiver plus tard.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await _api.delete(widget.item!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
        setState(() => _deleting = false);
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

  num? _parseNum(String s) => num.tryParse(s.replaceAll(',', '.').replaceAll(' ', ''));
  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _saving || _deleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier article' : 'Nouvel article'),
        actions: [
          if (_isEditing && widget.item!.isActive)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Désactiver',
              onPressed: busy ? null : _confirmDelete,
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: busy,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'article *',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU / référence',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Text('UNITÉ DE MESURE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _units
                    .map((u) => ChoiceChip(
                          label: Text(u),
                          selected: _unit == u,
                          onSelected: (_) => setState(() => _unit = u),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (!_isEditing) ...[
                TextFormField(
                  controller: _initialQuantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: InputDecoration(
                    labelText: 'Quantité initiale',
                    prefixIcon: const Icon(Icons.inventory_outlined),
                    suffixText: _unit,
                    helperText: 'Crée un mouvement « Stock initial »',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _thresholdController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: 'Seuil d\'alerte',
                  prefixIcon: const Icon(Icons.notifications_outlined),
                  suffixText: _unit,
                  helperText: 'L\'article apparaît dans /alertes en dessous de ce seuil',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(
                  labelText: 'Coût d\'achat unitaire',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: 'XAF',
                  helperText: 'Pour calculer la valeur du stock',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: busy ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? 'Enregistrer' : 'Créer l\'article'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
