class Product {
  final String id;
  final String name;
  final String? description;
  final num price;
  final String currency;
  final String? sku;
  final String? imageUrl;
  final String? variantsJson;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    this.sku,
    this.imageUrl,
    this.variantsJson,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as num,
      currency: json['currency'] as String,
      sku: json['sku'] as String?,
      imageUrl: json['imageUrl'] as String?,
      variantsJson: json['variantsJson'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }
}

class ProductListResponse {
  final List<Product> items;
  final int total;
  final int page;
  final int pageSize;

  ProductListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    return ProductListResponse(
      items: (json['items'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['pageSize'] as int,
    );
  }
}

/// Réponse de /api/Products/{id}/whatsapp-link
class WhatsAppLink {
  final String url;
  final String phoneNumber;
  final String message;

  WhatsAppLink({required this.url, required this.phoneNumber, required this.message});

  factory WhatsAppLink.fromJson(Map<String, dynamic> json) {
    return WhatsAppLink(
      url: json['url'] as String,
      phoneNumber: json['phoneNumber'] as String,
      message: json['message'] as String,
    );
  }
}
