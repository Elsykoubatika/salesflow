using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Domain.Entities;
using SalesFlow.Infrastructure.Persistence;
using SalesFlow.Application.Common.Security;

namespace SalesFlow.Api.Controllers;

/// <summary>
/// CRUD des Deals + endpoints d'analytics.
///
/// Routes :
///   GET    /api/deals/available           → deals créés par les AUTRES (à partager)
///   GET    /api/deals/mine                → deals que J'AI créés
///   GET    /api/deals/my-earnings         → mes partages + commissions gagnées
///   GET    /api/deals/{id}                → détail d'un deal
///   POST   /api/deals                     → créer un deal
///   PUT    /api/deals/{id}                → modifier un deal (créateur uniquement)
///   POST   /api/deals/{id}/close          → clôturer un deal
///   GET    /api/deals/{id}/analytics      → stats agrégées par canal (pour MA part)
/// </summary>
[ApiController]
[Route("api/deals")]
[Authorize]
public class DealsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public DealsController(AppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    // ─── Listings ────────────────────────────────────────────────────────────

    [HttpGet("available")]
    public async Task<ActionResult<List<DealListItem>>> Available()
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
        var now = DateTime.UtcNow;

        var deals = await _db.Deals
            .AsNoTracking()
            .Where(d => d.CreatorUserId != userId
                && d.Status == "Active"
                && d.ActiveFrom <= now
                && (d.ActiveTo == null || d.ActiveTo >= now))
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync();

        // Stats agrégées pour chaque deal (compteurs globaux affilié-toutes-confondues)
        var dealIds = deals.Select(d => d.Id).ToList();
        var shareStats = await _db.DealShares
            .AsNoTracking()
            .Where(s => dealIds.Contains(s.DealId))
            .GroupBy(s => s.DealId)
            .Select(g => new { DealId = g.Key, AffiliateCount = g.Count() })
            .ToListAsync();

        var saleEvents = await _db.DealEvents
            .AsNoTracking()
            .Where(e => e.EventType == "Sale")
            .Join(_db.DealShares.AsNoTracking().Where(s => dealIds.Contains(s.DealId)),
                e => e.DealShareId,
                s => s.Id,
                (e, s) => new { s.DealId })
            .GroupBy(x => x.DealId)
            .Select(g => new { DealId = g.Key, SaleCount = g.Count() })
            .ToListAsync();

        // Récupérer noms des créateurs (pour affichage "par BTP Kongo")
        var creatorIds = deals.Select(d => d.CreatorUserId).Distinct().ToList();
        var creators = await _db.Users
            .AsNoTracking()
            .Where(u => creatorIds.Contains(u.Id))
            .Select(u => new { u.Id, u.FullName })
            .ToDictionaryAsync(u => u.Id, u => u.FullName);

        var result = deals.Select(d => MapToListItem(
            d,
            creators.GetValueOrDefault(d.CreatorUserId, "Vendeur"),
            shareStats.FirstOrDefault(s => s.DealId == d.Id)?.AffiliateCount ?? 0,
            saleEvents.FirstOrDefault(s => s.DealId == d.Id)?.SaleCount ?? 0)).ToList();

        return Ok(result);
    }

    [HttpGet("mine")]
    public async Task<ActionResult<List<DealListItem>>> Mine()
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
        var deals = await _db.Deals
            .AsNoTracking()
            .Where(d => d.CreatorUserId == userId)
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync();

        var dealIds = deals.Select(d => d.Id).ToList();
        var shareStats = await _db.DealShares
            .AsNoTracking()
            .Where(s => dealIds.Contains(s.DealId))
            .GroupBy(s => s.DealId)
            .Select(g => new { DealId = g.Key, AffiliateCount = g.Count() })
            .ToListAsync();
        var saleEvents = await _db.DealEvents
            .AsNoTracking()
            .Where(e => e.EventType == "Sale")
            .Join(_db.DealShares.AsNoTracking().Where(s => dealIds.Contains(s.DealId)),
                e => e.DealShareId, s => s.Id,
                (e, s) => new { s.DealId })
            .GroupBy(x => x.DealId)
            .Select(g => new { DealId = g.Key, SaleCount = g.Count() })
            .ToListAsync();

        var result = deals.Select(d => MapToListItem(
            d,
            "Moi",
            shareStats.FirstOrDefault(s => s.DealId == d.Id)?.AffiliateCount ?? 0,
            saleEvents.FirstOrDefault(s => s.DealId == d.Id)?.SaleCount ?? 0)).ToList();

        return Ok(result);
    }

    [HttpGet("my-earnings")]
    public async Task<ActionResult<MyEarningsResponse>> MyEarnings()
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        var myShares = await _db.DealShares
            .AsNoTracking()
            .Where(s => s.AffiliateUserId == userId)
            .ToListAsync();

        if (myShares.Count == 0)
        {
            return Ok(new MyEarningsResponse(
                TotalEarned: 0m,
                TotalClicks: 0,
                TotalSales: 0,
                ActiveShares: 0,
                Currency: "XAF"));
        }

        var shareIds = myShares.Select(s => s.Id).ToList();
        var events = await _db.DealEvents
            .AsNoTracking()
            .Where(e => shareIds.Contains(e.DealShareId))
            .ToListAsync();

        var totalEarned = events.Sum(e => e.CommissionEarned ?? 0);
        var totalClicks = events.Count(e => e.EventType == "Click");
        var totalSales = events.Count(e => e.EventType == "Sale");

        return Ok(new MyEarningsResponse(
            TotalEarned: totalEarned,
            TotalClicks: totalClicks,
            TotalSales: totalSales,
            ActiveShares: myShares.Count,
            Currency: "XAF"));
    }

    // ─── Détail ──────────────────────────────────────────────────────────────

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<DealDetailResponse>> GetDetail(Guid id)
    {
        var deal = await _db.Deals.AsNoTracking().FirstOrDefaultAsync(d => d.Id == id);
        if (deal is null) return NotFound(new { error = "Deal introuvable." });

        var creator = await _db.Users
            .AsNoTracking()
            .Where(u => u.Id == deal.CreatorUserId)
            .Select(u => new { u.FullName })
            .FirstOrDefaultAsync();

        // Si un produit est lié, récupère ses infos
        string? productName = null;
        string? productImageUrl = null;
        decimal? productPrice = null;
        if (deal.ProductId.HasValue)
        {
            var p = await _db.Products
                .AsNoTracking()
                .Where(x => x.Id == deal.ProductId.Value)
                .Select(x => new { x.Name, x.ImageUrl, x.Price })
                .FirstOrDefaultAsync();
            productName = p?.Name;
            productImageUrl = p?.ImageUrl;
            productPrice = p?.Price;
        }

        return Ok(new DealDetailResponse(
            Deal: deal,
            CreatorName: creator?.FullName ?? "Vendeur",
            ProductName: productName,
            ProductImageUrl: productImageUrl,
            ProductPrice: productPrice));
    }

    // ─── Création / modification ─────────────────────────────────────────────

    [HttpPost]
    public async Task<ActionResult<Deal>> Create([FromBody] CreateDealRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title))
            return BadRequest(new { error = "Titre requis." });
        if (!new[] { "CPC", "CPS", "CPA", "CPL" }.Contains(request.CommissionType))
            return BadRequest(new { error = "Type de commission invalide." });
        if (request.CommissionAmount is null && request.CommissionPercent is null)
            return BadRequest(new { error = "Montant ou pourcentage de commission requis." });

        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
        var deal = new Deal
        {
            Id = Guid.NewGuid(),
            CreatorUserId = userId,
            ProductId = request.ProductId,
            Title = request.Title.Trim(),
            Description = request.Description,
            ContentImages = request.ContentImages,
            ContentMaterials = request.ContentMaterials,
            CommissionType = request.CommissionType,
            CommissionAmount = request.CommissionAmount,
            CommissionPercent = request.CommissionPercent,
            Currency = request.Currency ?? "XAF",
            Conditions = request.Conditions,
            StockAvailable = request.StockAvailable,
            ActiveFrom = request.ActiveFrom ?? DateTime.UtcNow,
            ActiveTo = request.ActiveTo,
            Status = "Active",
            CreatedAt = DateTime.UtcNow,
            CreatedBy = userId.ToString(),
        };
        _db.Deals.Add(deal);
        await _db.SaveChangesAsync();
        return Ok(deal);
    }

    [HttpPost("{id:guid}/close")]
    public async Task<ActionResult> Close(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
        var deal = await _db.Deals.FirstOrDefaultAsync(d => d.Id == id);
        if (deal is null) return NotFound();
        if (deal.CreatorUserId != userId) return Forbid();

        deal.Status = "Closed";
        deal.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync();
        return Ok();
    }

    // ─── Analytics par canal (pour MA part dans CE deal) ─────────────────────

    [HttpGet("{id:guid}/analytics")]
    public async Task<ActionResult<DealAnalyticsResponse>> Analytics(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        // Mes partages pour ce deal
        var myShares = await _db.DealShares
            .AsNoTracking()
            .Where(s => s.DealId == id && s.AffiliateUserId == userId)
            .ToListAsync();

        if (myShares.Count == 0)
        {
            return Ok(new DealAnalyticsResponse(
                TotalClicks: 0,
                TotalConversions: 0,
                TotalEarned: 0,
                Currency: "XAF",
                MyShareCode: null,
                ByChannel: new List<ChannelMetrics>()));
        }

        var shareIds = myShares.Select(s => s.Id).ToList();
        var events = await _db.DealEvents
            .AsNoTracking()
            .Where(e => shareIds.Contains(e.DealShareId))
            .ToListAsync();

        // Agrégation par canal
        var byChannel = myShares
            .GroupBy(s => s.Channel)
            .Select(g =>
            {
                var ids = g.Select(s => s.Id).ToList();
                var ch = events.Where(e => ids.Contains(e.DealShareId)).ToList();
                return new ChannelMetrics(
                    Channel: g.Key,
                    Clicks: ch.Count(e => e.EventType == "Click"),
                    Leads: ch.Count(e => e.EventType == "Lead"),
                    Sales: ch.Count(e => e.EventType == "Sale"),
                    Earned: ch.Sum(e => e.CommissionEarned ?? 0));
            })
            .OrderByDescending(c => c.Clicks)
            .ToList();

        return Ok(new DealAnalyticsResponse(
            TotalClicks: events.Count(e => e.EventType == "Click"),
            TotalConversions: events.Count(e => e.EventType == "Sale"),
            TotalEarned: events.Sum(e => e.CommissionEarned ?? 0),
            Currency: "XAF",
            MyShareCode: myShares.First().UniqueCode,
            ByChannel: byChannel));
    }

    // ─── Helper de mapping ──────────────────────────────────────────────────
    private static DealListItem MapToListItem(
        Deal d, string creatorName, int affiliateCount, int saleCount)
    {
        var commissionLabel = d.CommissionPercent.HasValue
            ? $"{d.CommissionPercent.Value:0.#}%"
            : (d.CommissionAmount?.ToString("0") ?? "0") + " " + d.Currency;

        return new DealListItem(
            Id: d.Id,
            Title: d.Title,
            CreatorName: creatorName,
            CommissionType: d.CommissionType,
            CommissionLabel: commissionLabel,
            Status: d.Status,
            ProductId: d.ProductId,
            ActiveTo: d.ActiveTo,
            AffiliateCount: affiliateCount,
            SaleCount: saleCount);
    }
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
public record CreateDealRequest(
    Guid? ProductId,
    string Title,
    string? Description,
    string? ContentImages,
    string? ContentMaterials,
    string CommissionType,
    decimal? CommissionAmount,
    decimal? CommissionPercent,
    string? Currency,
    string? Conditions,
    int? StockAvailable,
    DateTime? ActiveFrom,
    DateTime? ActiveTo);

public record DealListItem(
    Guid Id,
    string Title,
    string CreatorName,
    string CommissionType,
    string CommissionLabel,
    string Status,
    Guid? ProductId,
    DateTime? ActiveTo,
    int AffiliateCount,
    int SaleCount);

public record DealDetailResponse(
    Deal Deal,
    string CreatorName,
    string? ProductName,
    string? ProductImageUrl,
    decimal? ProductPrice);

public record MyEarningsResponse(
    decimal TotalEarned,
    int TotalClicks,
    int TotalSales,
    int ActiveShares,
    string Currency);

public record DealAnalyticsResponse(
    int TotalClicks,
    int TotalConversions,
    decimal TotalEarned,
    string Currency,
    string? MyShareCode,
    List<ChannelMetrics> ByChannel);

public record ChannelMetrics(
    string Channel,
    int Clicks,
    int Leads,
    int Sales,
    decimal Earned);
