using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Query;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Technical.Services;

public class TechnicalMaintenanceService : ITechnicalMaintenanceService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public TechnicalMaintenanceService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<IEnumerable<MaintenancePlanResponse>>> ListPlansAsync(bool activeOnly = true, CancellationToken ct = default)
{
    var userId = RequireUserId();
    var query = _db.MaintenancePlans
        .Where(p => p.UserId == userId)
        .Include(p => p.Client)
        .Include(p => p.Tasks)
        .AsNoTracking();

    if (activeOnly)
        query = query.Where(p => p.Status == "Active");

    var plans = await query
        .OrderByDescending(p => p.Status == "Active" ? 0 : 1)
        .ThenBy(p => p.NextScheduledDate)
        .Select(p => MapPlan(p))
        .ToListAsync(ct);

    return Result<IEnumerable<MaintenancePlanResponse>>.Success(plans);
}

    public async Task<Result<MaintenancePlanResponse>> GetPlanByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var plan = await _db.MaintenancePlans.AsNoTracking()
            .Include(p => p.Client)
            .Include(p => p.Tasks)
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        return plan is null
            ? Result<MaintenancePlanResponse>.Failure("Plan introuvable.")
            : Result<MaintenancePlanResponse>.Success(MapPlan(plan));
    }

    public async Task<Result<MaintenancePlanResponse>> CreatePlanAsync(CreateMaintenancePlanRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var client = await _db.Clients.FirstOrDefaultAsync(c => c.Id == request.ClientId && c.UserId == userId, ct);
        if (client is null)
            return Result<MaintenancePlanResponse>.Failure("Client introuvable.");

        var plan = new MaintenancePlan
        {
            UserId = userId,
            ClientId = request.ClientId,
            PlanName = request.PlanName.Trim(),
            AssetName = request.AssetName.Trim(),
            AssetModel = request.AssetModel?.Trim(),
            Description = request.Description?.Trim(),
            Frequency = request.Frequency,
            EstimatedCost = request.EstimatedCost,
            EstimatedDuration = request.EstimatedDuration,
            NextScheduledDate = request.NextScheduledDate,
            Status = "Active"
        };

        _db.MaintenancePlans.Add(plan);
        await _db.SaveChangesAsync(ct);

        return await GetPlanByIdAsync(plan.Id, ct);
    }

    public async Task<Result<MaintenanceTaskResponse>> AddTaskAsync(Guid planId, string title, DateTime dueDate, decimal estimatedHours, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var plan = await _db.MaintenancePlans.FirstOrDefaultAsync(p => p.Id == planId && p.UserId == userId, ct);
        if (plan is null)
            return Result<MaintenanceTaskResponse>.Failure("Plan introuvable.");

        var task = new MaintenanceTask
        {
            MaintenancePlanId = planId,
            Title = title.Trim(),
            TaskName = title.Trim(),
            DueDate = dueDate,
            EstimatedHours = estimatedHours,
            Status = "Pending",
            IsCompleted = false
        };

        _db.MaintenanceTasks.Add(task);
        await _db.SaveChangesAsync(ct);

        return Result<MaintenanceTaskResponse>.Success(MapTask(task));
    }

    public async Task<Result<bool>> CompleteTaskAsync(Guid taskId, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var task = await _db.MaintenanceTasks
            .Include(t => t.Plan)
            .FirstOrDefaultAsync(t => t.Id == taskId && t.Plan!.UserId == userId, ct);

        if (task is null)
            return Result<bool>.Failure("Tâche introuvable.");

        task.IsCompleted = true;
        task.CompletedAt = DateTime.UtcNow;
        task.Status = "Completed";

        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> DeletePlanAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var plan = await _db.MaintenancePlans.FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);
        if (plan is null)
            return Result<bool>.Failure("Plan introuvable.");

        _db.MaintenancePlans.Remove(plan);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    private static MaintenancePlanResponse MapPlan(MaintenancePlan p) => new(
        p.Id, p.PlanName, p.AssetName, p.AssetModel, p.ClientId,
        p.Client?.FullName ?? "Client supprimé", p.Frequency, p.EstimatedCost,
        p.Status, p.NextScheduledDate, p.Tasks?.Count ?? 0, p.CreatedAt
    );

    private static MaintenanceTaskResponse MapTask(MaintenanceTask t) => new(
        t.Id, t.MaintenancePlanId, t.Title, t.Status, t.DueDate,
        t.EstimatedHours, t.IsCompleted, t.CompletedAt
    );

    private Guid RequireUserId() => _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}