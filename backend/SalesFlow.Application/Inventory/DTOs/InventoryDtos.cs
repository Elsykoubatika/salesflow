using System.ComponentModel.DataAnnotations;
using SalesFlow.Domain.Enums;
namespace SalesFlow.Application.Inventory.DTOs;
// ✅ Créer un nouvel article en stock
public record CreateInventoryItemRequest(
[Required, MaxLength(200)] string Name,
[MaxLength(50)] string? Sku,
[MaxLength(500)] string? Description,
[Required, MaxLength(10)] string Unit = "pcs",
[Range(0, 999_999)] decimal InitialQuantity = 0,
[Range(0, 999_999)] decimal? ReorderThreshold = null,
[Range(0, 999_999)] decimal? Cost = null,
Guid? ProductId = null
);
// ✅ Mettre à jour un article
public record UpdateInventoryItemRequest(
[Required, MaxLength(200)] string Name,
[MaxLength(500)] string? Description,
[Range(0, 999_999)] decimal? ReorderThreshold = null,
[Range(0, 999_999)] decimal? Cost = null,
bool IsActive = true
);
// ✅ Enregistrer un mouvement de stock
public record CreateInventoryMovementRequest(
[Required] Guid InventoryItemId,
[Required] decimal Change, // Positif = entrée, Négatif = sortie
[Required] MovementReason Reason,
[MaxLength(500)] string? Note = null,
Guid? SalesOrderId = null
);
// ✅ Réponse article en stock
public record InventoryItemResponse(
Guid Id,
string Name,
string? Sku,
string? Description,
string Unit,
decimal Quantity,
decimal? ReorderThreshold,
decimal? Cost,
bool IsLowStock,
decimal? StockValue,
string? ProductName,
DateTime? LastMovementAt,
bool IsActive,
int MovementCount,
DateTime CreatedAt,
DateTime? UpdatedAt
);
// ✅ Liste paginée d'articles
public record InventoryListResponse(
IEnumerable<InventoryItemResponse> Items,
int Total,
int LowStockCount,
int Page,
int PageSize
);
// ✅ Réponse mouvement de stock
public record InventoryMovementResponse(
Guid Id,
Guid InventoryItemId,
string ItemName,
decimal Change,
string Reason,
decimal ResultingQuantity,
string? Note,
Guid? SalesOrderId,
DateTime CreatedAt
);
// ✅ Liste des mouvements d'un article
public record InventoryMovementListResponse(
Guid InventoryItemId,
string ItemName,
IEnumerable<InventoryMovementResponse> Movements,
int Total
);
