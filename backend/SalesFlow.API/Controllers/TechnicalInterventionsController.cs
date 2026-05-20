using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/technical/interventions")]
[Authorize]
public class TechnicalInterventionsController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public TechnicalInterventionsController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult> List([FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var query = _db.TechnicalInterventions
            .Where(i => i.UserId == userId)
            .Include(i => i.Client);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(i => i.StartTime)
            .Skip((page - 1) * 20)
            .Take(20)
            .Select(i => new
            {
                i.Id,
                clientName = i.Client!.FullName,
                i.Notes,
                i.StartTime,
                i.Status,
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult> GetById(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var intervention = await _db.TechnicalInterventions
            .Where(i => i.Id == id && i.UserId == userId)
            .Include(i => i.Client)
            .FirstOrDefaultAsync();

        if (intervention == null) return NotFound();

        return Ok(new
        {
            intervention.Id,
            clientName = intervention.Client!.FullName,
            intervention.Notes,
            intervention.StartTime,
            intervention.Status,
        });
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateTechnicalInterventionRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var intervention = new TechnicalIntervention
        {
            UserId = userId,
            ClientId = request.ClientId,
            Notes = request.Notes ?? string.Empty,
            StartTime = request.StartTime,
            Status = "Scheduled",
        };

        _db.TechnicalInterventions.Add(intervention);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = intervention.Id }, intervention);
    }

    [HttpPatch("{id:guid}/complete")]
    public async Task<ActionResult> CompleteIntervention(Guid id, [FromBody] CompleteInterventionRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var intervention = await _db.TechnicalInterventions
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (intervention == null) return NotFound();

        intervention.Status = "Completed";
        await _db.SaveChangesAsync();

        return Ok(intervention);
    }

    [HttpPost("{id:guid}/checklist-items")]
    public async Task<ActionResult> AddChecklistItem(Guid id, [FromBody] AddChecklistItemRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var intervention = await _db.TechnicalInterventions
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (intervention == null) return NotFound();

        // ✅ FIXED: Use TechnicalChecklistItem instead of MaintenanceChecklistItem
        var checklistItem = new TechnicalChecklistItem
        {
            TechnicalInterventionId = id,
            Title = request.Title ?? string.Empty,
            IsCompleted = false,
        };

        // Add via DbSet for consistency
        _db.TechnicalChecklistItems.Add(checklistItem);
        await _db.SaveChangesAsync();

        return Ok(checklistItem);
    }

    [HttpPatch("{id:guid}/checklist-items/{itemId:guid}")]
    public async Task<ActionResult> UpdateChecklistItem(Guid id, Guid itemId, [FromBody] UpdateChecklistItemRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var checklistItem = await _db.TechnicalChecklistItems
            .Include(x => x.TechnicalIntervention)
            .Where(x => x.Id == itemId && x.TechnicalIntervention!.UserId == userId)
            .FirstOrDefaultAsync();

        if (checklistItem == null) return NotFound();

        checklistItem.IsCompleted = request.IsCompleted;
        await _db.SaveChangesAsync();

        return Ok(checklistItem);
    }

    [HttpPost("{id:guid}/checklist-items/{itemId:guid}/complete")]
    public async Task<ActionResult> CompleteChecklistItem(Guid id, Guid itemId)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var checklistItem = await _db.TechnicalChecklistItems
            .Include(x => x.TechnicalIntervention)
            .Where(x => x.Id == itemId && x.TechnicalIntervention!.UserId == userId)
            .FirstOrDefaultAsync();

        if (checklistItem == null) return NotFound();

        checklistItem.IsCompleted = true;
        await _db.SaveChangesAsync();

        return Ok(checklistItem);
    }
}

public record CreateTechnicalInterventionRequest(
    Guid ClientId,
    string? Notes,
    DateTime StartTime
);

public record CompleteInterventionRequest(
    string? Notes
);

public record AddChecklistItemRequest(
    string? Title
);

public record UpdateChecklistItemRequest(
    bool IsCompleted
);