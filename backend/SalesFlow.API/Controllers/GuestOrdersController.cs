using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Domain.Entities;
using SalesFlow.Domain.Enums;
using SalesFlow.Infrastructure.Persistence;
using SalesFlow.Application.Services;

namespace SalesFlow.Api.Controllers;

/// <summary>
/// Passage de commande SANS compte préalable.
///
/// Flow :
///   1. Le visiteur remplit nom + téléphone + adresse + panier
///   2. On cherche s'il existe déjà un User avec ce téléphone
///        - Oui → on rattache la commande à ce User
///        - Non → on crée un User "léger" (mot de passe aléatoire,
///                téléphone = identifiant), avec DomainType = Commerce
///   3. On crée un Client (côté vendeur principal) + une SalesOrder
///   4. On retourne au visiteur : code de commande + token léger
///      pour qu'il puisse suivre sa commande
///
/// Route : POST /api/public/guest-orders
/// </summary>
[ApiController]
[Route("api/public/guest-orders")]
[AllowAnonymous]
public class GuestOrdersController(AppDbContext db) : ControllerBase
{
    private readonly AppDbContext _db = db;

    [HttpPost]
    public async Task<ActionResult<GuestOrderResponse>> Create(
        [FromBody] GuestOrderRequest request)
    {
        // ─── Validation ──────────────────────────────────────────────────────
        if (string.IsNullOrWhiteSpace(request.FullName))
            return BadRequest(new { error = "Nom requis." });
        if (string.IsNullOrWhiteSpace(request.PhoneNumber))
            return BadRequest(new { error = "Numéro de téléphone requis." });
        if (string.IsNullOrWhiteSpace(request.DeliveryAddress))
            return BadRequest(new { error = "Adresse de livraison requise." });
        if (request.Items is null || request.Items.Count == 0)
            return BadRequest(new { error = "Panier vide." });

        var phone = NormalizePhone(request.PhoneNumber);

        // ─── 1. Récupérer ou créer le compte client léger ────────────────────
        var customer = await _db.Users
            .FirstOrDefaultAsync(u => u.PhoneNumber == phone);

        var isNewCustomer = customer is null;
        if (isNewCustomer)
        {
            // Mot de passe aléatoire — le client pourra le réinitialiser
            // ultérieurement via OTP s'il veut vraiment se connecter.
            var tempPassword = Guid.NewGuid().ToString("N").Substring(0, 16);
            customer = new User
            {
                Id = Guid.NewGuid(),
                Email = $"{phone.Replace("+", "")}@guest.dealflow.cg",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(tempPassword, workFactor: 10),
                FullName = request.FullName.Trim(),
                PhoneNumber = phone,
                DomainType = DomainType.Commerce,  // client final, pas vendeur
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = "GuestOrder",
            };
            _db.Users.Add(customer);
            await _db.SaveChangesAsync();
        }

        // ─── 2. Identifier le vendeur (premier item du panier) ───────────────
        // Hypothèse v1 : une commande = un seul vendeur (le vendeur du 1er produit).
        // Si le panier contient des produits de vendeurs différents, on splittera
        // en plusieurs commandes dans une v2.
        var firstProduct = await _db.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == request.Items[0].ProductId);
        if (firstProduct is null)
            return BadRequest(new { error = "Produit du panier introuvable." });

        var sellerId = firstProduct.UserId;

        // ─── 3. Créer (ou récupérer) le Client côté vendeur ──────────────────
        // Le client final apparaîtra dans le CRM du vendeur.
        var clientRecord = await _db.Clients
            .FirstOrDefaultAsync(c => c.UserId == sellerId
                && c.PhoneNumber == phone);

        if (clientRecord is null)
        {
            clientRecord = new Client
            {
                Id = Guid.NewGuid(),
                UserId = sellerId,
                FullName = request.FullName.Trim(),
                PhoneNumber = phone,
                Email = customer!.Email,
                Address = request.DeliveryAddress.Trim(),
                Region = request.Region ?? "",
                Notes = "Client acquis via commande invité",
                CreatedAt = DateTime.UtcNow,
                CreatedBy = "GuestOrder",
            };
            _db.Clients.Add(clientRecord);
            await _db.SaveChangesAsync();
        }

