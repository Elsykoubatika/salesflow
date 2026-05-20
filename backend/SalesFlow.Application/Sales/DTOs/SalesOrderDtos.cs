using System.ComponentModel.DataAnnotations;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Application.Sales.DTOs;

// ─── Lignes ──────────────────────────────────────────────────────────────────

public record CreateSalesOrderItemRequest(
    Guid? ProductId,
    [Required, MaxLength(500)] string Description,
    [Range(0, 9_999_999_999.99)] decimal UnitPrice,
    [Range(0.001, 99_999_999.999)] decimal Quantity,
    [MaxLength(500)] string? Notes
);

public record SalesOrderItemResponse(
    Guid Id,
    Guid? ProductId,
    string Description,
    decimal UnitPrice,
    decimal Quantity,
    decimal LineTotal,
    string? Notes
);

// ─── Devis / Commande ────────────────────────────────────────────────────────

public record CreateSalesOrderRequest(
    [Required] Guid ClientId,
    [MaxLength(3)] string? Currency,
    [Range(0, 9_999_999_999.99)] decimal TaxAmount,
    [MaxLength(2000)] string? Notes,
    DateTime? ExpiresAt,
    [MinLength(1, ErrorMessage = "Au moins une ligne est requise.")] List<CreateSalesOrderItemRequest> Items
);

public record UpdateSalesOrderRequest(
    [Required] Guid ClientId,
    [MaxLength(3)] string? Currency,
    [Range(0, 9_999_999_999.99)] decimal TaxAmount,
    [MaxLength(2000)] string? Notes,
    DateTime? ExpiresAt,
    [MinLength(1)] List<CreateSalesOrderItemRequest> Items
);

public record TransitionSalesOrderRequest(
    [Required] SalesOrderStatus NewStatus,
    [MaxLength(500)] string? Reason
);

public record SalesOrderResponse(
    Guid Id,
    string OrderNumber,
    SalesOrderStatus Status,
    string StatusLabel,
    Guid ClientId,
    string ClientName,
    string Currency,
    decimal Subtotal,
    decimal TaxAmount,
    decimal Total,
    string? Notes,
    DateTime? ExpiresAt,
    DateTime? SentAt,
    DateTime? AcceptedAt,
    DateTime? DeliveredAt,
    DateTime? PaidAt,
    DateTime? CancelledAt,
    string? CancellationReason,
    DateTime CreatedAt,
    DateTime? UpdatedAt,
    IEnumerable<SalesOrderItemResponse> Items,
    IEnumerable<SalesOrderStatus> AllowedNextStatuses
);

public record SalesOrderListItem(
    Guid Id,
    string OrderNumber,
    SalesOrderStatus Status,
    string StatusLabel,
    Guid ClientId,
    string ClientName,
    string Currency,
    decimal Total,
    DateTime CreatedAt
);

public record SalesOrderListResponse(
    IEnumerable<SalesOrderListItem> Items,
    int Total,
    int Page,
    int PageSize
);
