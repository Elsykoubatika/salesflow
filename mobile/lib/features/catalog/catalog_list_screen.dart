import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'catalog_api.dart';
import 'catalog_cubit.dart';
import 'format_money.dart';
import 'product_form_screen.dart';
import 'product_model.dart';
import 'whatsapp_launcher.dart';

class CatalogListScreen extends StatelessWidget {
  const CatalogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CatalogCubit()..load(),
      child: const _CatalogListView(),
    );
  }
}

class _CatalogListView extends StatefulWidget {
  const _CatalogListView();

  @override
  State<_CatalogListView> createState() => _CatalogListViewState();
}

class _CatalogListViewState extends State<_CatalogListView> {
  final _searchController = TextEditingController();
  final _api = CatalogApi();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm(BuildContext context, {Product? product}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (result == true && context.mounted) {
      context.read<CatalogCubit>().refresh();
    }
  }

  /// Génère le lien WhatsApp via l'API et le lance dans WhatsApp.
  Future<void> _shareWhatsApp(BuildContext context, Product product) async {
    // Affiche un loader pendant la génération du lien
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final link = await _api.getWhatsAppLink(product.id);
      if (!context.mounted) return;
      Navigator.pop(context); // ferme le loader

      // Petite feuille de confirmation avant d'ouvrir WhatsApp
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _WhatsAppPreviewSheet(link: link),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // ferme le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          BlocBuilder<CatalogCubit, CatalogState>(
            builder: (context, state) {
              final activeOnly = state is CatalogLoaded ? state.activeOnly : true;
              return IconButton(
                icon: Icon(activeOnly ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                tooltip: activeOnly ? 'Voir aussi les inactifs' : 'Voir uniquement les actifs',
                onPressed: () => context.read<CatalogCubit>().toggleActiveOnly(),
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
                          context.read<CatalogCubit>().search('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (value) {
                context.read<CatalogCubit>().search(value);
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<CatalogCubit, CatalogState>(
              builder: (context, state) {
                return switch (state) {
                  CatalogLoading() => const Center(child: CircularProgressIndicator()),
                  CatalogError(message: final msg) => _ErrorView(
                      message: msg,
                      onRetry: () => context.read<CatalogCubit>().load(),
                    ),
                  CatalogLoaded(items: final items) when items.isEmpty => _EmptyView(
                      hasSearch: state.activeSearch != null && state.activeSearch!.isNotEmpty,
                      onCreate: () => _openForm(context),
                    ),
                  CatalogLoaded(items: final items, total: final total) => RefreshIndicator(
                      onRefresh: () => context.read<CatalogCubit>().refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: items.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4, left: 4),
                              child: Text(
                                '$total produit${total > 1 ? 's' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          final p = items[index - 1];
                          return _ProductTile(
                            product: p,
                            onTap: () => _openForm(context, product: p),
                            onShare: () => _shareWhatsApp(context, p),
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

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onShare;

  const _ProductTile({required this.product, required this.onTap, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!product.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Inactif',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMoney(product.price, product.currency),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.sku != null && product.sku!.isNotEmpty)
                      Text(
                        product.sku!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                color: theme.colorScheme.primary,
                tooltip: 'Partager via WhatsApp',
                onPressed: product.isActive ? onShare : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet de prévisualisation/confirmation avant ouverture WhatsApp.
class _WhatsAppPreviewSheet extends StatelessWidget {
  final dynamic link; // WhatsAppLink — typé via dynamic pour éviter l'import circulaire ici

  const _WhatsAppPreviewSheet({required this.link});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
            Text('Lien WhatsApp prêt', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Numéro destinataire : ${link.phoneNumber}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(link.message, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final ok = await WhatsAppLauncher.launch(link.url);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Impossible d'ouvrir WhatsApp.")),
                  );
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Ouvrir WhatsApp'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await WhatsAppLauncher.copyToClipboard(link.url);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lien copié dans le presse-papiers.')),
                  );
                }
              },
              icon: const Icon(Icons.content_copy_outlined),
              label: const Text('Copier le lien'),
            ),
          ],
        ),
      ),
    );
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
            Icon(Icons.shopping_bag_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'Aucun produit trouvé' : 'Catalogue vide',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch ? 'Essayez une autre recherche.' : 'Ajoutez votre premier produit pour pouvoir le partager.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Nouveau produit'),
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
