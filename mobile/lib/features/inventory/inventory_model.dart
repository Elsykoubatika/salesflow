enum MovementReason {
  restock(1, 'Réapprovisionnement', true),
  sale(2, 'Vente', false),
  customerReturn(3, 'Retour client', true),
  adjustment(4, 'Ajustement', null),
  loss(5, 'Perte / casse', false),
  initialStock(6, 'Stock initial', true);

  final int value;
  final String label;
  final bool? isPositive; // null = peut être les deux (ajustement)

  const MovementReason(this.value, this.label, this.isPositive);

  static MovementReason fromValue(int v) => MovementReason.values.firstWhere(
        (r) => r.value == v,
        orElse: () => MovementReason.adjustment,
      );
}

class InventoryItem {
  final String id;
  final String name;
  final String? sku;
  final String? description;
  final String unit;
  final num quantity;
  final num? reorderThreshold;
  final num? cost;
  final num? stockValue;
  final bool isLowStock;
  final String? productId;
  final DateTime? lastMovementAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double alertThreshold;

  InventoryItem({
    required this.id,
    required this.name,
    this.sku,
    this.description,
    required this.unit,
    required this.quantity,
    this.reorderThreshold,
    this.cost,
    this.stockValue,
    required this.isLowStock,
    this.productId,
    this.lastMovementAt,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.alertThreshold,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Inconnu',
      sku: json['sku'] as String?,
      description: json['description'] as String?,
      unit: json['unit'] as String? ?? '',

      // Sécurisation des nombres (num? -> double)
      quantity: (json['quantity'] as num? ?? 0).toDouble(),
      reorderThreshold: (json['reorderThreshold'] as num? ?? 0).toDouble(),
      cost: (json['cost'] as num? ?? 0).toDouble(),
      stockValue: (json['stockValue'] as num? ?? 0).toDouble(),

      isLowStock: json['isLowStock'] as bool? ?? false,
      productId: json['productId'] as String?,
      lastMovementAt: _parseDate(json['lastMovementAt']),
      isActive: json['isActive'] as bool? ?? true,

      // Sécurisation de la date de création
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),

      updatedAt: _parseDate(json['updatedAt']),

      // LA LIGNE QUI POSAIT PROBLÈME :
      alertThreshold: (json['alertThreshold'] as num? ?? 0.0).toDouble(),
    );
  }
}

class InventoryMovement {
  final String id;
  final num change;
  final MovementReason reason;
  final num resultingQuantity;
  final String? note;
  final String? salesOrderId;
  final DateTime createdAt;

  InventoryMovement({
    required this.id,
    required this.change,
    required this.reason,
    required this.resultingQuantity,
    this.note,
    this.salesOrderId,
    required this.createdAt,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) {
    return InventoryMovement(
      id: json['id'] as String,
      change: json['change'] as num,
      reason: MovementReason.fromValue(json['reason'] as int),
      resultingQuantity: json['resultingQuantity'] as num,
      note: json['note'] as String?,
      salesOrderId: json['salesOrderId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class InventoryItemDetail {
  final InventoryItem item;
  final List<InventoryMovement> recentMovements;

  InventoryItemDetail({required this.item, required this.recentMovements});

  factory InventoryItemDetail.fromJson(Map<String, dynamic> json) {
    // 1. On sécurise la liste des mouvements au cas où 'recentMovements' est null
    final movementsData = json['recentMovements'] as List?;

    final movements = (movementsData ?? [])
        .map((e) => InventoryMovement.fromJson(e as Map<String, dynamic>))
        .toList();

    // 2. C'est ici que le piège se cache :
    // On appelle InventoryItem.fromJson(json).
    // Si l'erreur persiste, c'est que le crash se produit À L'INTÉRIEUR de InventoryItem.
    final item = InventoryItem.fromJson(json);

    return InventoryItemDetail(
      item: item,
      recentMovements: movements,
    );
  }
}

class InventoryListResponse {
  final List<InventoryItem> items;
  final int total;
  final int page;
  final int pageSize;
  final int lowStockCount;

  InventoryListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.lowStockCount,
  });

  factory InventoryListResponse.fromJson(Map<String, dynamic> json) {
    return InventoryListResponse(
      // 1. On sécurise la liste : si 'items' est null, on renvoie une liste vide []
      items: (json['items'] as List? ?? [])
          .map((e) => InventoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),

      // 2. On sécurise les compteurs : si null, on met 0
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      lowStockCount: json['lowStockCount'] as int? ?? 0,
    );
  }
}

DateTime? _parseDate(dynamic date) {
  if (date == null) return null;
  return DateTime.parse(date as String);
}
