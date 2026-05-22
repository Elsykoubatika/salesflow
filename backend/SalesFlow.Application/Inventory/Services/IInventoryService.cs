using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Inventory.DTOs;
using SalesFlow.Domain.Enums;
namespace SalesFlow.Application.Inventory.Services;

public interface IInventoryService
{
    // ===== Items =====
    /// <summary>Liste paginée des articles en stock.</summary>
    Task<Result<InventoryListResponse>> ListItemsAsync(
        int page = 1,
        int pageSize = 20,
        bool lowStockOnly = false,
        CancellationToken ct = default
    );

    /// <summary>Récupère un article en stock par ID.</summary>
    Task<Result<InventoryItemResponse>> GetItemByIdAsync(Guid id, CancellationToken ct = default);

    /// <summary>Crée un nouvel article en stock.</summary>
    Task<Result<InventoryItemResponse>> CreateItemAsync(
        CreateInventoryItemRequest request,
        CancellationToken ct = default
    );

    /// <summary>Met à jour un article en stock (pas de modification directe de Quantity).</summary>
    Task<Result<InventoryItemResponse>> UpdateItemAsync(
        Guid id,
        UpdateInventoryItemRequest request,
        CancellationToken ct = default
    );

    /// <summary>Supprime un article en stock.</summary>
    Task<Result<bool>> DeleteItemAsync(Guid id, CancellationToken ct = default);

    // ===== Movements =====

    /// <summary>Enregistre un mouvement de stock (entrée ou sortie).</summary>
    Task<Result<InventoryMovementResponse>> RecordMovementAsync(
        CreateInventoryMovementRequest request,
        CancellationToken ct = default
    );

    /// <summary>Liste tous les mouvements d'un article.</summary>
    Task<Result<InventoryMovementListResponse>> GetMovementsAsync(
        Guid inventoryItemId,
        CancellationToken ct = default
    );

    /// <summary>Récupère les articles en stock faible (Quantity ≤ ReorderThreshold).</summary>
    Task<Result<IEnumerable<InventoryItemResponse>>> GetLowStockItemsAsync(
        CancellationToken ct = default
    );

    /// <summary>Récupère la valeur totale du stock (∑ Cost × Quantity).</summary>
    Task<Result<decimal>> GetTotalStockValueAsync(CancellationToken ct = default);
}