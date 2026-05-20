using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Inventory.DTOs;

namespace SalesFlow.Application.Inventory.Services;

public interface IInventoryService
{
    Task<Result<InventoryListResponse>> ListAsync(
        int page, int pageSize, string? search, bool? lowStockOnly, bool? activeOnly,
        CancellationToken ct = default);

    Task<Result<InventoryItemDetailResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<InventoryItemResponse>> CreateAsync(CreateInventoryItemRequest request, CancellationToken ct = default);

    Task<Result<InventoryItemResponse>> UpdateAsync(Guid id, UpdateInventoryItemRequest request, CancellationToken ct = default);

    /// <summary>
    /// Modifie la quantité par delta. Crée un mouvement traçable.
    /// Refuse si delta négatif rendrait le stock négatif (stock négatif interdit).
    /// </summary>
    Task<Result<InventoryItemResponse>> AdjustAsync(Guid id, AdjustInventoryRequest request, CancellationToken ct = default);

    Task<Result<bool>> SoftDeleteAsync(Guid id, CancellationToken ct = default);
}
