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
    private const int RecentMovementsLimit = 20;

    public InventoryService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    // ─── Listing ─────────────────────────────────────────────────────────────

    public async Task<Result<InventoryListResponse>> ListAsync(
        int page, int pageSize, string? search, bool? lowStockOnly, bool? activeOnly,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        page = page < 1 ? 1 : page;
        pageSize = pageSize switch { < 1 => DefaultPageSize, > MaxPageSize => MaxPageSize, _ => pageSize };

        var query = _db.InventoryItems.AsNoTracking().Where(i => i.UserId == userId);

        if (activeOnly == true)
            query = query.Where(i => i.IsActive);

        if (lowStockOnly == true)
            query = query.Where(i => i.ReorderThreshold.HasValue && i.Quantity <= i.ReorderThreshold.Value);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(i =>
                i.Name.ToLower().Contains(s) ||
                (i.Sku != null && i.Sku.ToLower().Contains(s)) ||
                (i.Description != null && i.Description.ToLower().Contains(s))
            );
        }

        var total = await query.CountAsync(ct);

        // Compteur global d'alertes (avant pagination)
        var lowStockCount = await _db.InventoryItems
            .AsNoTracking()
            .Where(i => i.UserId == userId && i.IsActive && i.ReorderThreshold.HasValue && i.Quantity <= i.ReorderThreshold.Value)
            .CountAsync(ct);

        var items = await query
            .OrderBy(i => i.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        var responses = items.Select(MapList);

        return Result<InventoryListResponse>.Success(
            new InventoryListResponse(responses, total, page, pageSize, lowStockCount));
    }

    // ─── Détail avec historique ──────────────────────────────────────────────

    public async Task<Result<InventoryItemDetailResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var item = await _db.InventoryItems.AsNoTracking()
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (item is null)
            return Result<InventoryItemDetailResponse>.Failure("Article introuvable.");

        var movements = await _db.InventoryMovements.AsNoTracking()
            .Where(m => m.InventoryItemId == id)
            .OrderByDescending(m => m.CreatedAt)
            .Take(RecentMovementsLimit)
            .Select(m => new InventoryMovementResponse(
                m.Id, m.Change, m.Reason, m.Reason.ToString(), m.ResultingQuantity, m.Note, m.SalesOrderId, m.CreatedAt))
            .ToListAsync(ct);

        return Result<InventoryItemDetailResponse>.Success(MapDetail(item, movements));
    }

    // ─── Création ────────────────────────────────────────────────────────────

    public async Task<Result<InventoryItemResponse>> CreateAsync(CreateInventoryItemRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // Si lien produit, vérifier qu'il appartient au user
        if (request.ProductId.HasValue)
        {
            var productExists = await _db.Products
                .AnyAsync(p => p.Id == request.ProductId && p.UserId == userId, ct);
            if (!productExists)
                return Result<InventoryItemResponse>.Failure("Produit lié introuvable.");
        }

        var item = new InventoryItem
        {
            UserId = userId,
            Name = request.Name.Trim(),
            Sku = request.Sku?.Trim(),
            Description = request.Description?.Trim(),
            Unit = string.IsNullOrWhiteSpace(request.Unit) ? "pcs" : request.Unit.Trim(),
            Quantity = request.InitialQuantity,
            ReorderThreshold = request.ReorderThreshold,
            Cost = request.Cost,
            ProductId = request.ProductId,
            IsActive = true
        };

        // Mouvement initial pour traçabilité
        if (request.InitialQuantity > 0)
        {
            item.LastMovementAt = DateTime.UtcNow;
            item.Movements.Add(new InventoryMovement
            {
                Change = request.InitialQuantity,
                Reason = MovementReason.InitialStock,
                ResultingQuantity = request.InitialQuantity,
                Note = "Stock initial à la création"
            });
        }

        _db.InventoryItems.Add(item);
        await _db.SaveChangesAsync(ct);

        return Result<InventoryItemResponse>.Success(MapList(item));
    }

    // ─── Modification (sans toucher à la quantité) ───────────────────────────

    public async Task<Result<InventoryItemResponse>> UpdateAsync(Guid id, UpdateInventoryItemRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var item = await _db.InventoryItems
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (item is null)
            return Result<InventoryItemResponse>.Failure("Article introuvable.");

        if (request.ProductId.HasValue && request.ProductId != item.ProductId)
        {
            var productExists = await _db.Products
                .AnyAsync(p => p.Id == request.ProductId && p.UserId == userId, ct);
            if (!productExists)
                return Result<InventoryItemResponse>.Failure("Produit lié introuvable.");
        }

        item.Name = request.Name.Trim();
        item.Sku = request.Sku?.Trim();
        item.Description = request.Description?.Trim();
        item.Unit = string.IsNullOrWhiteSpace(request.Unit) ? item.Unit : request.Unit.Trim();
        item.ReorderThreshold = request.ReorderThreshold;
        item.Cost = request.Cost;
        item.ProductId = request.ProductId;

        await _db.SaveChangesAsync(ct);
        return Result<InventoryItemResponse>.Success(MapList(item));
    }

    // ─── Ajustement de quantité (génère un mouvement) ────────────────────────

    public async Task<Result<InventoryItemResponse>> AdjustAsync(Guid id, AdjustInventoryRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var item = await _db.InventoryItems
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (item is null)
            return Result<InventoryItemResponse>.Failure("Article introuvable.");

        if (!item.IsActive)
            return Result<InventoryItemResponse>.Failure("Article désactivé — réactiver avant d'ajuster.");

        if (request.Delta == 0)
            return Result<InventoryItemResponse>.Failure("Le delta ne peut pas être nul.");

        var newQuantity = item.Quantity + request.Delta;
        if (newQuantity < 0)
            return Result<InventoryItemResponse>.Failure(
                $"Stock négatif interdit. Quantité actuelle : {item.Quantity}. Delta demandé : {request.Delta}.");

        item.Quantity = newQuantity;
        item.LastMovementAt = DateTime.UtcNow;

        _db.InventoryMovements.Add(new InventoryMovement
        {
            InventoryItemId = item.Id,
            Change = request.Delta,
            Reason = request.Reason,
            ResultingQuantity = newQuantity,
            Note = request.Note?.Trim()
        });

        await _db.SaveChangesAsync(ct);
        return Result<InventoryItemResponse>.Success(MapList(item));
    }

    // ─── Soft delete (préserve historique) ───────────────────────────────────

    public async Task<Result<bool>> SoftDeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var item = await _db.InventoryItems
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (item is null)
            return Result<bool>.Failure("Article introuvable.");

        item.IsActive = false;
        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");

    private static InventoryItemResponse MapList(InventoryItem i) => new(
        i.Id, i.Name, i.Sku, i.Description, i.Unit,
        i.Quantity, i.ReorderThreshold, i.Cost, i.StockValue, i.IsLowStock,
        i.ProductId, i.LastMovementAt, i.IsActive, i.CreatedAt, i.UpdatedAt
    );

    private static InventoryItemDetailResponse MapDetail(InventoryItem i, IEnumerable<InventoryMovementResponse> movements) => new(
        i.Id, i.Name, i.Sku, i.Description, i.Unit,
        i.Quantity, i.ReorderThreshold, i.Cost, i.StockValue, i.IsLowStock,
        i.ProductId, i.LastMovementAt, i.IsActive, i.CreatedAt, i.UpdatedAt,
        movements
    );
}
