import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'catalog_api.dart';
import 'product_model.dart';
import 'whatsapp_launcher.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = CatalogApi();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _skuController;
  late final TextEditingController _imageUrlController;
  late bool _isActive;

  bool _saving = false;
  bool _deleting = false;
  bool _sharingWhatsApp = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _currencyController = TextEditingController(text: p?.currency ?? 'XAF');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _skuController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final price = num.parse(_priceController.text.replaceAll(' ', '').replaceAll(',', '.'));

    try {
      if (_isEditing) {
        await _api.update(
          widget.product!.id,
          name: _nameController.text.trim(),
          description: _nullIfEmpty(_descriptionController.text),
          price: price,
          currency: _currencyController.text.trim(),
          sku: _nullIfEmpty(_skuController.text),
          imageUrl: _nullIfEmpty(_imageUrlController.text),
          isActive: _isActive,
        );
      } else {
        await _api.create(
          name: _nameController.text.trim(),
          description: _nullIfEmpty(_descriptionController.text),
          price: price,
          currency: _currencyController.text.trim(),
          sku: _nullIfEmpty(_skuController.text),
          imageUrl: _nullIfEmpty(_imageUrlController.text),
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
        title: const Text('Supprimer ce produit ?'),
        content: Text(
          '« ${widget.product!.name} » sera supprimé définitivement. Pour le masquer sans perdre l\'historique, désactivez-le plutôt.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await _api.delete(widget.product!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceFirst('Exception: ', ''));
        setState(() => _deleting = false);
      }
    }
  }

  Future<void> _shareWhatsApp() async {
    if (widget.product == null) return;
    setState(() => _sharingWhatsApp = true);
    try {
      final link = await _api.getWhatsAppLink(widget.product!.id);
      if (!mounted) return;
      final ok = await WhatsAppLauncher.launch(link.url);
      if (!ok && mounted) {
        _showError("Impossible d'ouvrir WhatsApp.");
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sharingWhatsApp = false);
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

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _saving || _deleting || _sharingWhatsApp;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier produit' : 'Nouveau produit'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
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
                  labelText: 'Nom du produit *',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Prix *',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Prix requis';
                        final n = num.tryParse(v.replaceAll(' ', '').replaceAll(',', '.'));
                        if (n == null || n < 0) return 'Prix invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currencyController,
                      decoration: const InputDecoration(labelText: 'Devise'),
                      maxLength: 3,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
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
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image du produit (lien URL)',
                  prefixIcon: Icon(Icons.image_outlined),
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
              ),
              if (_imageUrlController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      _imageUrlController.text.trim(),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                ),
                      errorBuilder: (context, error, stack) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 4),
                            Text(
                              'Lien image invalide',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (_isEditing) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Produit actif'),
                  subtitle: Text(
                    _isActive
                        ? 'Visible dans le catalogue partageable'
                        : 'Masqué — l\'historique est préservé',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: busy ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? 'Enregistrer' : 'Créer le produit'),
              ),
              if (_isEditing && _isActive) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: busy ? null : _shareWhatsApp,
                  icon: _sharingWhatsApp
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.share),
                  label: const Text('Partager via WhatsApp'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
