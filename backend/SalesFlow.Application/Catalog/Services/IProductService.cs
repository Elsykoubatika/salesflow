using SalesFlow.Application.Catalog.DTOs;
using SalesFlow.Application.Common.Models;

namespace SalesFlow.Application.Catalog.Services;

public interface IProductService
{
    Task<Result<ProductListResponse>> ListAsync(int page, int pageSize, string? search, bool? activeOnly, CancellationToken ct = default);
    Task<Result<ProductResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Result<ProductResponse>> CreateAsync(CreateProductRequest request, CancellationToken ct = default);
    Task<Result<ProductResponse>> UpdateAsync(Guid id, UpdateProductRequest request, CancellationToken ct = default);
    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);

    /// <summary>
    /// Génère un lien wa.me pré-rempli pour partager le produit via WhatsApp.
    /// </summary>
    Task<Result<WhatsAppLinkResponse>> GenerateWhatsAppLinkAsync(Guid productId, string? customMessage, CancellationToken ct = default);
}