        // ─── 4. Calcul du total + création de la commande ────────────────────
        decimal total = 0m;
        var productIds = request.Items.Select(i => i.ProductId).Distinct().ToList();
        var products = await _db.Products
            .AsNoTracking()
            .Where(p => productIds.Contains(p.Id))
            .ToDictionaryAsync(p => p.Id);

        foreach (var item in request.Items)
        {
            if (!products.TryGetValue(item.ProductId, out var p))
                return BadRequest(new { error = $"Produit introuvable : {item.ProductId}" });
            if (item.Quantity < 1)
                return BadRequest(new { error = "Quantité invalide." });
            total += p.Price * item.Quantity;
        }

        var orderCode = $"DF-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6).ToUpperInvariant()}";
        var order = new SalesOrder
        {
            Id = Guid.NewGuid(),
            UserId = sellerId,
            ClientId = clientRecord.Id,
            OrderNumber = orderCode,
            Total = total,
            Currency = firstProduct.Currency,
            Status = SalesOrderStatus.Accepted,
            Notes = $"Commande invité — {request.FullName.Trim()} ({phone})\nAdresse de livraison : {request.DeliveryAddress.Trim()}",
            CreatedAt = DateTime.UtcNow,
            CreatedBy = customer!.Email,
        };
        _db.SalesOrders.Add(order);
        await _db.SaveChangesAsync();

        // ─── 4.5 Affiliation tracking ────────────────────────────────────────
        if (Request.Cookies.TryGetValue("dealflow_aff", out var shareIdStr) 
            && Guid.TryParse(shareIdStr, out var shareId))
        {
            var share = await _db.DealShares
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.Id == shareId);

            if (share is not null)
            {
                var deal = await _db.Deals
                    .AsNoTracking()
                    .FirstOrDefaultAsync(d => d.Id == share.DealId);

                if (deal is not null)
                {
                    var saleEvent = new DealEvent
                    {
                        Id = Guid.NewGuid(),
                        DealShareId = share.Id,
                        EventType = "Sale",
                        SaleAmount = total,
                        OrderId = order.Id,
                        CreatedAt = DateTime.UtcNow,
                    };
                    saleEvent.CommissionEarned = CommissionCalculator.Calculate(deal, saleEvent);
                    _db.DealEvents.Add(saleEvent);
                    await _db.SaveChangesAsync();
                }
            }
        }

        // ─── 5. Réponse au visiteur ──────────────────────────────────────────

        return Ok(new GuestOrderResponse(
            OrderId: order.Id,
            OrderCode: orderCode,
            TotalAmount: total,
            Currency: order.Currency,
            CustomerId: customer.Id,
            IsNewAccount: isNewCustomer,
            Message: isNewCustomer
                ? "Compte créé automatiquement. Utilisez votre numéro de téléphone pour vous connecter ultérieurement."
                : "Commande rattachée à votre compte existant."));
    }

    private static string NormalizePhone(string raw)
    {
        var cleaned = new string(raw.Where(c => char.IsDigit(c) || c == '+').ToArray());
        if (!cleaned.StartsWith('+') && cleaned.Length >= 9)
            cleaned = "+242" + cleaned.TrimStart('0');  // défaut Congo-Brazza
        return cleaned;
    }
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
public record GuestOrderRequest(
    string FullName,
    string PhoneNumber,
    string DeliveryAddress,
    string? Region,
    List<GuestOrderItem> Items);

public record GuestOrderItem(Guid ProductId, int Quantity);

public record GuestOrderResponse(
    Guid OrderId,
    string OrderCode,
    decimal TotalAmount,
    string Currency,
    Guid CustomerId,
    bool IsNewAccount,
    string Message);
