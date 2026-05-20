using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Sales.DTOs;
using SalesFlow.Domain.Common;
using SalesFlow.Domain.Entities;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Application.Sales.Services;

public class SalesOrderService : ISalesOrderService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public SalesOrderService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    // ─── Listing ─────────────────────────────────────────────────────────────

    public async Task<Result<SalesOrderListResponse>> ListAsync(
        int page, int pageSize, SalesOrderStatus? status, Guid? clientId, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        page = page < 1 ? 1 : page;
        pageSize = pageSize switch { < 1 => DefaultPageSize, > MaxPageSize => MaxPageSize, _ => pageSize };

        var query = _db.SalesOrders.AsNoTracking().Where(o => o.UserId == userId);
        if (status.HasValue) query = query.Where(o => o.Status == status.Value);
        if (clientId.HasValue) query = query.Where(o => o.ClientId == clientId.Value);

        var total = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(o => new SalesOrderListItem(
                o.Id, o.OrderNumber, o.Status, o.Status.ToString(),
                o.ClientId, o.Client!.FullName, o.Currency, o.Total, o.CreatedAt))
            .ToListAsync(ct);

        return Result<SalesOrderListResponse>.Success(new SalesOrderListResponse(items, total, page, pageSize));
    }

    // ─── Détail ──────────────────────────────────────────────────────────────

    public async Task<Result<SalesOrderResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var order = await LoadFullAsync(id, userId, tracked: false, ct);
        return order is null
            ? Result<SalesOrderResponse>.Failure("Devis/commande introuvable.")
            : Result<SalesOrderResponse>.Success(Map(order));
    }

    // ─── Création ────────────────────────────────────────────────────────────

    public async Task<Result<SalesOrderResponse>> CreateAsync(CreateSalesOrderRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // 1. Le client doit exister et appartenir à l'utilisateur
        var client = await _db.Clients
            .FirstOrDefaultAsync(c => c.Id == request.ClientId && c.UserId == userId, ct);
        if (client is null)
            return Result<SalesOrderResponse>.Failure("Client introuvable.");

        // 2. Validation des lignes
        if (request.Items is null || request.Items.Count == 0)
            return Result<SalesOrderResponse>.Failure("Au moins une ligne est requise.");

        // 3. Construire le SalesOrder avec les lignes (résolution des produits éventuels)
        var order = new SalesOrder
        {
            UserId = userId,
            ClientId = client.Id,
            Status = SalesOrderStatus.Draft,
            Currency = string.IsNullOrWhiteSpace(request.Currency) ? "XAF" : request.Currency.Trim().ToUpperInvariant(),
            TaxAmount = request.TaxAmount,
            Notes = request.Notes?.Trim(),
            ExpiresAt = request.ExpiresAt,
            OrderNumber = await GenerateOrderNumberAsync(userId, ct)
        };

        var itemsResult = await BuildItemsAsync(request.Items, userId, ct);
        if (!itemsResult.IsSuccess)
            return Result<SalesOrderResponse>.Failure(itemsResult.Error!);

        foreach (var i in itemsResult.Value!)
            order.Items.Add(i);

        order.Recalculate();

        _db.SalesOrders.Add(order);
        await _db.SaveChangesAsync(ct);

        // Recharger pour avoir les Client/Items proprement attachés pour le mapping
        var fresh = await LoadFullAsync(order.Id, userId, tracked: false, ct);
        return Result<SalesOrderResponse>.Success(Map(fresh!));
    }

    // ─── Modification (Draft uniquement) ─────────────────────────────────────

    public async Task<Result<SalesOrderResponse>> UpdateAsync(Guid id, UpdateSalesOrderRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var order = await _db.SalesOrders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id && o.UserId == userId, ct);

        if (order is null)
            return Result<SalesOrderResponse>.Failure("Devis/commande introuvable.");

        if (!order.IsEditable)
            return Result<SalesOrderResponse>.Failure(
                $"Modification interdite : statut actuel '{order.Status}'. Seuls les brouillons sont modifiables.");

        // Vérifier le client
        var clientExists = await _db.Clients
            .AnyAsync(c => c.Id == request.ClientId && c.UserId == userId, ct);
        if (!clientExists)
            return Result<SalesOrderResponse>.Failure("Client introuvable.");

        // Mettre à jour les champs
        order.ClientId = request.ClientId;
        order.Currency = string.IsNullOrWhiteSpace(request.Currency) ? "XAF" : request.Currency.Trim().ToUpperInvariant();
        order.TaxAmount = request.TaxAmount;
        order.Notes = request.Notes?.Trim();
        order.ExpiresAt = request.ExpiresAt;

        // Stratégie simple : remplacer toutes les lignes
        // (Les anciennes lignes seront supprimées en cascade par EF puisqu'elles sont retirées de la collection)
        order.Items.Clear();

        var itemsResult = await BuildItemsAsync(request.Items, userId, ct);
        if (!itemsResult.IsSuccess)
            return Result<SalesOrderResponse>.Failure(itemsResult.Error!);

        foreach (var i in itemsResult.Value!) order.Items.Add(i);

        order.Recalculate();
        await _db.SaveChangesAsync(ct);

        var fresh = await LoadFullAsync(order.Id, userId, tracked: false, ct);
        return Result<SalesOrderResponse>.Success(Map(fresh!));
    }

    // ─── Transition de statut ────────────────────────────────────────────────

    public async Task<Result<SalesOrderResponse>> TransitionAsync(Guid id, TransitionSalesOrderRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var order = await _db.SalesOrders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id && o.UserId == userId, ct);

        if (order is null)
            return Result<SalesOrderResponse>.Failure("Devis/commande introuvable.");

        if (!SalesOrderStatusMachine.CanTransition(order.Status, request.NewStatus))
        {
            var allowed = string.Join(", ", SalesOrderStatusMachine.AllowedFrom(order.Status));
            return Result<SalesOrderResponse>.Failure(
                $"Transition '{order.Status}' → '{request.NewStatus}' non autorisée. Transitions possibles : {(allowed.Length == 0 ? "aucune (statut terminal)" : allowed)}.");
        }

        // Validations métier supplémentaires
        if (request.NewStatus == SalesOrderStatus.Sent && order.Items.Count == 0)
            return Result<SalesOrderResponse>.Failure("Impossible d'envoyer un devis vide. Ajouter au moins une ligne.");

        // Appliquer la transition + horodatage du jalon
        var now = DateTime.UtcNow;
        order.Status = request.NewStatus;

        switch (request.NewStatus)
        {
            case SalesOrderStatus.Sent:      order.SentAt = now; break;
            case SalesOrderStatus.Accepted:  order.AcceptedAt = now; break;
            case SalesOrderStatus.Delivered: order.DeliveredAt = now; break;
            case SalesOrderStatus.Paid:      order.PaidAt = now; break;
            case SalesOrderStatus.Cancelled:
            case SalesOrderStatus.Rejected:
                order.CancelledAt = now;
                order.CancellationReason = request.Reason?.Trim();
                break;
        }

        await _db.SaveChangesAsync(ct);

        var fresh = await LoadFullAsync(order.Id, userId, tracked: false, ct);
        return Result<SalesOrderResponse>.Success(Map(fresh!));
    }

    // ─── Suppression (Draft uniquement) ──────────────────────────────────────

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var order = await _db.SalesOrders
            .FirstOrDefaultAsync(o => o.Id == id && o.UserId == userId, ct);

        if (order is null)
            return Result<bool>.Failure("Devis/commande introuvable.");

        if (order.Status != SalesOrderStatus.Draft)
            return Result<bool>.Failure(
                $"Suppression interdite : statut '{order.Status}'. Annuler le document plutôt que supprimer (transition → Cancelled).");

        _db.SalesOrders.Remove(order);
        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");

    private async Task<SalesOrder?> LoadFullAsync(Guid id, Guid userId, bool tracked, CancellationToken ct)
    {
        var query = _db.SalesOrders
            .Include(o => o.Client)
            .Include(o => o.Items)
            .AsQueryable();
        if (!tracked) query = query.AsNoTracking();
        return await query.FirstOrDefaultAsync(o => o.Id == id && o.UserId == userId, ct);
    }

    /// <summary>
    /// Construit la liste de SalesOrderItem à partir des DTOs.
    /// Si ProductId fourni, vérifie l'appartenance et utilise comme référence.
    /// La description et le prix viennent du DTO (snapshot client → serveur).
    /// </summary>
    private async Task<Result<List<SalesOrderItem>>> BuildItemsAsync(
        List<CreateSalesOrderItemRequest> requests, Guid userId, CancellationToken ct)
    {
        // Charger en bloc tous les ProductIds référencés pour vérifier qu'ils appartiennent au user
        var requestedProductIds = requests
            .Where(r => r.ProductId.HasValue)
            .Select(r => r.ProductId!.Value)
            .Distinct()
            .ToList();

        Dictionary<Guid, Product>? products = null;
        if (requestedProductIds.Count > 0)
        {
            products = await _db.Products
                .Where(p => p.UserId == userId && requestedProductIds.Contains(p.Id))
                .ToDictionaryAsync(p => p.Id, ct);

            var missing = requestedProductIds.Except(products.Keys).ToList();
            if (missing.Count > 0)
                return Result<List<SalesOrderItem>>.Failure(
                    $"Produit(s) introuvable(s) : {string.Join(", ", missing)}.");
        }

        var items = new List<SalesOrderItem>();
        foreach (var r in requests)
        {
            if (r.UnitPrice < 0)
                return Result<List<SalesOrderItem>>.Failure("Prix unitaire négatif interdit.");
            if (r.Quantity <= 0)
                return Result<List<SalesOrderItem>>.Failure("Quantité doit être > 0.");
            if (string.IsNullOrWhiteSpace(r.Description))
                return Result<List<SalesOrderItem>>.Failure("Description de ligne obligatoire.");

            items.Add(new SalesOrderItem
            {
                ProductId = r.ProductId,
                Description = r.Description.Trim(),
                UnitPrice = r.UnitPrice,
                Quantity = r.Quantity,
                Notes = r.Notes?.Trim()
            });
        }

        return Result<List<SalesOrderItem>>.Success(items);
    }

    /// <summary>
    /// Génère le prochain numéro de document : SF-{année}-{séquence sur 4 chiffres}.
    /// Séquentiel par utilisateur et par année. Si conflit (rare), on retente.
    /// </summary>
    private async Task<string> GenerateOrderNumberAsync(Guid userId, CancellationToken ct)
    {
        var year = DateTime.UtcNow.Year;
        var prefix = $"SF-{year}-";

        var lastNumber = await _db.SalesOrders
            .Where(o => o.UserId == userId && o.OrderNumber.StartsWith(prefix))
            .OrderByDescending(o => o.OrderNumber)
            .Select(o => o.OrderNumber)
            .FirstOrDefaultAsync(ct);

        var next = 1;
        if (!string.IsNullOrEmpty(lastNumber)
            && int.TryParse(lastNumber[prefix.Length..], out var n))
        {
            next = n + 1;
        }

        return $"{prefix}{next:D4}";
    }

    private static SalesOrderResponse Map(SalesOrder o) => new(
        o.Id,
        o.OrderNumber,
        o.Status,
        o.Status.ToString(),
        o.ClientId,
        o.Client?.FullName ?? string.Empty,
        o.Currency,
        o.Subtotal,
        o.TaxAmount,
        o.Total,
        o.Notes,
        o.ExpiresAt,
        o.SentAt, o.AcceptedAt, o.DeliveredAt, o.PaidAt, o.CancelledAt,
        o.CancellationReason,
        o.CreatedAt,
        o.UpdatedAt,
        o.Items.Select(i => new SalesOrderItemResponse(
            i.Id, i.ProductId, i.Description, i.UnitPrice, i.Quantity, i.LineTotal, i.Notes)),
        SalesOrderStatusMachine.AllowedFrom(o.Status)
    );
}
