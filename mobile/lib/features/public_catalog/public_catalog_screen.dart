import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../widgets/brand.dart';
import '../guest_cart/guest_cart_cubit.dart';
import 'public_catalog_cubit.dart';
import 'public_catalog_model.dart';
import 'public_catalog_state.dart';
import 'public_product_detail_screen.dart';
import '../../screens/guest_checkout_screen.dart';
import '../../screens/login_screen.dart';

/// Écran d'entrée — catalogue public croisé (mode invité).
///
/// Affiche les produits actifs de TOUS les vendeurs.
/// Le visiteur peut filtrer, chercher, ajouter au panier, commander.
/// Le bouton « Se connecter » en haut bascule vers l'app authentifiée.
class PublicCatalogScreen extends StatefulWidget {
  const PublicCatalogScreen({super.key});

  @override
  State<PublicCatalogScreen> createState() => _PublicCatalogScreenState();
}

class _PublicCatalogScreenState extends State<PublicCatalogScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PublicCatalogCubit>().loadInitial();
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<PublicCatalogCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DealFlowBrand.cream,
      body: Column(
        children: [
          _PublicHeader(
            searchController: _searchCtrl,
            onSearch: (q) => context.read<PublicCatalogCubit>().filter(query: q),
            onLogin: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
          Expanded(
            child: BlocBuilder<PublicCatalogCubit, PublicCatalogState>(
              builder: (context, state) {
                return switch (state) {
                  PublicCatalogInitial() ||
                  PublicCatalogLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  PublicCatalogError(:final message) => _ErrorView(
                      message: message,
                      onRetry: () =>
                          context.read<PublicCatalogCubit>().loadInitial(),
                    ),
                  PublicCatalogLoaded() => _CatalogBody(
                      state: state,
                      scrollController: _scrollCtrl,
                    ),
                };
              },
            ),
          ),
          const _CartFooter(),
        ],
      ),
    );
  }
}

// ─── Top bar émeraude (logo + se connecter + recherche) ──────────────────────
class _PublicHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onLogin;

  const _PublicHeader({
    required this.searchController,
    required this.onSearch,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DealFlowBrand.green900,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: DealFlowBrand.green500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DealFlow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onLogin,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 0.5,
                        ),
                      ),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  onSubmitted: onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Rechercher produit, service…',
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    prefixIcon: Icon(Icons.search,
                        size: 18, color: Colors.grey.shade600),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 11),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Corps : chips de catégories + grille produits + scroll infini ──────────
class _CatalogBody extends StatelessWidget {
  final PublicCatalogLoaded state;
  final ScrollController scrollController;

  const _CatalogBody({required this.state, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Aucun produit trouvé',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Essayez d\'élargir vos critères de recherche.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PublicCatalogCubit>().refresh(),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(child: _CategoryChips(state: state)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.66,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductCard(product: state.items[index]),
                childCount: state.items.length,
              ),
            ),
          ),
          if (state.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            )
          else if (!state.hasMore && state.items.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    '${state.total} produit${state.total > 1 ? 's' : ''} au total',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final PublicCatalogLoaded state;
  const _CategoryChips({required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: state.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final cat = state.categories[i];
          final selected = cat.slug == state.selectedCategory;
          return InkWell(
            onTap: () => context
                .read<PublicCatalogCubit>()
                .filter(category: cat.slug),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? DealFlowBrand.green900 : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? DealFlowBrand.green900
                      : Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                cat.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Carte produit ───────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final PublicProductSummary product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PublicProductDetailScreen(productId: product.id),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _ProductImage(url: product.imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatMoney(product.price, product.currency),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DealFlowBrand.green900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [product.sellerName, product.sellerRegion]
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;
  const _ProductImage({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.trim().isEmpty) {
      return Container(
        color: Colors.grey.shade100,
        child: Icon(Icons.shopping_bag_outlined,
            size: 36, color: Colors.grey.shade400),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (c, child, progress) => progress == null
          ? child
          : Container(
              color: Colors.grey.shade100,
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
      errorBuilder: (c, e, s) => Container(
        color: Colors.grey.shade100,
        child: Icon(Icons.image_not_supported_outlined,
            size: 32, color: Colors.grey.shade400),
      ),
    );
  }
}

// ─── Footer panier ───────────────────────────────────────────────────────────
class _CartFooter extends StatelessWidget {
  const _CartFooter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GuestCartCubit, GuestCartState>(
      builder: (context, cart) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined,
                      color: DealFlowBrand.green900, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mon panier',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${cart.itemCount} article${cart.itemCount > 1 ? 's' : ''} · '
                          '${_formatMoney(cart.total, cart.currency)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: DealFlowBrand.green900,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GuestCheckoutScreen(),
                      ),
                    ),
                    child: const Text('Commander',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.red.shade400, size: 42),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: DealFlowBrand.green800),
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double v, String currency) {
  final f = NumberFormat.decimalPattern('fr_FR');
  return '${f.format(v.round())} $currency';
}
