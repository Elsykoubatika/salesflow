using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/liberal/projects")]
[Authorize]
public class LiberalProjectsController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public LiberalProjectsController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult> List([FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var query = _db.LiberalProjects
            .Where(p => p.UserId == userId)
            .Include(p => p.Deliverables);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(p => p.CreatedOn)
            .Skip((page - 1) * 20)
            .Take(20)
            .Select(p => new
            {
                p.Id,
                p.ProjectName,
                p.Status,
                p.BudgetAmount,
                p.TotalInvoiced,
                progress = p.Deliverables.Count > 0 
                    ? (double)p.Deliverables.Count(d => d.IsCompleted) / p.Deliverables.Count * 100 
                    : 0,
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult> GetById(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var project = await _db.LiberalProjects
            .Where(p => p.Id == id && p.UserId == userId)
            .Include(p => p.Deliverables)
            .Include(p => p.Tasks)
            .FirstOrDefaultAsync();

        if (project == null) return NotFound();

        var completedDeliverables = project.Deliverables.Count(d => d.IsCompleted);
        var totalDeliverables = project.Deliverables.Count;
        var progress = totalDeliverables > 0 
            ? (double)completedDeliverables / totalDeliverables * 100 
            : 0;

        return Ok(new
        {
            project.Id,
            project.ProjectName,
            project.Description,
            project.Status,
            project.BudgetAmount,
            project.TotalInvoiced,
            project.TotalPaid,
            progress,
            deliverables = project.Deliverables.Select(d => new
            {
                d.Id,
                d.Title,
                d.DueDate,
                d.IsCompleted,
            }).ToList(),
            tasks = project.Tasks.Select(t => new
            {
                t.Id,
                t.Title,
                t.Status,
                t.Priority,
            }).ToList(),
        });
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateLiberalProjectRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var project = new LiberalProject
        {
            UserId = userId,
            ClientId = request.ClientId,
            ProjectName = request.ProjectName ?? string.Empty,
            Description = request.Description ?? string.Empty,
            ProjectType = request.ProjectType ?? string.Empty,
            StartDate = request.StartDate ?? DateTime.UtcNow,
            EndDate = request.EndDate ?? DateTime.UtcNow.AddMonths(1),
            BudgetAmount = request.BudgetAmount ?? 0m,
            Status = "Planning",
        };

        _db.LiberalProjects.Add(project);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = project.Id }, project);
    }

    [HttpPost("{id:guid}/deliverable")]
    public async Task<ActionResult> AddDeliverable(Guid id, [FromBody] AddDeliverableRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var project = await _db.LiberalProjects
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (project == null) return NotFound();

        var deliverable = new ProjectDeliverable
        {
            LiberalProjectId = id,
            Title = request.Title ?? string.Empty,
            Description = request.Description ?? string.Empty,
            DueDate = request.DueDate ?? DateTime.UtcNow,
            IsCompleted = false,
        };

        project.Deliverables.Add(deliverable);
        await _db.SaveChangesAsync();

        return Ok(deliverable);
    }

    [HttpPatch("{id:guid}/deliverable/{deliverableId:guid}")]
    public async Task<ActionResult> CompleteDeliverable(Guid id, Guid deliverableId)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var project = await _db.LiberalProjects
            .Include(p => p.Deliverables)
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (project == null) return NotFound();

        var deliverable = project.Deliverables.FirstOrDefault(d => d.Id == deliverableId);
        if (deliverable == null) return NotFound();

        deliverable.IsCompleted = true;
        deliverable.CompletedDate = DateTime.UtcNow;
        
        await _db.SaveChangesAsync();

        return Ok(deliverable);
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult> UpdateStatus(Guid id, [FromBody] UpdateProjectStatusRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var project = await _db.LiberalProjects
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (project == null) return NotFound();

        project.Status = request.Status ?? project.Status;
        await _db.SaveChangesAsync();

        return Ok(project);
    }
}

public record CreateLiberalProjectRequest(
    Guid ClientId,
    string? ProjectName,
    string? Description,
    string? ProjectType,
    DateTime? StartDate,
    DateTime? EndDate,
    decimal? BudgetAmount
);

public record AddDeliverableRequest(
    string? Title,
    string? Description,
    DateTime? DueDate
);

public record UpdateProjectStatusRequest(
    string? Status
);
