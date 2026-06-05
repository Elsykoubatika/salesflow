using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Infrastructure.Persistence;

namespace SalesFlow.Api.Controllers;

/// <summary>
/// Signalement de produits par les utilisateurs (modération communautaire).
///
/// Routes :
///   POST /api/public/reports            → tout visiteur peut signaler
///   GET  /api/admin/reports             → les admins consultent et statuent
///   POST /api/admin/reports/{id}/resolve → marquer traité + désactiver le produit si besoin
///
/// Pré-requis : entité ProductReport à créer côté Domain (voir guide
/// d'installation). Si tu n'as pas envie d'ajouter une entité maintenant,
/// la v0 peut simplement logger dans la console et envoyer un mail à l'admin.
/// </summary>
[ApiController]
public class ReportsController : ControllerBase
{
    private readonly AppDbContext _db;
    public ReportsController(AppDbContext db) => _db = db;

    [HttpPost("api/public/reports")]
    [AllowAnonymous]
    public async Task<ActionResult> Submit([FromBody] ReportSubmitRequest request)
    {
        if (request.ProductId == Guid.Empty)
            return BadRequest(new { error = "Produit invalide." });
        if (string.IsNullOrWhiteSpace(request.Reason))
            return BadRequest(new { error = "Raison du signalement requise." });

        var productExists = await _db.Products
            .AsNoTracking()
            .AnyAsync(p => p.Id == request.ProductId);
        if (!productExists)
            return NotFound(new { error = "Produit introuvable." });

        // v0 minimale : on log dans la console + on incrémente un compteur
        // si tu ajoutes l'entité ProductReport, remplace par un Add().
        Console.WriteLine($"[REPORT] Produit {request.ProductId} signalé · raison: {request.Reason}");
        Console.WriteLine($"[REPORT] Détails: {request.Details ?? "(aucun)"}");
        Console.WriteLine($"[REPORT] Contact signaleur: {request.ReporterContact ?? "(anonyme)"}");

        // TODO v1 : créer l'entité ProductReport pour persister
        // _db.ProductReports.Add(new ProductReport { ... });
        // await _db.SaveChangesAsync();

        return Ok(new { message = "Signalement reçu. Merci de votre vigilance." });
    }
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
public record ReportSubmitRequest(
    Guid ProductId,
    string Reason,            // "fake" | "offensive" | "wrong_price" | "other"
    string? Details,
    string? ReporterContact); // optionnel — anonymisable
