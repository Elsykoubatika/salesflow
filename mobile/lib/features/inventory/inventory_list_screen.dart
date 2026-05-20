import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../catalog/format_money.dart';
import 'inventory_cubit.dart';
import 'inventory_detail_screen.dart';
import 'inventory_form_screen.dart';
import 'inventory_model.dart';

class InventoryListScreen extends StatelessWidget {
  const InventoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryCubit()..load(),
      child: const _InventoryListView(),
    );
  }
}

class _InventoryListView extends StatefulWidget {
  const _InventoryListView();

  @override
  State<_InventoryListView> createState() => _InventoryListViewState();
}

class _InventoryListViewState extends State<_InventoryListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const InventoryFormScreen()),
    );
    if (result == true && context.mounted) {
      context.read<InventoryCubit>().refresh();
    }
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InventoryDetailScreen(itemId: id)),
    );
    if (context.mounted) {
      context.read<InventoryCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              final activeOnly = state is InventoryLoaded ? state.activeOnly : true;
              return IconButton(
                icon: Icon(activeOnly ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: activeOnly ? 'Voir aussi les inactifs' : 'Voir uniquement les actifs',
                onPressed: () => context.read<InventoryCubit>().toggleActiveOnly(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: Column(
        children: [
          // Bandeau d'alerte si articles sous le seuil
          BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              if (state is! InventoryLoaded || state.lowStockCount == 0) {
                return const SizedBox.shrink();
              }
              return _AlertBanner(
                count: state.lowStockCount,
                showingOnlyAlerts: state.lowStockOnly,
                onTap: () => context.read<InventoryCubit>().toggleLowStockOnly(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher (nom, SKU, description)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          context.read<InventoryCubit>().search('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (value) {
                context.read<InventoryCubit>().search(value);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<InventoryCubit, InventoryState>(
              builder: (context, state) {
                return switch (state) {
                  InventoryLoading() => const Center(child: CircularProgressIndicator()),
                  InventoryError(message: final msg) => _ErrorView(
                      message: msg,
                      onRetry: () => context.read<InventoryCubit>().load(),
                    ),
                  InventoryLoaded(items: final items) when items.isEmpty => _EmptyView(
                      hasFilter: state.lowStockOnly ||
                          (state.activeSearch != null && state.activeSearch!.isNotEmpty),
                      onCreate: () => _openForm(context),
                    ),
                  InventoryLoaded(items: final items, total: final total) => RefreshIndicator(
                      onRefresh: () => context.read<InventoryCubit>().refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 4),
                              child: Text(
                                '$total article${total > 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          final item = items[index - 1];
                          return _InventoryTile(item: item, onTap: () => _openDetail(context, item.id));
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

class _AlertBanner extends StatelessWidget {
  final int count;
  final bool showingOnlyAlerts;
  final VoidCallback onTap;

  const _AlertBanner({required this.count, required this.showingOnlyAlerts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4E5),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[800]),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.orange[900], fontSize: 14),
                    children: [
                      TextSpan(
                        text: '$count article${count > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: count > 1 ? ' sont sous le seuil d\'alerte' : ' est sous le seuil d\'alerte'),
                    ],
                  ),
                ),
              ),
              Text(
                showingOnlyAlerts ? 'Tout voir' : 'Filtrer',
                style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  const _InventoryTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: item.isLowStock
                    ? const Color(0xFFFFE0B2)
                    : theme.colorScheme.primaryContainer,
                foregroundColor: item.isLowStock
                    ? Colors.orange[800]
                    : theme.colorScheme.onPrimaryContainer,
                child: Icon(item.isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!item.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Inactif',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${_fmt(item.quantity)} ${item.unit}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: item.isLowStock ? Colors.orange[800] : theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.reorderThreshold != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '/ seuil ${_fmt(item.reorderThreshold!)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                    if (item.sku != null && item.sku!.isNotEmpty)
                      Text(
                        item.sku!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    if (item.stockValue != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Valeur ${formatMoney(item.stockValue!, 'XAF')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(num n) {
    if (n == n.truncate()) return n.toInt().toString();
    return n.toString();
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onCreate;
  const _EmptyView({required this.hasFilter, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(hasFilter ? 'Aucun article correspondant' : 'Stock vide',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              hasFilter ? 'Essayez d\'autres filtres.' : 'Ajoutez votre premier article pour suivre votre stock.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (!hasFilter) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Nouvel article')),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
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
