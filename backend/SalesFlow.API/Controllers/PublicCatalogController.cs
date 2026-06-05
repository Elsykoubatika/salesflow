using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Infrastructure.Persistence;

namespace SalesFlow.Api.Controllers;

/// <summary>
/// Catalogue PUBLIC — accessible sans authentification.
/// Agrège les produits actifs de TOUS les utilisateurs vendeurs.
/// Mode "Shein/Alibaba" : un visiteur peut parcourir et commander
/// sans compte.
///
/// Routes :
///   GET  /api/public/catalog          → liste paginée + filtres
///   GET  /api/public/catalog/{id}     → détail d'un produit + infos vendeur
///   GET  /api/public/catalog/categories → liste des catégories disponibles
/// </summary>
[ApiController]
[Route("api/public/catalog")]
[AllowAnonymous]
public class PublicCatalogController : ControllerBase
{
    private readonly AppDbContext _db;
    public PublicCatalogController(AppDbContext db) => _db = db;

    [HttpGet]
    public async Task<ActionResult<PublicCatalogPage>> List(
        [FromQuery] string? q,
        [FromQuery] string? category,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        [FromQuery] string sort = "recent",  // recent | price_asc | price_desc
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 24)
    {
        // Garde-fous pagination
        page = page < 1 ? 1 : page;
        pageSize = pageSize is < 1 or > 60 ? 24 : pageSize;

        // Base : tous les produits actifs, non signalés
        var query = _db.Products
            .AsNoTracking()
            .Where(p => p.IsActive);

        // Filtres
        if (!string.IsNullOrWhiteSpace(q))
        {
            var term = q.Trim().ToLower();
            query = query.Where(p =>
                p.Name.ToLower().Contains(term) ||
                (p.Description != null && p.Description.ToLower().Contains(term)) ||
                (p.Sku != null && p.Sku.ToLower().Contains(term)));
        }

        if (!string.IsNullOrWhiteSpace(category) && category != "all")
        {
            // Catégorie inférée du début du SKU (ex. DISJ-, CIMENT-)
            // ADJUST IF NEEDED : si tu as un champ Category dédié, utilise-le ici.
            var prefix = category.ToUpper() + "-";
            query = query.Where(p => p.Sku != null && p.Sku.StartsWith(prefix));
        }

        if (minPrice.HasValue) query = query.Where(p => p.Price >= minPrice.Value);
        if (maxPrice.HasValue) query = query.Where(p => p.Price <= maxPrice.Value);

        // Tri
        query = sort switch
        {
            "price_asc" => query.OrderBy(p => p.Price),
            "price_desc" => query.OrderByDescending(p => p.Price),
            _ => query.OrderByDescending(p => p.CreatedAt),
        };

        var total = await query.CountAsync();

        // Pagination + jointure avec User pour récupérer le nom du vendeur
        var rows = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Join(_db.Users.AsNoTracking(),
                p => p.UserId,
                u => u.Id,
                (p, u) => new PublicProductSummary(
                    p.Id,
                    p.Name,
                    p.Sku,
                    p.Description,
                    p.Price,
                    p.Currency,
                    p.ImageUrl,
                    u.Id,
                    u.FullName,
                    ""))
            .ToListAsync();

        return Ok(new PublicCatalogPage(
            Items: rows,
            Total: total,
            Page: page,
            PageSize: pageSize,
            HasMore: page * pageSize < total));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<PublicProductDetail>> Detail(Guid id)
    {
        var row = await _db.Products
            .AsNoTracking()
            .Where(p => p.Id == id && p.IsActive)
            .Join(_db.Users.AsNoTracking(),
                p => p.UserId,
                u => u.Id,
                (p, u) => new PublicProductDetail(
                    p.Id,
                    p.Name,
                    p.Sku,
                    p.Description,
                    p.Price,
                    p.Currency,
                    p.ImageUrl,
                    u.Id,
                    u.FullName,
                    "",
                    u.PhoneNumber))
            .FirstOrDefaultAsync();

        if (row is null) return NotFound(new { error = "Produit introuvable." });
        return Ok(row);
    }

    [HttpGet("categories")]
    public async Task<ActionResult<List<CategoryItem>>> Categories()
    {
        // Catégories inférées des préfixes de SKU
        var prefixes = await _db.Products
            .AsNoTracking()
            .Where(p => p.IsActive && p.Sku != null && p.Sku.Contains('-'))
            .Select(p => p.Sku!.Substring(0, p.Sku.IndexOf('-')))
            .Distinct()
            .ToListAsync();

        var cats = prefixes
            .Select(p => new CategoryItem(p.ToLower(), MapLabel(p)))
            .OrderBy(c => c.Label)
            .ToList();

        cats.Insert(0, new CategoryItem("all", "Tous"));
        return Ok(cats);
    }

    private static string MapLabel(string prefix) => prefix.ToUpper() switch
    {
        "DISJ" or "PRISE" or "CABLE" or "TABLEAU" or "INTER" or "FIL" or "BOITE" => "Électricité",
        "CIMENT" or "TUYAU" or "PAINT" or "RACCORD" or "SIPHON" or "SEAU" => "BTP",
        "ROBIN" or "TUYAU-FLEX" => "Plomberie",
        "SERV" or "CONS" or "FORM" or "MAINT" => "Services",
        _ => prefix,
    };
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
public record PublicCatalogPage(
    List<PublicProductSummary> Items,
    int Total,
    int Page,
    int PageSize,
    bool HasMore);

public record PublicProductSummary(
    Guid Id,
    string Name,
    string? Sku,
    string? Description,
    decimal Price,
    string Currency,
    string? ImageUrl,
    Guid SellerId,
    string SellerName,
    string SellerRegion);

public record PublicProductDetail(
    Guid Id,
    string Name,
    string? Sku,
    string? Description,
    decimal Price,
    string Currency,
    string? ImageUrl,
    Guid SellerId,
    string SellerName,
    string SellerRegion,
    string? SellerPhone);

public record CategoryItem(string Slug, string Label);
