using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Technical.DTOs;

// ✅ CRÉER REQUEST
public record CreateTechnicalQuoteRequest(
    [Required] Guid ClientId,
    [Required, MaxLength(200)] string Title,
    [MaxLength(1000)] string? Description,
    [MaxLength(200)] string? ServiceLocation,
    [Range(0, 10_000)] decimal EstimatedHours,
    [Range(0, 999_999)] decimal HourlyRate,
    List<CreateTechnicalQuoteItemRequest>? Items = null
);

// ✅ ITEM REQUEST (renommé pour cohérence)
public record CreateTechnicalQuoteItemRequest(
    [Required, MaxLength(150)] string ItemName,
    [MaxLength(50)] string ItemType = "Material",
    [Range(0, 10_000)] decimal Quantity = 1,
    [MaxLength(20)] string Unit = "pcs",
    [Range(0, 999_999)] decimal UnitPrice = 0
);

// ✅ UPDATE REQUEST
public record UpdateTechnicalQuoteRequest(
    [Required, MaxLength(200)] string Title,
    [MaxLength(1000)] string? Description,
    [Range(0, 10_000)] decimal EstimatedHours,
    [Range(0, 999_999)] decimal HourlyRate
);

// ✅ RESPONSE
public record TechnicalQuoteResponse(
    Guid Id,
    string QuoteNumber,
    string Title,
    string? Description,
    string? ServiceLocation,
    Guid ClientId,
    string ClientName,
    decimal EstimatedHours,
    decimal HourlyRate,
    decimal MaterialsCost,
    decimal LaborCost,
    decimal Total,
    string Currency,
    DateTime? ValidUntil,
    string Status,
    DateTime? SentAt,
    DateTime? AcceptedAt,
    int ItemCount,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

// ✅ LIST RESPONSE
public record TechnicalQuoteListResponse(
    IEnumerable<TechnicalQuoteResponse> Items,
    int Total,
    int AcceptedCount,
    int Page,
    int PageSize
);

// ✅ ITEM RESPONSE
public record TechnicalQuoteItemResponse(
    Guid Id,
    string ItemName,
    string ItemType,
    decimal Quantity,
    string Unit,
    decimal UnitPrice,
    decimal Total
);