import 'package:flutter/material.dart';

import 'client_model.dart';
import 'clients_api.dart';

/// Formulaire de création OU édition selon que `client` est fourni ou non.
/// Retourne `true` à Navigator.pop si une modification a été enregistrée.
class ClientFormScreen extends StatefulWidget {
  final Client? client;
  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ClientsApi();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _regionController;
  late final TextEditingController _notesController;

  bool _saving = false;
  bool _deleting = false;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _fullNameController = TextEditingController(text: c?.fullName ?? '');
    _phoneController = TextEditingController(text: c?.phoneNumber ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _regionController = TextEditingController(text: c?.region ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await _api.update(
          widget.client!.id,
          fullName: _fullNameController.text.trim(),
          phoneNumber: _nullIfEmpty(_phoneController.text),
          email: _nullIfEmpty(_emailController.text),
          address: _nullIfEmpty(_addressController.text),
          region: _nullIfEmpty(_regionController.text),
          notes: _nullIfEmpty(_notesController.text),
        );
      } else {
        await _api.create(
          fullName: _fullNameController.text.trim(),
          phoneNumber: _nullIfEmpty(_phoneController.text),
          email: _nullIfEmpty(_emailController.text),
          address: _nullIfEmpty(_addressController.text),
          region: _nullIfEmpty(_regionController.text),
          notes: _nullIfEmpty(_notesController.text),
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
        title: const Text('Supprimer ce client ?'),
        content: Text(
          'Cette action est définitive. Toutes les références à ${widget.client!.fullName} seront perdues sauf si elles sont déjà liées à un devis ou une commande.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await _api.delete(widget.client!.id);
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

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _deleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier client' : 'Nouveau client'),
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
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+242060000000',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                decoration: const InputDecoration(
                  labelText: 'Quartier / zone',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'Talangaï, Poto-Poto...',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse complète',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: busy ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Enregistrer' : 'Créer le client'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
