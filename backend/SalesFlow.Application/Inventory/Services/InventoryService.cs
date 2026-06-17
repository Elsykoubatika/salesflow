using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Inventory.DTOs;
using SalesFlow.Domain.Entities;
using SalesFlow.Domain.Enums;
namespace SalesFlow.Application.Inventory.Services;

public class InventoryService : IInventoryService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public InventoryService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    // ===== Items =====

    public async Task<Result<InventoryListResponse>> ListItemsAsync(
        int page = 1,
        int pageSize = 20,
        bool lowStockOnly = false,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        page = page < 1 ? 1 : page;
        pageSize = pageSize switch
        {
            < 1 => DefaultPageSize,
            > MaxPageSize => MaxPageSize,
            _ => pageSize
        };

        var query = _db.InventoryItems.AsNoTracking()
            .Where(i => i.UserId == userId && i.IsActive)
            .Include(i => i.Product)
            .Include(i => i.Movements);

        if (lowStockOnly)
            query = (Microsoft.EntityFrameworkCore.Query.IIncludableQueryable<InventoryItem, ICollection<InventoryMovement>>)query.Where(i => i.ReorderThreshold.HasValue && i.Quantity <= i.ReorderThreshold.Value);

        var total = await query.CountAsync(ct);

        var lowStockCount = await _db.InventoryItems.AsNoTracking()
            .Where(i => i.UserId == userId && i.IsActive &&
                       i.ReorderThreshold.HasValue && i.Quantity <= i.ReorderThreshold.Value)
            .CountAsync(ct);

        var items = await query
            .OrderByDescending(i => i.ReorderThreshold > 0 && i.Quantity <= i.ReorderThreshold)
            .ThenBy(i => i.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(i => MapItem(i))
            .ToListAsync(ct);

        return Result<InventoryListResponse>.Success(
            new InventoryListResponse(items, total, lowStockCount, page, pageSize)
        );
    }

    public async Task<Result<InventoryItemResponse>> GetItemByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var item = await _db.InventoryItems.AsNoTracking()
            .Include(i => i.Product)
            .Include(i => i.Movements)
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        return item is null
            ? Result<InventoryItemResponse>.Failure("Article en stock introuvable.")
            : Result<InventoryItemResponse>.Success(MapItem(item));
    }

    public async Task<Result<InventoryItemResponse>> CreateItemAsync(
        CreateInventoryItemRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // Vérifier que ProductId existe si fourni
        if (request.ProductId.HasValue)
        {
            var productExists = await _db.Products.AsNoTracking()
                .AnyAsync(p => p.Id == request.ProductId && p.UserId == userId, ct);

            if (!productExists)
                return Result<InventoryItemResponse>.Failure("Produit introuvable.");
        }

        var item = new InventoryItem
        {
            UserId = userId,
            Name = request.Name.Trim(),
            Sku = request.Sku?.Trim(),
            Description = request.Description?.Trim(),
            Unit = request.Unit,
            Quantity = request.InitialQuantity,
            ReorderThreshold = request.ReorderThreshold,
            Cost = request.Cost,
            ProductId = request.ProductId,
            IsActive = true
        };

        _db.InventoryItems.Add(item);

        // ✅ Si InitialQuantity > 0, enregistrer un mouvement d'entrée initiale
        if (request.InitialQuantity > 0)
        {
            var initialMovement = new InventoryMovement
            {
                InventoryItemId = item.Id,
                Change = request.InitialQuantity,
                Reason = MovementReason.InitialStock,
                ResultingQuantity = request.InitialQuantity,
                Note = "Stock initial"
            };

            _db.InventoryMovements.Add(initialMovement);
            item.LastMovementAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync(ct);

        return await GetItemByIdAsync(item.Id, ct);
    }

    public async Task<Result<InventoryItemResponse>> UpdateItemAsync(
        Guid id,
        UpdateInventoryItemRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var item = await _db.InventoryItems
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (item is null)
            return Result<InventoryItemResponse>.Failure("Article en stock introuvable.");

        item.Name = request.Name.Trim();
        item.Description = request.Description?.Trim();
        item.ReorderThreshold = request.ReorderThreshold;
        item.Cost = request.Cost;
        item.IsActive = request.IsActive;

        await _db.SaveChangesAsync(ct);

        return await GetItemByIdAsync(id, ct);
    }

    public async Task<Result<bool>> DeleteItemAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var item = await _db.InventoryItems
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (item is null)
            return Result<bool>.Failure("Article en stock introuvable.");

        _db.InventoryItems.Remove(item);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    // ===== Movements =====

    public async Task<Result<InventoryMovementResponse>> RecordMovementAsync(
        CreateInventoryMovementRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // ✅ Vérifier que l'article existe et appartient à l'utilisateur
        var item = await _db.InventoryItems
            .FirstOrDefaultAsync(i => i.Id == request.InventoryItemId && i.UserId == userId, ct);

        if (item is null)
            return Result<InventoryMovementResponse>.Failure("Article en stock introuvable.");

        // ✅ Vérifier que la nouvelle quantité ne devient pas négative
        var newQuantity = item.Quantity + request.Change;
        if (newQuantity < 0)
            return Result<InventoryMovementResponse>.Failure(
                $"Stock insuffisant. Quantité actuelle: {item.Quantity}, tentative de retrait: {Math.Abs(request.Change)}"
            );

        // ✅ Vérifier que SalesOrderId existe si fourni
        if (request.SalesOrderId.HasValue)
        {
            var orderExists = await _db.SalesOrders.AsNoTracking()
                .AnyAsync(o => o.Id == request.SalesOrderId && o.UserId == userId, ct);

            if (!orderExists)
                return Result<InventoryMovementResponse>.Failure("Commande introuvable.");
        }

        // ✅ Créer le mouvement
        var movement = new InventoryMovement
        {
            InventoryItemId = request.InventoryItemId,
            Change = request.Change,
            Reason = request.Reason,
            ResultingQuantity = newQuantity,
            Note = request.Note?.Trim(),
            SalesOrderId = request.SalesOrderId
        };

        // ✅ Mettre à jour la quantité et LastMovementAt
        item.Quantity = newQuantity;
        item.LastMovementAt = DateTime.UtcNow;

        _db.InventoryMovements.Add(movement);
        await _db.SaveChangesAsync(ct);

        return Result<InventoryMovementResponse>.Success(new InventoryMovementResponse(
            movement.Id,
            movement.InventoryItemId,
            item.Name,
            movement.Change,
            movement.Reason.ToString(),
            movement.ResultingQuantity,
            movement.Note,
            movement.SalesOrderId,
            movement.CreatedAt
        ));
    }

    public async Task<Result<InventoryMovementListResponse>> GetMovementsAsync(
        Guid inventoryItemId,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // ✅ Vérifier que l'article existe et appartient à l'utilisateur
        var item = await _db.InventoryItems.AsNoTracking()
            .FirstOrDefaultAsync(i => i.Id == inventoryItemId && i.UserId == userId, ct);

        if (item is null)
            return Result<InventoryMovementListResponse>.Failure("Article en stock introuvable.");

        // ✅ Récupérer tous les mouvements (triés par date décroissante)
        var movements = await _db.InventoryMovements.AsNoTracking()
            .Where(m => m.InventoryItemId == inventoryItemId)
            .OrderByDescending(m => m.CreatedAt)
            .Select(m => new InventoryMovementResponse(
                m.Id,
                m.InventoryItemId,
                item.Name,
                m.Change,
                m.Reason.ToString(),
                m.ResultingQuantity,
                m.Note,
                m.SalesOrderId,
                m.CreatedAt
            ))
            .ToListAsync(ct);

        return Result<InventoryMovementListResponse>.Success(
            new InventoryMovementListResponse(inventoryItemId, item.Name, movements, movements.Count)
        );
    }

    public async Task<Result<IEnumerable<InventoryItemResponse>>> GetLowStockItemsAsync(
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var items = await _db.InventoryItems.AsNoTracking()
            .Where(i => i.UserId == userId && i.IsActive &&
                       i.ReorderThreshold.HasValue && i.Quantity <= i.ReorderThreshold.Value)
            .Include(i => i.Product)
            .Include(i => i.Movements)
            .OrderBy(i => i.Quantity) // Articles les plus critiques en premier
            .Select(i => MapItem(i))
            .ToListAsync(ct);

        return Result<IEnumerable<InventoryItemResponse>>.Success(items);
    }

    public async Task<Result<decimal>> GetTotalStockValueAsync(CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var totalValue = await _db.InventoryItems.AsNoTracking()
            .Where(i => i.UserId == userId && i.IsActive && i.Cost.HasValue)
            .SumAsync(i => i.Cost!.Value * i.Quantity, ct);

        return Result<decimal>.Success(totalValue);
    }

    // ===== Helpers =====

    private static InventoryItemResponse MapItem(InventoryItem i) => new(
        i.Id,
        i.Name,
        i.Sku,
        i.Description,
        i.Unit,
        i.Quantity,
        i.ReorderThreshold,
        i.Cost,
        i.IsLowStock,
        i.StockValue,
        i.Product?.Name,
        i.LastMovementAt,
        i.IsActive,
        i.Movements?.Count ?? 0,
        i.CreatedAt,
        i.UpdatedAt
    );

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}