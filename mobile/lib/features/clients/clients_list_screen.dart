import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'client_form_screen.dart';
import 'client_model.dart';
import 'clients_cubit.dart';

class ClientsListScreen extends StatelessWidget {
  const ClientsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClientsCubit()..load(),
      child: const _ClientsListView(),
    );
  }
}

class _ClientsListView extends StatefulWidget {
  const _ClientsListView();

  @override
  State<_ClientsListView> createState() => _ClientsListViewState();
}

class _ClientsListViewState extends State<_ClientsListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm(BuildContext context, {Client? client}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)),
    );
    if (result == true && context.mounted) {
      context.read<ClientsCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher (nom, téléphone, ville...)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ClientsCubit>().search('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (value) {
                context.read<ClientsCubit>().search(value);
                setState(() {}); // Pour afficher la croix
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<ClientsCubit, ClientsState>(
              builder: (context, state) {
                return switch (state) {
                  ClientsLoading() => const Center(child: CircularProgressIndicator()),
                  ClientsError(message: final msg) => _ErrorView(
                      message: msg,
                      onRetry: () => context.read<ClientsCubit>().load(),
                    ),
                  ClientsLoaded(items: final items, total: _) when items.isEmpty =>
                    _EmptyView(
                      hasSearch: state.activeSearch != null && state.activeSearch!.isNotEmpty,
                      onCreate: () => _openForm(context),
                    ),
                  ClientsLoaded(items: final items, total: final total) => RefreshIndicator(
                      onRefresh: () => context.read<ClientsCubit>().refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 4),
                              child: Text(
                                '$total client${total > 1 ? 's' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          final client = items[index - 1];
                          return _ClientTile(
                            client: client,
                            onTap: () => _openForm(context, client: client),
                          );
                        },
                      ),
                    ),
                  _ => const SizedBox.shrink(),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const _ClientTile({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(client.fullName);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(client.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client.phoneNumber != null && client.phoneNumber!.isNotEmpty)
              Text(client.phoneNumber!),
            if (client.region != null && client.region!.isNotEmpty)
              Text(
                client.region!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onCreate;

  const _EmptyView({required this.hasSearch, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'Aucun client trouvé' : 'Pas encore de client',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Essayez une autre recherche.'
                  : 'Créez votre premier client pour commencer.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.person_add),
                label: const Text('Nouveau client'),
              ),
            ],
          ],
        ),
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
