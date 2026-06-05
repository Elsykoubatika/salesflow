using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Domain.Entities;
using SalesFlow.Infrastructure.Persistence;
using SalesFlow.Application.Services;
using SalesFlow.Application.Common.Security;

namespace SalesFlow.Api.Controllers;

/// <summary>
/// Création / récupération des liens de partage d'un Deal.
///
/// Routes :
///   POST /api/deals/{dealId}/share        → générer (ou récupérer) mon lien pour un canal donné
///   GET  /api/deals/{dealId}/my-shares    → tous mes liens pour ce deal (un par canal)
/// </summary>
[ApiController]
[Route("api/deals/{dealId:guid}")]
[Authorize]
public class DealSharesController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private const string PublicBaseUrl = "https://dealflow.app/d/";  // ADJUST

    public DealSharesController(AppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpPost("share")]
    public async Task<ActionResult<ShareLinkResponse>> CreateShare(
        Guid dealId, [FromBody] CreateShareRequest request)
    {
        if (!new[] { "WhatsApp", "Facebook", "Instagram", "Direct", "Own" }
            .Contains(request.Channel))
        {
            return BadRequest(new { error = "Canal non supporté." });
        }

        var deal = await _db.Deals
            .AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == dealId);
        if (deal is null) return NotFound(new { error = "Deal introuvable." });
        if (deal.Status != "Active")
            return BadRequest(new { error = "Ce deal n'est plus actif." });

        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");

        // Idempotence : si l'affilié a déjà partagé ce deal sur ce canal,
        // on retourne le même lien (évite d'avoir 10 liens identiques).
        var existing = await _db.DealShares
            .FirstOrDefaultAsync(s =>
                s.DealId == dealId
                && s.AffiliateUserId == userId
                && s.Channel == request.Channel);

        DealShare share;
        bool isNew;
        if (existing is not null)
        {
            share = existing;
            isNew = false;
        }
        else
        {
            share = new DealShare
            {
                Id = Guid.NewGuid(),
                DealId = dealId,
                AffiliateUserId = userId,
                Channel = request.Channel,
                UniqueCode = GenerateUniqueCode(),
                CreatedAt = DateTime.UtcNow,
            };
            _db.DealShares.Add(share);

            // Crée un event "Share" pour stats + commission CPS éventuelle
            var shareEvent = new DealEvent
            {
                Id = Guid.NewGuid(),
                DealShareId = share.Id,
                EventType = "Share",
                CreatedAt = DateTime.UtcNow,
            };
            shareEvent.CommissionEarned = CommissionCalculator.Calculate(deal, shareEvent);
            _db.DealEvents.Add(shareEvent);

            await _db.SaveChangesAsync();
            isNew = true;
        }

        return Ok(new ShareLinkResponse(
            ShareId: share.Id,
            UniqueCode: share.UniqueCode,
            FullUrl: PublicBaseUrl + share.UniqueCode,
            Channel: share.Channel,
            IsNew: isNew));
    }

    [HttpGet("my-shares")]
    public async Task<ActionResult<List<ShareLinkResponse>>> MyShares(Guid dealId)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
        var shares = await _db.DealShares
            .AsNoTracking()
            .Where(s => s.DealId == dealId && s.AffiliateUserId == userId)
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync();

        var result = shares.Select(s => new ShareLinkResponse(
            ShareId: s.Id,
            UniqueCode: s.UniqueCode,
            FullUrl: PublicBaseUrl + s.UniqueCode,
            Channel: s.Channel,
            IsNew: false)).ToList();

        return Ok(result);
    }

    // ─── Helper : génère un code court alphanumérique unique ────────────────
    private static string GenerateUniqueCode()
    {
        // 7 caractères : ~3 × 10^12 combinaisons — assez pour ne pas
        // s'inquiéter de collisions à l'échelle d'une PME.
        const string alphabet = "abcdefghijkmnpqrstuvwxyz23456789";
        var rnd = Random.Shared;
        var chars = new char[7];
        for (int i = 0; i < chars.Length; i++)
            chars[i] = alphabet[rnd.Next(alphabet.Length)];
        return new string(chars);
    }
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
public record CreateShareRequest(string Channel);

public record ShareLinkResponse(
    Guid ShareId,
    string UniqueCode,
    string FullUrl,
    string Channel,
    bool IsNew);
