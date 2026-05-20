using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Catalog.DTOs;

public record CreateProductRequest(
    [Required, MaxLength(150)] string Name,
    [MaxLength(2000)] string? Description,
    [Range(0, 9_999_999_999.99)] decimal Price,
    [MaxLength(3)] string? Currency,
    [MaxLength(50)] string? Sku,
    [MaxLength(500)] string? ImageUrl,
    string? VariantsJson
);

public record UpdateProductRequest(
    [Required, MaxLength(150)] string Name,
    [MaxLength(2000)] string? Description,
    [Range(0, 9_999_999_999.99)] decimal Price,
    [MaxLength(3)] string? Currency,
    [MaxLength(50)] string? Sku,
    [MaxLength(500)] string? ImageUrl,
    string? VariantsJson,
    bool IsActive
);

public record ProductResponse(
    Guid Id,
    string Name,
    string? Description,
    decimal Price,
    string Currency,
    string? Sku,
    string? ImageUrl,
    string? VariantsJson,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record ProductListResponse(
    IEnumerable<ProductResponse> Items,
    int Total,
    int Page,
    int PageSize
);

/// <summary>
/// Lien WhatsApp pré-rempli pour un produit. Le marchand le partage à ses clients.
/// </summary>
public record WhatsAppLinkResponse(
    string Url,
    string PhoneNumber,
    string Message
);
