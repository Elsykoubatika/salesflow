import 'package:flutter/material.dart';

import '../clients/client_model.dart';
import '../clients/clients_api.dart';

/// Champ réutilisable pour sélectionner un client existant.
/// Charge la liste via /api/Clients et renvoie le client choisi.
class ClientPickerField extends StatefulWidget {
  final Client? selected;
  final ValueChanged<Client> onSelected;
  final String label;

  const ClientPickerField({
    super.key,
    required this.selected,
    required this.onSelected,
    this.label = 'Client *',
  });

  @override
  State<ClientPickerField> createState() => _ClientPickerFieldState();
}

class _ClientPickerFieldState extends State<ClientPickerField> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          widget.selected?.fullName ?? 'Sélectionner un client',
          style: TextStyle(
            color: widget.selected == null
                ? Colors.grey.shade500
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  Future<void> _pick() async {
    final client = await showModalBottomSheet<Client>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ClientPickerSheet(),
    );
    if (client != null) widget.onSelected(client);
  }
}

class _ClientPickerSheet extends StatefulWidget {
  const _ClientPickerSheet();

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final _api = ClientsApi();
  late Future<ClientListResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.list(pageSize: 100);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Choisir un client',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: FutureBuilder<ClientListResponse>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
                    ),
                  );
                }
                final clients = snapshot.data!.items;
                if (clients.isEmpty) {
                  return const Center(
                    child: Text('Aucun client. Créez-en un d\'abord.'),
                  );
                }
                return ListView.builder(
                  itemCount: clients.length,
                  itemBuilder: (_, i) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF5E35B1),
                      child: Text(
                        clients[i].fullName.isNotEmpty
                            ? clients[i].fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(clients[i].fullName),
                    subtitle: clients[i].phoneNumber != null
                        ? Text(clients[i].phoneNumber!)
                        : null,
                    onTap: () => Navigator.pop(context, clients[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
