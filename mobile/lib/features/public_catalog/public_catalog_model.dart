import 'package:equatable/equatable.dart';

/// Réponse paginée de GET /api/public/catalog
class PublicCatalogPage extends Equatable {
  final List<PublicProductSummary> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PublicCatalogPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PublicCatalogPage.fromJson(Map<String, dynamic> json) {
    return PublicCatalogPage(
      items: ((json['items'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(PublicProductSummary.fromJson)
          .toList(),
      total: (json['total'] as num? ?? 0).toInt(),
      page: (json['page'] as num? ?? 1).toInt(),
      pageSize: (json['pageSize'] as num? ?? 24).toInt(),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [items, total, page, pageSize, hasMore];
}

/// Produit vu depuis le catalogue public — inclut les infos vendeur.
class PublicProductSummary extends Equatable {
  final String id;
  final String name;
  final String? sku;
  final String? description;
  final double price;
  final String currency;
  final String? imageUrl;
  final String sellerId;
  final String sellerName;
  final String sellerRegion;

  const PublicProductSummary({
    required this.id,
    required this.name,
    this.sku,
    this.description,
    required this.price,
    required this.currency,
    this.imageUrl,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRegion,
  });

  factory PublicProductSummary.fromJson(Map<String, dynamic> json) {
    return PublicProductSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'XAF',
      imageUrl: json['imageUrl'] as String?,
      sellerId: json['sellerId'] as String? ?? '',
      sellerName: json['sellerName'] as String? ?? '',
      sellerRegion: json['sellerRegion'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, price, sellerId];
}

/// Détail produit (idem summary + téléphone vendeur si disponible).
class PublicProductDetail extends PublicProductSummary {
  final String? sellerPhone;

  const PublicProductDetail({
    required super.id,
    required super.name,
    super.sku,
    super.description,
    required super.price,
    required super.currency,
    super.imageUrl,
    required super.sellerId,
    required super.sellerName,
    required super.sellerRegion,
    this.sellerPhone,
  });

  factory PublicProductDetail.fromJson(Map<String, dynamic> json) {
    return PublicProductDetail(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'XAF',
      imageUrl: json['imageUrl'] as String?,
      sellerId: json['sellerId'] as String? ?? '',
      sellerName: json['sellerName'] as String? ?? '',
      sellerRegion: json['sellerRegion'] as String? ?? '',
      sellerPhone: json['sellerPhone'] as String?,
    );
  }
}

/// Catégorie de filtrage.
class CategoryItem extends Equatable {
  final String slug;
  final String label;
  const CategoryItem({required this.slug, required this.label});

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        slug: json['slug'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  @override
  List<Object?> get props => [slug];
}

/// Item du panier invité (en mémoire — pas persisté côté backend tant qu'on
/// n'a pas validé la commande).
class GuestCartItem extends Equatable {
  final PublicProductSummary product;
  final int quantity;
  const GuestCartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  GuestCartItem copyWith({int? quantity}) =>
      GuestCartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product.id, quantity];
}

/// Réponse de POST /api/public/guest-orders
class GuestOrderResult extends Equatable {
  final String orderId;
  final String orderCode;
  final double totalAmount;
  final String currency;
  final String customerId;
  final bool isNewAccount;
  final String message;

  const GuestOrderResult({
    required this.orderId,
    required this.orderCode,
    required this.totalAmount,
    required this.currency,
    required this.customerId,
    required this.isNewAccount,
    required this.message,
  });

  factory GuestOrderResult.fromJson(Map<String, dynamic> json) {
    return GuestOrderResult(
      orderId: json['orderId'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'XAF',
      customerId: json['customerId'] as String? ?? '',
      isNewAccount: json['isNewAccount'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [orderId, orderCode];
}
