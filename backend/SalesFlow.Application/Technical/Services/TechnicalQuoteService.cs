using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Technical.DTOs;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Technical.Services;

public class TechnicalQuoteService : ITechnicalQuoteService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public TechnicalQuoteService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<TechnicalQuoteListResponse>> ListAsync(
    int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        page = page < 1 ? 1 : page;
        pageSize = pageSize switch { < 1 => DefaultPageSize, > MaxPageSize => MaxPageSize, _ => pageSize };

        // ✅ SIMPLE - Pas de type explicite, pas d'Include à la fin
        var query = _db.TechnicalQuotes
            .Where(q => q.UserId == userId)
            .Include(q => q.Client)
            .Include(q => q.Items)
            .AsNoTracking();  // ← Mettre AsNoTracking() À LA FIN

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(q => q.Status == status);

        var total = await query.CountAsync(ct);
        var acceptedCount = await query.Where(q => q.Status == "Accepted").CountAsync(ct);

        var items = await query
            .OrderByDescending(q => q.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(q => MapQuote(q))
            .ToListAsync(ct);

        return Result<TechnicalQuoteListResponse>.Success(
            new TechnicalQuoteListResponse(items, total, acceptedCount, page, pageSize)
        );
    }

    public async Task<Result<TechnicalQuoteResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var quote = await _db.TechnicalQuotes.AsNoTracking()
            .Include(q => q.Client)
            .Include(q => q.Items)
            .FirstOrDefaultAsync(q => q.Id == id && q.UserId == userId, ct);

        return quote is null
            ? Result<TechnicalQuoteResponse>.Failure("Devis introuvable.")
            : Result<TechnicalQuoteResponse>.Success(MapQuote(quote));
    }

    public async Task<Result<TechnicalQuoteResponse>> CreateAsync(CreateTechnicalQuoteRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var client = await _db.Clients.FirstOrDefaultAsync(c => c.Id == request.ClientId && c.UserId == userId, ct);
        if (client is null)
            return Result<TechnicalQuoteResponse>.Failure("Client introuvable.");

        var laborCost = request.EstimatedHours * request.HourlyRate;
        var materialsCost = request.Items?.Sum(i => i.Quantity * i.UnitPrice) ?? 0;
        var total = laborCost + materialsCost;

        var quote = new TechnicalQuote
        {
            UserId = userId,
            ClientId = request.ClientId,
            QuoteNumber = GenerateQuoteNumber(),
            Title = request.Title.Trim(),
            Description = request.Description?.Trim() ?? string.Empty,
            ServiceLocation = request.ServiceLocation?.Trim() ?? string.Empty,
            EstimatedHours = request.EstimatedHours,
            HourlyRate = request.HourlyRate,
            MaterialsCost = materialsCost,
            LaborCost = laborCost,
            Total = total,
            Currency = "XAF",
            ValidUntil = DateTime.UtcNow.AddDays(30),
            Status = "Draft"
        };

        if (request.Items?.Any() == true)
        {
            foreach (var item in request.Items)
            {
                quote.Items.Add(new TechnicalQuoteItem
                {
                    ItemName = item.ItemName.Trim(),
                    ItemType = item.ItemType,
                    Quantity = item.Quantity,
                    Unit = item.Unit,
                    UnitPrice = item.UnitPrice
                });
            }
        }

        _db.TechnicalQuotes.Add(quote);
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(quote.Id, ct);
    }

    public async Task<Result<TechnicalQuoteItemResponse>> AddItemAsync(Guid quoteId, CreateTechnicalQuoteItemRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var quote = await _db.TechnicalQuotes.FirstOrDefaultAsync(q => q.Id == quoteId && q.UserId == userId, ct);
        if (quote is null)
            return Result<TechnicalQuoteItemResponse>.Failure("Devis introuvable.");

        var item = new TechnicalQuoteItem
        {
            TechnicalQuoteId = quoteId,
            ItemName = request.ItemName.Trim(),
            ItemType = request.ItemType,
            Quantity = request.Quantity,
            Unit = request.Unit,
            UnitPrice = request.UnitPrice
        };

        quote.MaterialsCost += item.Total;
        quote.Total = quote.LaborCost + quote.MaterialsCost;

        _db.TechnicalQuoteItems.Add(item);
        await _db.SaveChangesAsync(ct);

        return Result<TechnicalQuoteItemResponse>.Success(new TechnicalQuoteItemResponse(
            item.Id, item.ItemName, item.ItemType, item.Quantity, item.Unit, item.UnitPrice, item.Total
        ));
    }

    public async Task<Result<TechnicalQuoteResponse>> SendAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var quote = await _db.TechnicalQuotes.FirstOrDefaultAsync(q => q.Id == id && q.UserId == userId, ct);
        if (quote is null)
            return Result<TechnicalQuoteResponse>.Failure("Devis introuvable.");
        if (quote.Status != "Draft")
            return Result<TechnicalQuoteResponse>.Failure("Seul un brouillon peut être envoyé.");

        quote.Status = "Sent";
        quote.SentAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<TechnicalQuoteResponse>> AcceptAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var quote = await _db.TechnicalQuotes.FirstOrDefaultAsync(q => q.Id == id && q.UserId == userId, ct);
        if (quote is null)
            return Result<TechnicalQuoteResponse>.Failure("Devis introuvable.");
        if (quote.Status != "Sent")
            return Result<TechnicalQuoteResponse>.Failure("Seul un devis envoyé peut être accepté.");

        quote.Status = "Accepted";
        quote.AcceptedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var quote = await _db.TechnicalQuotes.FirstOrDefaultAsync(q => q.Id == id && q.UserId == userId, ct);
        if (quote is null)
            return Result<bool>.Failure("Devis introuvable.");
        if (quote.Status != "Draft")
            return Result<bool>.Failure("Seul un brouillon peut être supprimé.");

        _db.TechnicalQuotes.Remove(quote);
        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    private static TechnicalQuoteResponse MapQuote(TechnicalQuote q) => new(
        q.Id, q.QuoteNumber, q.Title, q.Description, q.ServiceLocation, q.ClientId,
        q.Client?.FullName ?? "Client supprimé", q.EstimatedHours, q.HourlyRate,
        q.MaterialsCost, q.LaborCost, q.Total, q.Currency, q.ValidUntil,
        q.Status, q.SentAt, q.AcceptedAt, q.Items?.Count ?? 0, q.CreatedAt, q.UpdatedAt
    );

    private static string GenerateQuoteNumber() => $"QTE-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6).ToUpper()}";

    private Guid RequireUserId() => _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}