using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Domain.Entities;
using SalesFlow.Infrastructure.Persistence;
using SalesFlow.Application.Services;

namespace SalesFlow.Api.Controllers;

/// <summary>
/// Endpoint public de tracking — c'est lui qui reçoit les clics sur les
/// liens partagés (https://dealflow.app/d/{code}) et redirige.
///
/// Flow :
///   1. Un visiteur clique sur le lien WhatsApp d'un affilié
///   2. Backend reçoit GET /d/{code}
///   3. Crée un DealEvent(type=Click) avec hash IP pour anti-fraude
///   4. Redirige vers la fiche produit publique (ou la page d'accueil
///      si campagne libre sans produit)
///
/// Routes :
///   GET  /d/{code}                          → tracking + redirect
///   POST /api/deals/tracking/lead           → app frontend signale un lead
///   POST /api/deals/tracking/sale-from-order → backend interne : commande créée via affiliation
/// </summary>
[ApiController]
public class DealTrackingController : ControllerBase
{
    private readonly AppDbContext _db;
    public DealTrackingController(AppDbContext db) => _db = db;

    /// <summary>
    /// Point d'entrée des clics depuis le réseau social.
    /// Public, sans auth — on log et on redirige.
    /// </summary>
    [HttpGet("/d/{code}")]
    [AllowAnonymous]
    public async Task<IActionResult> Track(string code)
    {
        var share = await _db.DealShares
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.UniqueCode == code);

        if (share is null)
        {
            return Redirect("/"); // code invalide → accueil
        }

        var deal = await _db.Deals
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == share.DealId);

        // Anti-fraude : on déduplique les clics depuis la même IP sur 60 secondes
        var ipHash = HashIp(HttpContext.Connection.RemoteIpAddress?.ToString());
        var userAgent = Request.Headers.UserAgent.ToString();
        var sixtySecondsAgo = DateTime.UtcNow.AddSeconds(-60);

        var recentClick = await _db.DealEvents
            .AsNoTracking()
            .AnyAsync(e => e.DealShareId == share.Id
                && e.EventType == "Click"
                && e.IpHash == ipHash
                && e.CreatedAt >= sixtySecondsAgo);

        if (!recentClick && deal is not null)
        {
            var clickEvent = new DealEvent
            {
                Id = Guid.NewGuid(),
                DealShareId = share.Id,
                EventType = "Click",
                IpHash = ipHash,
                UserAgent = userAgent.Length > 200
                    ? userAgent.Substring(0, 200)
                    : userAgent,
                CreatedAt = DateTime.UtcNow,
            };
            clickEvent.CommissionEarned =
                CommissionCalculator.Calculate(deal, clickEvent);
            _db.DealEvents.Add(clickEvent);
            await _db.SaveChangesAsync();
        }

        // Redirection
        // - Deal lié à un produit → page publique du produit
        // - Sinon → accueil app (avec le dealId dans l'URL pour campagne libre)
        var redirectUrl = deal?.ProductId.HasValue == true
            ? $"/p/{deal.ProductId}"
            : $"/?deal={share.DealId}";

        // Pose un cookie pour rattacher une éventuelle commande au DealShare
        Response.Cookies.Append("dealflow_aff", share.Id.ToString(),
            new CookieOptions
            {
                HttpOnly = true,
                MaxAge = TimeSpan.FromDays(30),
                SameSite = SameSiteMode.Lax,
            });

        return Redirect(redirectUrl);
    }

    /// <summary>
    /// L'app frontend signale qu'un lead a été capturé (ex : un formulaire
    /// de contact a été soumis après un clic affiliation).
    /// </summary>
    [HttpPost("/api/deals/tracking/lead")]
    [AllowAnonymous]
    public async Task<IActionResult> RegisterLead([FromBody] LeadTrackingRequest request)
    {
        var share = await _db.DealShares
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.UniqueCode == request.Code);
        if (share is null) return Ok(); // silencieux

        var deal = await _db.Deals
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == share.DealId);
        if (deal is null) return Ok();

        var leadEvent = new DealEvent
        {
            Id = Guid.NewGuid(),
            DealShareId = share.Id,
            EventType = "Lead",
            CreatedAt = DateTime.UtcNow,
        };
        leadEvent.CommissionEarned = CommissionCalculator.Calculate(deal, leadEvent);
        _db.DealEvents.Add(leadEvent);
        await _db.SaveChangesAsync();

        return Ok();
    }

    /// <summary>
    /// Rattache une vente (SalesOrder) à un partage si elle vient d'un clic
    /// affiliation. À appeler depuis le flow de création de commande quand
    /// le cookie dealflow_aff est présent.
    ///
    /// L'appel est protégé : seuls les services internes le déclenchent
    /// (typiquement depuis SalesOrdersController ou GuestOrdersController).
    /// </summary>
    [HttpPost("/api/deals/tracking/sale-from-order")]
    [Authorize]
    public async Task<IActionResult> RegisterSale([FromBody] SaleTrackingRequest request)
    {
        var share = await _db.DealShares
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == request.DealShareId);
        if (share is null) return NotFound();

        var deal = await _db.Deals
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == share.DealId);
        if (deal is null) return NotFound();

        var saleEvent = new DealEvent
        {
            Id = Guid.NewGuid(),
            DealShareId = share.Id,
            EventType = "Sale",
            SaleAmount = request.Amount,
            OrderId = request.OrderId,
            CreatedAt = DateTime.UtcNow,
        };
        saleEvent.CommissionEarned = CommissionCalculator.Calculate(deal, saleEvent);
        _db.DealEvents.Add(saleEvent);
        await _db.SaveChangesAsync();

        return Ok(new { commission = saleEvent.CommissionEarned });
    }

    // ─── Helper : hash IP (anti-fraude, pas réversible) ─────────────────────
    private static string HashIp(string? ip)
    {
        if (string.IsNullOrEmpty(ip)) return "";
        using var sha = SHA256.Create();
        var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(ip));
        return Convert.ToHexString(bytes).Substring(0, 16);
    }
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
public record LeadTrackingRequest(string Code);
public record SaleTrackingRequest(Guid DealShareId, decimal Amount, Guid? OrderId);
