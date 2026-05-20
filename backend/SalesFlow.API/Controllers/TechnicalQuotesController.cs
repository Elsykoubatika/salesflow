using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/technical/quotes")]
[Authorize]
public class TechnicalQuotesController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public TechnicalQuotesController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult> List([FromQuery] string? status = null, [FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        IQueryable<TechnicalQuote> query = _db.TechnicalQuotes
            .Where(q => q.UserId == userId)
            .Include(q => q.Items);

        if (!string.IsNullOrEmpty(status))
            query = query.Where(q => q.Status == status);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(q => q.CreatedOn)
            .Skip((page - 1) * 20)
            .Take(20)
            .Select(q => new
            {
                q.Id,
                q.QuoteNumber,
                q.Title,
                q.Total,
                q.Status,
                itemCount = q.Items.Count,
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult> GetById(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var quote = await _db.TechnicalQuotes
            .Where(q => q.Id == id && q.UserId == userId)
            .Include(q => q.Items)
            .FirstOrDefaultAsync();

        if (quote == null) return NotFound();

        return Ok(new
        {
            quote.Id,
            quote.QuoteNumber,
            quote.Title,
            quote.Description,
            quote.EstimatedHours,
            quote.HourlyRate,
            quote.MaterialsCost,
            quote.Total,
            quote.Currency,
            quote.ValidUntil,
            quote.Status,
            items = quote.Items.Select(i => new
            {
                i.Id,
                i.ItemName,
                i.Quantity,
                i.UnitPrice,
                i.Total,
            }).ToList(),
        });
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateTechnicalQuoteRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var estimatedHours = (decimal)(request.EstimatedHours ?? 0);
        var hourlyRate = request.HourlyRate ?? 50_000m;
        var laborCost = estimatedHours * hourlyRate;
        var total = laborCost + (request.MaterialsCost ?? 0m);

        var quote = new TechnicalQuote
        {
            UserId = userId,
            ClientId = request.ClientId,
            QuoteNumber = $"DEVIS-{DateTime.Now:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6)}",
            Title = request.Title ?? string.Empty,
            Description = request.Description ?? string.Empty,
            ServiceLocation = request.ServiceLocation ?? string.Empty,
            EstimatedHours = estimatedHours,
            HourlyRate = hourlyRate,
            MaterialsCost = request.MaterialsCost ?? 0m,
            LaborCost = laborCost,
            Total = total,
            Currency = "XAF",
            ValidUntil = request.ValidUntil,
            Status = "Draft",
        };

        _db.TechnicalQuotes.Add(quote);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = quote.Id }, quote);
    }

    [HttpPost("{id:guid}/items")]
    public async Task<ActionResult> AddItem(Guid id, [FromBody] AddQuoteItemRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var quote = await _db.TechnicalQuotes
            .FirstOrDefaultAsync(q => q.Id == id && q.UserId == userId);

        if (quote == null) return NotFound();

        var item = new TechnicalQuoteItem
        {
            TechnicalQuoteId = id,
            ItemName = request.ItemName ?? string.Empty,
            ItemType = request.ItemType ?? string.Empty,
            Quantity = request.Quantity,
            UnitPrice = request.UnitPrice,
            Unit = request.Unit ?? "pcs",
        };

        quote.Items.Add(item);

        // Recalculate quote total
        var newMaterialsCost = quote.Items.Sum(i => i.Total);
        quote.MaterialsCost = newMaterialsCost;
        quote.Total = quote.LaborCost + newMaterialsCost;

        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = quote.Id }, item);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult> Update(Guid id, [FromBody] UpdateTechnicalQuoteRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var quote = await _db.TechnicalQuotes
            .FirstOrDefaultAsync(q => q.Id == id && q.UserId == userId);

        if (quote == null) return NotFound();

        if (request.Title != null) quote.Title = request.Title;
        if (request.Description != null) quote.Description = request.Description;
        if (request.ValidUntil.HasValue) quote.ValidUntil = request.ValidUntil;

        // Recalculate total if hours or rate changed
        if (request.EstimatedHours.HasValue || request.HourlyRate.HasValue)
        {
            var hours = request.EstimatedHours ?? quote.EstimatedHours;
            var rate = request.HourlyRate ?? quote.HourlyRate;
            var laborCost = (decimal)hours * rate;
            quote.LaborCost = laborCost;
            quote.Total = laborCost + quote.MaterialsCost;
        }

        await _db.SaveChangesAsync();
        return Ok(quote);
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult> UpdateStatus(Guid id, [FromBody] UpdateQuoteStatusRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var quote = await _db.TechnicalQuotes
            .FirstOrDefaultAsync(q => q.Id == id && q.UserId == userId);

        if (quote == null) return NotFound();

        quote.Status = request.Status;
        if (request.Status == "Sent")
            quote.SentAt = DateTime.UtcNow;
        else if (request.Status == "Accepted")
            quote.AcceptedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync();
        return Ok(quote);
    }
}

public record CreateTechnicalQuoteRequest(
    Guid ClientId,
    string? Title,
    string? Description,
    string? ServiceLocation,
    double? EstimatedHours,
    decimal? HourlyRate,
    decimal? MaterialsCost,
    DateTime? ValidUntil
);

public record AddQuoteItemRequest(
    string? ItemName,
    string? ItemType,
    decimal Quantity,
    decimal UnitPrice,
    string? Unit
);

public record UpdateTechnicalQuoteRequest(
    string? Title,
    string? Description,
    decimal? EstimatedHours,
    decimal? HourlyRate,
    DateTime? ValidUntil
);

public record UpdateQuoteStatusRequest(string Status);
