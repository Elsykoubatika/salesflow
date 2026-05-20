using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/technical/maintenance")]
[Authorize]
public class TechnicalMaintenanceController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public TechnicalMaintenanceController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult> List([FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var query = _db.MaintenancePlans
            .Where(m => m.UserId == userId)
            .Include(m => m.Tasks);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(m => m.CreatedOn)
            .Skip((page - 1) * 20)
            .Take(20)
            .Select(m => new
            {
                m.Id,
                m.PlanName,
                m.Frequency,
                m.Status,
                taskCount = m.Tasks.Count,
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult> GetById(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var plan = await _db.MaintenancePlans
            .Where(m => m.Id == id && m.UserId == userId)
            .Include(m => m.Tasks)
            .FirstOrDefaultAsync();

        if (plan == null) return NotFound();

        return Ok(new
        {
            plan.Id,
            plan.PlanName,
            plan.Description,
            plan.Frequency,
            plan.Status,
            tasks = plan.Tasks.Select(t => new
            {
                t.Id,
                t.Title,
                t.Status,
                t.DueDate,
            }).ToList(),
        });
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateMaintenancePlanRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var plan = new MaintenancePlan
        {
            UserId = userId,
            PlanName = request.PlanName ?? string.Empty,
            Description = request.Description ?? string.Empty,
            Frequency = request.Frequency ?? string.Empty,
            Status = "Active",
        };

        _db.MaintenancePlans.Add(plan);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = plan.Id }, plan);
    }

    [HttpPost("{id:guid}/task")]
    public async Task<ActionResult> AddTask(Guid id, [FromBody] AddMaintenanceTaskRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var plan = await _db.MaintenancePlans
            .FirstOrDefaultAsync(m => m.Id == id && m.UserId == userId);

        if (plan == null) return NotFound();

        var task = new MaintenanceTask
        {
            MaintenancePlanId = id,
            Title = request.Title ?? string.Empty,
            Description = request.Description ?? string.Empty,
            DueDate = request.DueDate ?? DateTime.UtcNow,
            EstimatedHours = request.EstimatedHours ?? 0m,
            Status = "Pending",
        };

        plan.Tasks.Add(task);
        await _db.SaveChangesAsync();

        return Ok(task);
    }

    [HttpPatch("{id:guid}/task/{taskId:guid}")]
    public async Task<ActionResult> CompleteTask(Guid id, Guid taskId, [FromBody] CompleteMaintenanceTaskRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var plan = await _db.MaintenancePlans
            .Include(m => m.Tasks)
            .FirstOrDefaultAsync(m => m.Id == id && m.UserId == userId);

        if (plan == null) return NotFound();

        var task = plan.Tasks.FirstOrDefault(t => t.Id == taskId);
        if (task == null) return NotFound();

        task.Status = "Completed";
        
        // Safely handle nullable values with null-coalescing
        var actualHours = request.ActualHours ?? 0m;
        var costPerHour = request.CostPerHour ?? 0m;
        
        task.ActualHours = actualHours;
        await _db.SaveChangesAsync();

        return Ok(task);
    }
}

public record CreateMaintenancePlanRequest(
    string? PlanName,
    string? Description,
    string? Frequency
);

public record AddMaintenanceTaskRequest(
    string? Title,
    string? Description,
    DateTime? DueDate,
    decimal? EstimatedHours
);

public record CompleteMaintenanceTaskRequest(
    decimal? ActualHours,
    decimal? CostPerHour
);
