using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/liberal/pipeline")]
[Authorize]
public class LiberalPipelineController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public LiberalPipelineController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult> List([FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var query = _db.ProspectContacts
            .Where(p => p.UserId == userId)
            .Include(p => p.Events);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(p => p.CreatedOn)
            .Skip((page - 1) * 20)
            .Take(20)
            .Select(p => new
            {
                p.Id,
                p.CompanyName,
                p.ContactPerson,
                p.Probability,
                eventCount = p.Events.Count(),
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult> GetById(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var prospect = await _db.ProspectContacts
            .Where(p => p.Id == id && p.UserId == userId)
            .Include(p => p.Events)
            .FirstOrDefaultAsync();

        if (prospect == null) return NotFound();

        return Ok(new
        {
            prospect.Id,
            prospect.CompanyName,
            prospect.ContactPerson,
            prospect.PhoneNumber,
            prospect.Email,
            prospect.Probability,
            events = prospect.Events.Select(e => new
            {
                e.Id,
                e.EventType,
                e.Notes,
                e.EventDate,
            }).ToList(),
        });
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateProspectContactRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var prospect = new ProspectContact
        {
            UserId = userId,
            CompanyName = request.CompanyName ?? string.Empty,
            ContactPerson = request.ContactPerson ?? string.Empty,
            // Safely falling back to empty strings if the entity properties are non-nullable
            PhoneNumber = request.PhoneNumber ?? string.Empty,
            Email = request.Email ?? string.Empty,
            Probability = request.Probability ?? 0, // Keep ?? 0 ONLY if request.Probability is nullable (e.g., int?)
        };

        _db.ProspectContacts.Add(prospect);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = prospect.Id }, prospect);
    }

    [HttpPost("{id:guid}/event")]
    public async Task<ActionResult> AddEvent(Guid id, [FromBody] AddPipelineEventRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var prospect = await _db.ProspectContacts
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (prospect == null) return NotFound();

        var pipelineEvent = new PipelineEvent
        {
            ProspectContactId = id,
            EventType = request.EventType ?? string.Empty,
            EventDate = request.EventDate ?? DateTime.UtcNow,
            Notes = request.Notes,
        };

        prospect.Events.Add(pipelineEvent);
        await _db.SaveChangesAsync();

        return Ok(pipelineEvent);
    }

    [HttpPatch("{id:guid}/probability")]
    public async Task<ActionResult> UpdateProbability(Guid id, [FromBody] UpdateProbabilityRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var prospect = await _db.ProspectContacts
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (prospect == null) return NotFound();

        prospect.Probability = request.Probability ?? prospect.Probability;
        await _db.SaveChangesAsync();

        return Ok(new { prospect.Id, prospect.Probability });
    }
}

public record CreateProspectContactRequest(
    string? CompanyName,
    string? ContactPerson,
    string? PhoneNumber,
    string? Email,
    int? Probability
);

public record AddPipelineEventRequest(
    string? EventType,
    DateTime? EventDate,
    string? Notes
);

public record UpdateProbabilityRequest(
    int? Probability
);
