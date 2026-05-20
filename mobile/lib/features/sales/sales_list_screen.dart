import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../catalog/format_money.dart';
import 'sales_cubit.dart';
import 'sales_detail_screen.dart';
import 'sales_form_screen.dart';
import 'sales_order_model.dart';
import 'status_visual.dart';

class SalesListScreen extends StatelessWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesCubit()..load(),
      child: const _SalesListView(),
    );
  }
}

class _SalesListView extends StatelessWidget {
  const _SalesListView();

  Future<void> _openForm(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SalesFormScreen()),
    );
    if (result == true && context.mounted) {
      context.read<SalesCubit>().refresh();
    }
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalesDetailScreen(orderId: id)),
    );
    // Toujours rafraîchir au retour : le statut peut avoir changé.
    if (context.mounted) {
      context.read<SalesCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devis & Commandes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
      body: Column(
        children: [
          // Barre de filtres par statut
          BlocBuilder<SalesCubit, SalesState>(
            builder: (context, state) {
              final active = state is SalesLoaded ? state.statusFilter : null;
              return SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _FilterChip(label: 'Tous', selected: active == null,
                        onSelected: () => context.read<SalesCubit>().setStatusFilter(null)),
                    for (final s in SalesOrderStatus.values)
                      _FilterChip(
                        label: s.label,
                        selected: active == s,
                        onSelected: () => context.read<SalesCubit>().setStatusFilter(s),
                      ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<SalesCubit, SalesState>(
              builder: (context, state) {
                return switch (state) {
                  SalesLoading() => const Center(child: CircularProgressIndicator()),
                  SalesError(message: final msg) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(msg, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: () => context.read<SalesCubit>().load(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SalesLoaded(items: final items) when items.isEmpty => _EmptyView(
                      filtered: state.statusFilter != null,
                      onCreate: () => _openForm(context),
                    ),
                  SalesLoaded(items: final items, total: final total) => RefreshIndicator(
                      onRefresh: () => context.read<SalesCubit>().refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 4),
                              child: Text(
                                '$total document${total > 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          }
                          final item = items[index - 1];
                          return _OrderTile(item: item, onTap: () => _openDetail(context, item.id));
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final SalesOrderListItemDto item;
  final VoidCallback onTap;

  const _OrderTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(item.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  StatusBadge(status: item.status, compact: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(item.clientName, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(item.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    formatMoney(item.total, item.currency),
                    style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool filtered;
  final VoidCallback onCreate;

  const _EmptyView({required this.filtered, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(filtered ? 'Aucun document avec ce statut' : 'Aucun devis pour l\'instant',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              filtered ? 'Essayez un autre filtre.' : 'Créez votre premier devis pour démarrer le pipeline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (!filtered) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.add), label: const Text('Nouveau devis')),
            ],
          ],
        ),
      ),
    );
  }
}
