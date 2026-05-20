using System.Web;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Catalog.DTOs;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Catalog.Services;

public class ProductService : IProductService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public ProductService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<ProductListResponse>> ListAsync(int page, int pageSize, string? search, bool? activeOnly, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        page = page < 1 ? 1 : page;
        pageSize = pageSize switch
        {
            < 1 => DefaultPageSize,
            > MaxPageSize => MaxPageSize,
            _ => pageSize
        };

        var query = _db.Products.AsNoTracking().Where(p => p.UserId == userId);

        if (activeOnly == true)
            query = query.Where(p => p.IsActive);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p =>
                p.Name.ToLower().Contains(s) ||
                (p.Description != null && p.Description.ToLower().Contains(s)) ||
                (p.Sku != null && p.Sku.ToLower().Contains(s))
            );
        }

        var total = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => Map(p))
            .ToListAsync(ct);

        return Result<ProductListResponse>.Success(new ProductListResponse(items, total, page, pageSize));
    }

    public async Task<Result<ProductResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var product = await _db.Products.AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        return product is null
            ? Result<ProductResponse>.Failure("Produit introuvable.")
            : Result<ProductResponse>.Success(Map(product));
    }

    public async Task<Result<ProductResponse>> CreateAsync(CreateProductRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var product = new Product
        {
            UserId = userId,
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            Price = request.Price,
            Currency = string.IsNullOrWhiteSpace(request.Currency) ? "XAF" : request.Currency.Trim().ToUpperInvariant(),
            Sku = request.Sku?.Trim(),
            ImageUrl = request.ImageUrl?.Trim(),
            VariantsJson = request.VariantsJson,
            IsActive = true
        };

        _db.Products.Add(product);
        await _db.SaveChangesAsync(ct);

        return Result<ProductResponse>.Success(Map(product));
    }

    public async Task<Result<ProductResponse>> UpdateAsync(Guid id, UpdateProductRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var product = await _db.Products
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        if (product is null)
            return Result<ProductResponse>.Failure("Produit introuvable.");

        product.Name = request.Name.Trim();
        product.Description = request.Description?.Trim();
        product.Price = request.Price;
        product.Currency = string.IsNullOrWhiteSpace(request.Currency) ? "XAF" : request.Currency.Trim().ToUpperInvariant();
        product.Sku = request.Sku?.Trim();
        product.ImageUrl = request.ImageUrl?.Trim();
        product.VariantsJson = request.VariantsJson;
        product.IsActive = request.IsActive;

        await _db.SaveChangesAsync(ct);
        return Result<ProductResponse>.Success(Map(product));
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var product = await _db.Products
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        if (product is null)
            return Result<bool>.Failure("Produit introuvable.");

        _db.Products.Remove(product);
        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    public async Task<Result<WhatsAppLinkResponse>> GenerateWhatsAppLinkAsync(Guid productId, string? customMessage, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        // On a besoin du produit ET du numéro du marchand
        var data = await (
            from p in _db.Products
            join u in _db.Users on p.UserId equals u.Id
            where p.Id == productId && p.UserId == userId
            select new { Product = p, MerchantPhone = u.PhoneNumber }
        ).AsNoTracking().FirstOrDefaultAsync(ct);

        if (data is null)
            return Result<WhatsAppLinkResponse>.Failure("Produit introuvable.");

        if (string.IsNullOrWhiteSpace(data.MerchantPhone))
            return Result<WhatsAppLinkResponse>.Failure(
                "Aucun numéro WhatsApp configuré sur votre profil. Renseignez votre numéro de téléphone d'abord.");

        // Normaliser le numéro pour wa.me : que des chiffres, pas de +, pas d'espaces
        var phoneDigits = NormalizePhone(data.MerchantPhone);
        if (phoneDigits.Length < 8)
            return Result<WhatsAppLinkResponse>.Failure("Le numéro de téléphone du profil semble invalide.");

        var message = !string.IsNullOrWhiteSpace(customMessage)
            ? customMessage.Trim()
            : BuildDefaultMessage(data.Product);

        // Encoder pour URL (espaces → %20, etc.). HttpUtility est conservé pour compatibilité.
        var encoded = HttpUtility.UrlEncode(message);
        var url = $"https://wa.me/{phoneDigits}?text={encoded}";

        return Result<WhatsAppLinkResponse>.Success(new WhatsAppLinkResponse(url, phoneDigits, message));
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");

    private static string NormalizePhone(string raw) =>
        new string(raw.Where(char.IsDigit).ToArray());

    private static string BuildDefaultMessage(Product p)
    {
        var price = p.Price.ToString("N0", System.Globalization.CultureInfo.InvariantCulture).Replace(",", " ");
        return $"Bonjour, je suis intéressé(e) par : {p.Name} ({price} {p.Currency}). Pouvez-vous me confirmer la disponibilité ? Merci.";
    }

    private static ProductResponse Map(Product p) => new(
        p.Id, p.Name, p.Description, p.Price, p.Currency, p.Sku, p.ImageUrl,
        p.VariantsJson, p.IsActive, p.CreatedAt, p.UpdatedAt
    );
}
