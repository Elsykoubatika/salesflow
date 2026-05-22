using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Proofs.DTOs;
using SalesFlow.Domain.Entities;
using SalesFlow.Domain.Enums;
namespace SalesFlow.Application.Proofs.Services;

public class ProofService : IProofService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;
    private const int MaxImageSizeBytes = 5 * 1024 * 1024; // 5 MB

    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
{
    "image/jpeg", "image/jpg", "image/png", "image/webp"
};

    public ProofService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<ProofListResponse>> ListAsync(
        int page = 1,
        int pageSize = 20,
        ProofStatus? status = null,
        Guid? clientId = null,
        Guid? salesOrderId = null,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // Sanitize pagination
        page = page < 1 ? 1 : page;
        pageSize = pageSize switch
        {
            < 1 => DefaultPageSize,
            > MaxPageSize => MaxPageSize,
            _ => pageSize
        };

        // ✅ Base query SANS charger ImageBytes (très important pour la perf!)
        var query = _db.Proofs.AsNoTracking()
            .Where(p => p.UserId == userId);

        // Appliquer filtres optionnels
        if (status.HasValue)
            query = query.Where(p => p.Status == status.Value);

        if (clientId.HasValue)
            query = query.Where(p => p.ClientId == clientId.Value);

        if (salesOrderId.HasValue)
            query = query.Where(p => p.SalesOrderId == salesOrderId.Value);

        var total = await query.CountAsync(ct);

        var pendingCount = await _db.Proofs.AsNoTracking()
            .Where(p => p.UserId == userId && p.Status == ProofStatus.Pending)
            .CountAsync(ct);

        // ✅ Projection explicite pour exclure ImageBytes du transfert réseau
        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new
            {
                p.Id,
                p.ImageContentType,
                p.ImageSizeBytes,
                p.Amount,
                p.Currency,
                p.TransactionReference,
                p.Operator,
                p.TransactionDate,
                p.Notes,
                p.Status,
                p.ErrorMessage,
                p.ClientId,
                ClientName = p.Client != null ? p.Client.FullName : null,
                p.SalesOrderId,
                OrderNumber = p.SalesOrder != null ? p.SalesOrder.OrderNumber : null,
                p.CreatedAt,
                p.UpdatedAt
            })
            .ToListAsync(ct);

        var responses = items.Select(p => new ProofResponse(
            p.Id,
            p.ImageContentType,
            p.ImageSizeBytes,
            p.Amount,
            p.Currency,
            p.TransactionReference,
            p.Operator,
            p.Operator.ToString(),
            p.TransactionDate,
            p.Notes,
            p.Status,
            p.Status.ToString(),
            p.ErrorMessage,
            p.ClientId,
            p.ClientName,
            p.SalesOrderId,
            p.OrderNumber,
            p.CreatedAt,
            p.UpdatedAt
        ));

        return Result<ProofListResponse>.Success(
            new ProofListResponse(responses, total, page, pageSize, pendingCount)
        );
    }

    public async Task<Result<ProofResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // ✅ Projection explicite pour exclure ImageBytes
        var p = await _db.Proofs.AsNoTracking()
            .Where(p => p.Id == id && p.UserId == userId)
            .Select(p => new
            {
                p.Id,
                p.ImageContentType,
                p.ImageSizeBytes,
                p.Amount,
                p.Currency,
                p.TransactionReference,
                p.Operator,
                p.TransactionDate,
                p.Notes,
                p.Status,
                p.ErrorMessage,
                p.ClientId,
                ClientName = p.Client != null ? p.Client.FullName : null,
                p.SalesOrderId,
                OrderNumber = p.SalesOrder != null ? p.SalesOrder.OrderNumber : null,
                p.CreatedAt,
                p.UpdatedAt
            })
            .FirstOrDefaultAsync(ct);

        if (p is null)
            return Result<ProofResponse>.Failure("Preuve introuvable.");

        return Result<ProofResponse>.Success(new ProofResponse(
            p.Id,
            p.ImageContentType,
            p.ImageSizeBytes,
            p.Amount,
            p.Currency,
            p.TransactionReference,
            p.Operator,
            p.Operator.ToString(),
            p.TransactionDate,
            p.Notes,
            p.Status,
            p.Status.ToString(),
            p.ErrorMessage,
            p.ClientId,
            p.ClientName,
            p.SalesOrderId,
            p.OrderNumber,
            p.CreatedAt,
            p.UpdatedAt
        ));
    }

    public async Task<Result<ProofImage>> GetImageAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var image = await _db.Proofs.AsNoTracking()
            .Where(p => p.Id == id && p.UserId == userId)
            .Select(p => new { p.ImageBytes, p.ImageContentType })
            .FirstOrDefaultAsync(ct);

        if (image is null)
            return Result<ProofImage>.Failure("Preuve introuvable.");

        if (image.ImageBytes is null || image.ImageBytes.Length == 0)
            return Result<ProofImage>.Failure("Aucune image associée.");

        return Result<ProofImage>.Success(new ProofImage(image.ImageBytes, image.ImageContentType));
    }

    public async Task<Result<ProofResponse>> UploadAsync(
        CreateProofRequest request,
        byte[] imageBytes,
        string imageContentType,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // ✅ Validation de l'image
        if (imageBytes.Length == 0)
            return Result<ProofResponse>.Failure("Image vide.");

        if (imageBytes.Length > MaxImageSizeBytes)
            return Result<ProofResponse>.Failure(
                $"Image trop volumineuse (max 5 MB, reçu {Math.Round(imageBytes.Length / 1024.0 / 1024.0, 2)} MB)."
            );

        if (!AllowedContentTypes.Contains(imageContentType))
            return Result<ProofResponse>.Failure(
                $"Format non supporté : {imageContentType}. Utilisez JPEG, PNG ou WebP."
            );

        // ✅ Validation métier: SalesOrderId
        if (request.SalesOrderId.HasValue)
        {
            var order = await _db.SalesOrders.AsNoTracking()
                .FirstOrDefaultAsync(o => o.Id == request.SalesOrderId && o.UserId == userId, ct);

            if (order is null)
                return Result<ProofResponse>.Failure("Commande introuvable.");

            // ✅ Vérification logique: ne pas accepter de preuve pour une commande déjà payée
            if (order.Status == SalesOrderStatus.Paid)
                return Result<ProofResponse>.Failure("Cette commande est déjà payée.");
        }

        // ✅ Validation métier: ClientId
        if (request.ClientId.HasValue)
        {
            var clientExists = await _db.Clients.AsNoTracking()
                .AnyAsync(c => c.Id == request.ClientId && c.UserId == userId, ct);

            if (!clientExists)
                return Result<ProofResponse>.Failure("Client introuvable.");
        }

        // ✅ Créer la preuve
        var proof = new Proof
        {
            UserId = userId,
            ImageBytes = imageBytes,
            ImageContentType = imageContentType.ToLowerInvariant(),
            ImageSizeBytes = imageBytes.Length,
            Amount = request.Amount,
            Currency = string.IsNullOrWhiteSpace(request.Currency) ? "XAF" : request.Currency.Trim().ToUpperInvariant(),
            TransactionReference = request.TransactionReference?.Trim(),
            Operator = request.Operator,
            TransactionDate = request.TransactionDate,
            Notes = request.Notes?.Trim(),
            Status = ProofStatus.Pending,
            ClientId = request.ClientId,
            SalesOrderId = request.SalesOrderId
        };

        _db.Proofs.Add(proof);
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(proof.Id, ct);
    }

    public async Task<Result<ProofResponse>> UpdateAsync(
        Guid id,
        UpdateProofRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var proof = await _db.Proofs.FirstOrDefaultAsync(
            p => p.Id == id && p.UserId == userId,
            ct
        );

        if (proof is null)
            return Result<ProofResponse>.Failure("Preuve introuvable.");

        // ✅ Vérifier intégrité si ClientId change
        if (request.ClientId.HasValue && request.ClientId != proof.ClientId)
        {
            var clientExists = await _db.Clients.AsNoTracking()
                .AnyAsync(c => c.Id == request.ClientId && c.UserId == userId, ct);

            if (!clientExists)
                return Result<ProofResponse>.Failure("Client introuvable.");
        }

        // ✅ Vérifier intégrité si SalesOrderId change
        if (request.SalesOrderId.HasValue && request.SalesOrderId != proof.SalesOrderId)
        {
            var order = await _db.SalesOrders.AsNoTracking()
                .FirstOrDefaultAsync(o => o.Id == request.SalesOrderId && o.UserId == userId, ct);

            if (order is null)
                return Result<ProofResponse>.Failure("Commande introuvable.");

            if (order.Status == SalesOrderStatus.Paid)
                return Result<ProofResponse>.Failure("Cette commande est déjà payée.");
        }

        // ✅ Mettre à jour (NOTE: pas de modification d'image, seulement métadonnées)
        proof.Amount = request.Amount;
        proof.Currency = string.IsNullOrWhiteSpace(request.Currency) ? "XAF" : request.Currency.Trim().ToUpperInvariant();
        proof.TransactionReference = request.TransactionReference?.Trim();
        proof.Operator = request.Operator;
        proof.TransactionDate = request.TransactionDate;
        proof.Notes = request.Notes?.Trim();
        proof.Status = request.Status;
        proof.ErrorMessage = request.ErrorMessage?.Trim();
        proof.ClientId = request.ClientId;
        proof.SalesOrderId = request.SalesOrderId;

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(proof.Id, ct);
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var proof = await _db.Proofs.FirstOrDefaultAsync(
            p => p.Id == id && p.UserId == userId,
            ct
        );

        if (proof is null)
            return Result<bool>.Failure("Preuve introuvable.");

        _db.Proofs.Remove(proof);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    /// <summary>Récupère et valide l'UserId de l'utilisateur authentifié.</summary>
    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}