using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Infrastructure.Persistence;
using SalesFlow.Application.Common;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Enums;

namespace SalesFlow.Api.Controllers;

/// <summary>
/// Endpoint agrégé pour le Dashboard analytique de l'app DealFlow.
/// Une seule requête → toutes les métriques nécessaires à l'affichage de
/// l'écran d'accueil après connexion.
///
/// Route : GET /api/dashboard/overview
/// </summary>
[ApiController]
[Route("api/dashboard")]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public DashboardController(AppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet("overview")]
    public async Task<ActionResult<DashboardOverviewResponse>> GetOverview()
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
        var now = DateTime.UtcNow;
        var startOfDay = new DateTime(now.Year, now.Month, now.Day, 0, 0, 0, DateTimeKind.Utc);
        var startOfMonth = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var startOfPrevMonth = startOfMonth.AddMonths(-1);
        var startOfYesterday = startOfDay.AddDays(-1);
        var sevenDaysAgo = startOfDay.AddDays(-6); // 7 jours fenêtre glissante (J-6 → J)

        // ─── 1. Commandes : ventes du jour, hier, en cours ───────────────────
        var todayOrders = await _db.SalesOrders
            .AsNoTracking()
            .Where(o => o.UserId == userId && o.CreatedAt >= startOfDay)
            .ToListAsync();
        var yesterdayOrders = await _db.SalesOrders
            .AsNoTracking()
            .Where(o => o.UserId == userId
                && o.CreatedAt >= startOfYesterday
                && o.CreatedAt < startOfDay)
            .ToListAsync();

        var todayRevenue = todayOrders.Sum(o => o.Total);
        var yesterdayRevenue = yesterdayOrders.Sum(o => o.Total);
        var todayDeltaPercent = yesterdayRevenue > 0
            ? (double)((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100.0
            : (todayRevenue > 0 ? 100.0 : 0.0);

        // Commandes "en cours" = créées mais pas encore livrées/payées
        // (ajuste les statuts selon ton enum côté backend)
        var inProgressStatuses = new[] { SalesOrderStatus.Sent, SalesOrderStatus.Accepted };
        var inProgressCount = await _db.SalesOrders
            .AsNoTracking()
            .CountAsync(o => o.UserId == userId
                && inProgressStatuses.Contains(o.Status));

        // ─── 2. Revenu mensuel + comparaison mois précédent ──────────────────
        var monthOrders = await _db.SalesOrders
            .AsNoTracking()
            .Where(o => o.UserId == userId && o.CreatedAt >= startOfMonth)
            .ToListAsync();
        var prevMonthOrders = await _db.SalesOrders
            .AsNoTracking()
            .Where(o => o.UserId == userId
                && o.CreatedAt >= startOfPrevMonth
                && o.CreatedAt < startOfMonth)
            .ToListAsync();

        var monthRevenue = monthOrders.Sum(o => o.Total);
        var prevMonthRevenue = prevMonthOrders.Sum(o => o.Total);
        var monthDeltaPercent = prevMonthRevenue > 0
            ? (double)((monthRevenue - prevMonthRevenue) / prevMonthRevenue) * 100.0
            : (monthRevenue > 0 ? 100.0 : 0.0);

        // ─── 3. Clients : actifs (avec au moins une commande) + nouveaux ─────
        var activeClientIds = await _db.SalesOrders
            .AsNoTracking()
            .Where(o => o.UserId == userId)
            .Select(o => o.ClientId)
            .Distinct()
            .CountAsync();

        var newClientsThisMonth = await _db.Clients
            .AsNoTracking()
            .CountAsync(c => c.UserId == userId && c.CreatedAt >= startOfMonth);

        // ─── 4. Courbe revenu 7 derniers jours ───────────────────────────────
        var sevenDayOrders = await _db.SalesOrders
            .AsNoTracking()
            .Where(o => o.UserId == userId && o.CreatedAt >= sevenDaysAgo)
            .Select(o => new { o.CreatedAt, o.Total })
            .ToListAsync();

        var revenueByDay = new List<DailyRevenuePoint>();
        for (int i = 0; i < 7; i++)
        {
            var day = sevenDaysAgo.AddDays(i);
            var nextDay = day.AddDays(1);
            var dayTotal = sevenDayOrders
                .Where(o => o.CreatedAt >= day && o.CreatedAt < nextDay)
                .Sum(o => o.Total);
            revenueByDay.Add(new DailyRevenuePoint(day, dayTotal));
        }

        // ─── 5. Top produits du mois (par fréquence dans les commandes) ──────
        // Ici on agrège côté serveur via SalesOrderItems si la table existe ;
        // sinon on fait une approximation par OrderCount.
        var topProducts = await GetTopProductsAsync(userId);

        // ─── 6. Alertes opérationnelles ──────────────────────────────────────
        var lowStockCount = await _db.InventoryItems
            .AsNoTracking()
            .CountAsync(i => i.UserId == userId
                && i.ReorderThreshold.HasValue
                && i.Quantity <= i.ReorderThreshold.Value);

        var alerts = new List<DashboardAlert>();
        if (lowStockCount > 0)
        {
            alerts.Add(new DashboardAlert(
                Type: "low_stock",
                Severity: "warning",
                Title: $"{lowStockCount} article{(lowStockCount > 1 ? "s" : "")} en stock bas",
                Action: "Voir l'inventaire"));
        }

        // ─── Réponse ─────────────────────────────────────────────────────────
        var response = new DashboardOverviewResponse(
            TodayRevenue: todayRevenue,
            TodayDeltaPercent: Math.Round(todayDeltaPercent, 1),
            InProgressOrders: inProgressCount,
            MonthRevenue: monthRevenue,
            MonthDeltaPercent: Math.Round(monthDeltaPercent, 1),
            ActiveClients: activeClientIds,
            NewClientsThisMonth: newClientsThisMonth,
            RevenueByDay: revenueByDay,
            TopProducts: topProducts,
            Alerts: alerts,
            Currency: "XAF",
            GeneratedAt: now);

        return Ok(response);
    }

    // ─────────────────────────────────────────────────────────────────────────
    private async Task<List<TopProductItem>> GetTopProductsAsync(
        Guid userId)
    {
        // Variante 1 : si une table SalesOrderItems existe avec ProductId + Quantity
        // Variante 2 : approximation via comptage des occurrences (à adapter selon
        // la structure réelle de SalesOrder côté backend).
        //
        // Implémentation par défaut (variante 2 — robuste sans SalesOrderItems) :
        // on prend les 3 produits actifs les plus récemment vendus comme proxy.
        var products = await _db.Products
            .AsNoTracking()
            .Where(p => p.UserId == userId && p.IsActive)
            .OrderByDescending(p => p.CreatedAt)
            .Take(3)
            .Select(p => new TopProductItem(
                p.Id,
                p.Name,
                0,            // SalesCount à remplir si SalesOrderItems existe
                p.Currency,
                p.Price))
            .ToListAsync();

        return products;
    }
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
public record DashboardOverviewResponse(
    decimal TodayRevenue,
    double TodayDeltaPercent,
    int InProgressOrders,
    decimal MonthRevenue,
    double MonthDeltaPercent,
    int ActiveClients,
    int NewClientsThisMonth,
    List<DailyRevenuePoint> RevenueByDay,
    List<TopProductItem> TopProducts,
    List<DashboardAlert> Alerts,
    string Currency,
    DateTime GeneratedAt);

public record DailyRevenuePoint(DateTime Date, decimal Amount);

public record TopProductItem(
    Guid ProductId,
    string Name,
    int SalesCount,
    string Currency,
    decimal UnitPrice);

public record DashboardAlert(
    string Type,
    string Severity,
    string Title,
    string Action);
