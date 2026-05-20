import 'dart:async';
import 'package:flutter/material.dart';

import '../clients/client_model.dart';
import '../clients/clients_api.dart';

/// Affiche une bottom sheet pour choisir un client existant.
/// Retourne le client sélectionné ou null si annulé.
Future<Client?> pickClient(BuildContext context) async {
  return showModalBottomSheet<Client>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => _ClientPickerSheet(scrollController: scrollController),
    ),
  );
}

class _ClientPickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _ClientPickerSheet({required this.scrollController});

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final _api = ClientsApi();
  final _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  List<Client> _clients = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _api.list(search: search, pageSize: 100);
      if (mounted) {
        setState(() {
        _clients = response.items;
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _load(search: value.isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Sélectionner un client', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _clients.isEmpty
                        ? const Center(child: Text('Aucun client.'))
                        : ListView.separated(
                            controller: widget.scrollController,
                            itemCount: _clients.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final c = _clients[index];
                              return ListTile(
                                title: Text(c.fullName),
                                subtitle: Text([
                                  if (c.phoneNumber != null && c.phoneNumber!.isNotEmpty) c.phoneNumber,
                                  if (c.region != null && c.region!.isNotEmpty) c.region,
                                ].whereType<String>().join(' • ')),
                                onTap: () => Navigator.pop(context, c),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
