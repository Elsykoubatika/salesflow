using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/prospects")]
[Authorize]
public class ProspectsController : ControllerBase
{
    private readonly ICurrentUser _currentUser;
    private readonly IAppDbContext _dbContext;

    public ProspectsController(ICurrentUser currentUser, IAppDbContext dbContext)
    {
        _currentUser = currentUser;
        _dbContext = dbContext;
    }

    [HttpGet]
    public async Task<ActionResult<List<dynamic>>> GetProspects([FromQuery] string? stage)
    {
        var query = _dbContext.ProspectContacts
            .Where(p => p.UserId == _currentUser.UserId)
            .AsQueryable();

        if (!string.IsNullOrEmpty(stage))
            query = query.Where(p => p.Stage == stage);

        var prospects = await query
            .OrderByDescending(p => p.LastContactDate)
            .Select(p => new
            {
                p.Id,
                p.CompanyName,
                p.ContactPerson,
                p.Email,
                p.PhoneNumber,
                p.Stage,
                p.EstimatedValue,
                p.Probability,
                p.FirstContactDate,
                p.LastContactDate,
                p.NextFollowUpDate,
                p.RenewalDate,
                EventCount = p.Events.Count,
                LastEvent = p.Events.OrderByDescending(e => e.EventDate).FirstOrDefault()!.EventType
            })
            .ToListAsync();

        return Ok(prospects);
    }

    [HttpGet("pipeline-stats")]
    public async Task<ActionResult> GetPipelineStats()
    {
        var prospects = await _dbContext.ProspectContacts
            .Where(p => p.UserId == _currentUser.UserId)
            .ToListAsync();

        var stats = new
        {
            TotalProspects = prospects.Count,
            ByStage = new
            {
                Prospect = prospects.Count(p => p.Stage == "Prospect"),
                Discussion = prospects.Count(p => p.Stage == "Discussion"),
                Proposal = prospects.Count(p => p.Stage == "Proposal"),
                Negotiation = prospects.Count(p => p.Stage == "Negotiation"),
                Signed = prospects.Count(p => p.Stage == "Signed"),
                Lost = prospects.Count(p => p.Stage == "Lost")
            },
            TotalPipelineValue = prospects.Sum(p => p.EstimatedValue),
            AverageProbability = prospects.Any() ? prospects.Average(p => p.Probability) : 0,
            NeedingRenewal = prospects.Count(p => p.NeedsRenewal)
        };

        return Ok(stats);
    }

    [HttpPost]
    public async Task<ActionResult> CreateProspect([FromBody] CreateProspectRequest request)
    {
        var prospect = new ProspectContact
        {
            UserId = _currentUser.UserId,
            CompanyName = request.CompanyName,
            ContactPerson = request.ContactPerson,
            Email = request.Email,
            PhoneNumber = request.PhoneNumber,
            Stage = "Prospect",
            Source = request.Source,
            FirstContactDate = DateTime.Now,
            EstimatedValue = request.EstimatedValue,
            Probability = 20, // Default 20% for new prospect
            Notes = request.Notes
        };

        _dbContext.ProspectContacts.Add(prospect);
        await _dbContext.SaveChangesAsync();

        return CreatedAtAction(nameof(GetProspects), new { id = prospect.Id }, prospect);
    }

    [HttpPut("{id}/stage")]
    public async Task<ActionResult> UpdateStage(Guid id, [FromBody] UpdateStageRequest request)
    {
        var prospect = await _dbContext.ProspectContacts
            .Include(p => p.Events)
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == _currentUser.UserId);

        if (prospect == null) return NotFound();

        var oldStage = prospect.Stage;
        prospect.Stage = request.Stage;
        prospect.LastContactDate = DateTime.Now;
        prospect.Probability = request.Stage switch
        {
            "Prospect" => 20,
            "Discussion" => 40,
            "Proposal" => 60,
            "Negotiation" => 75,
            "Signed" => 100,
            "Lost" => 0,
            _ => prospect.Probability
        };

        // Log event
        var stageEvent = new PipelineEvent
        {
            ProspectContactId = id,
            EventType = $"Stage changed from {oldStage} to {request.Stage}",
            EventDate = DateTime.Now,
            Notes = request.Notes
        };

        _dbContext.PipelineEvents.Add(stageEvent);
        await _dbContext.SaveChangesAsync();

        return Ok(prospect);
    }

    [HttpPost("{id}/event")]
    public async Task<ActionResult> LogEvent(Guid id, [FromBody] LogEventRequest request)
    {
        var prospect = await _dbContext.ProspectContacts.FindAsync(id);
        if (prospect == null || prospect.UserId != _currentUser.UserId) return NotFound();

        var @event = new PipelineEvent
        {
            ProspectContactId = id,
            EventType = request.EventType,
            EventDate = request.EventDate,
            Notes = request.Notes,
            IsRenewalEvent = request.IsRenewalEvent
        };

        prospect.LastContactDate = DateTime.Now;
        prospect.NextFollowUpDate = request.NextFollowUp;

        _dbContext.PipelineEvents.Add(@event);
        await _dbContext.SaveChangesAsync();

        return Ok(@event);
    }

    [HttpPost("{id}/schedule-renewal")]
    public async Task<ActionResult> ScheduleRenewal(Guid id, [FromBody] ScheduleRenewalRequest request)
    {
        var prospect = await _dbContext.ProspectContacts.FindAsync(id);
        if (prospect == null || prospect.UserId != _currentUser.UserId) return NotFound();

        prospect.RenewalDate = request.RenewalDate;
        prospect.NeedsRenewal = true;

        if (request.AddReminder)
        {
            prospect.RenewalReminders ??= new List<string>();
            prospect.RenewalReminders.Add(request.RenewalDate.AddDays(-30).ToString("O"));
        }

        await _dbContext.SaveChangesAsync();
        return Ok(prospect);
    }
}

public record CreateProspectRequest(
    string CompanyName,
    string ContactPerson,
    string Email,
    string PhoneNumber,
    string? Source,
    decimal EstimatedValue,
    string? Notes
);

public record UpdateStageRequest(
    string Stage,
    string? Notes
);

public record LogEventRequest(
    string EventType,
    DateTime EventDate,
    string? Notes,
    bool IsRenewalEvent,
    DateTime? NextFollowUp
);

public record ScheduleRenewalRequest(
    DateTime RenewalDate,
    bool AddReminder
);
