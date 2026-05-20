using System.ComponentModel.DataAnnotations;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Application.Inventory.DTOs;

public record CreateInventoryItemRequest(
    [Required, MaxLength(150)] string Name,
    [MaxLength(50)] string? Sku,
    [MaxLength(1000)] string? Description,
    [MaxLength(10)] string? Unit,
    [Range(0, 99_999_999.999)] decimal InitialQuantity,
    [Range(0, 99_999_999.999)] decimal? ReorderThreshold,
    [Range(0, 9_999_999_999.99)] decimal? Cost,
    Guid? ProductId
);

public record UpdateInventoryItemRequest(
    [Required, MaxLength(150)] string Name,
    [MaxLength(50)] string? Sku,
    [MaxLength(1000)] string? Description,
    [MaxLength(10)] string? Unit,
    [Range(0, 99_999_999.999)] decimal? ReorderThreshold,
    [Range(0, 9_999_999_999.99)] decimal? Cost,
    Guid? ProductId
);

public record AdjustInventoryRequest(
    [Required, Range(typeof(decimal), "-99999999.999", "99999999.999")] decimal Delta,
    [Required] MovementReason Reason,
    [MaxLength(500)] string? Note
);

public record InventoryMovementResponse(
    Guid Id,
    decimal Change,
    MovementReason Reason,
    string ReasonLabel,
    decimal ResultingQuantity,
    string? Note,
    Guid? SalesOrderId,
    DateTime CreatedAt
);

public record InventoryItemResponse(
    Guid Id,
    string Name,
    string? Sku,
    string? Description,
    string Unit,
    decimal Quantity,
    decimal? ReorderThreshold,
    decimal? Cost,
    decimal? StockValue,
    bool IsLowStock,
    Guid? ProductId,
    DateTime? LastMovementAt,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record InventoryItemDetailResponse(
    Guid Id,
    string Name,
    string? Sku,
    string? Description,
    string Unit,
    decimal Quantity,
    decimal? ReorderThreshold,
    decimal? Cost,
    decimal? StockValue,
    bool IsLowStock,
    Guid? ProductId,
    DateTime? LastMovementAt,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    IEnumerable<InventoryMovementResponse> RecentMovements
);

public record InventoryListResponse(
    IEnumerable<InventoryItemResponse> Items,
    int Total,
    int Page,
    int PageSize,
    int LowStockCount
);
