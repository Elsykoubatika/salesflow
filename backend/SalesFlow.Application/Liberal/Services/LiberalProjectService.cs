using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Liberal.DTOs;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Liberal.Services;

public class LiberalProjectService : ILiberalProjectService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public LiberalProjectService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<LiberalProjectListResponse>> ListAsync(
        int page = 1,
        int pageSize = 20,
        string? status = null,
        bool activeOnly = false,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        page = page < 1 ? 1 : page;
        pageSize = pageSize switch
        {
            < 1 => DefaultPageSize,
            > MaxPageSize => MaxPageSize,
            _ => pageSize
        };

        var query = _db.LiberalProjects
            .Where(p => p.UserId == userId)
            .Include(p => p.Client)
            .Include(p => p.Deliverables)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(p => p.Status == status);

        if (activeOnly)
            query = query.Where(p => p.Status == "InProgress");

        var total = await query.CountAsync(ct);
        var activeCount = await _db.LiberalProjects.AsNoTracking()
            .Where(p => p.UserId == userId && p.Status == "InProgress")
            .CountAsync(ct);

        var items = await query
            .OrderBy(p => p.Status == "InProgress" ? 0 : 1)
            .ThenByDescending(p => p.StartDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => Map(p))
            .ToListAsync(ct);

        return Result<LiberalProjectListResponse>.Success(
            new LiberalProjectListResponse(items, total, activeCount, page, pageSize)
        );
    }

    public async Task<Result<LiberalProjectResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var project = await _db.LiberalProjects
            .Where(p => p.Id == id && p.UserId == userId)
            .Include(p => p.Client)
            .Include(p => p.Deliverables)
            .AsNoTracking()
            .FirstOrDefaultAsync(ct);

        return project is null
            ? Result<LiberalProjectResponse>.Failure("Projet introuvable.")
            : Result<LiberalProjectResponse>.Success(Map(project));
    }

    public async Task<Result<LiberalProjectResponse>> CreateAsync(
        CreateLiberalProjectRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var client = await _db.Clients.FirstOrDefaultAsync(
            c => c.Id == request.ClientId && c.UserId == userId, ct);
        if (client is null)
            return Result<LiberalProjectResponse>.Failure("Client introuvable.");

        if (request.EndDate <= request.StartDate)
            return Result<LiberalProjectResponse>.Failure(
                "La date de fin doit être après la date de début.");

        var project = new LiberalProject
        {
            UserId = userId,
            ClientId = request.ClientId,
            ProjectName = request.ProjectName.Trim(),
            Description = request.Description?.Trim() ?? string.Empty,
            ProjectType = request.ProjectType?.Trim() ?? string.Empty,
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            BudgetAmount = request.BudgetAmount,
            EstimatedHours = request.EstimatedHours,
            HourlyRate = request.HourlyRate,
            Status = "Planning",
            Notes = request.Notes?.Trim() ?? string.Empty
        };

        _db.LiberalProjects.Add(project);
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(project.Id, ct);
    }

    public async Task<Result<LiberalProjectResponse>> UpdateAsync(
        Guid id,
        UpdateLiberalProjectRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var project = await _db.LiberalProjects
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        if (project is null)
            return Result<LiberalProjectResponse>.Failure("Projet introuvable.");

        if (request.EndDate.HasValue && request.EndDate.Value <= project.StartDate)
            return Result<LiberalProjectResponse>.Failure(
                "La date de fin doit être après la date de début.");

        project.ProjectName = request.ProjectName.Trim();
        project.Description = request.Description?.Trim() ?? string.Empty;
        if (request.EndDate.HasValue)
            project.EndDate = request.EndDate.Value;
        project.BudgetAmount = request.BudgetAmount;
        project.Status = request.Status;
        project.Notes = request.Notes?.Trim() ?? string.Empty;

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<DeliverableResponse>> AddDeliverableAsync(
        CreateDeliverableRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var project = await _db.LiberalProjects
            .Include(p => p.Deliverables)
            .FirstOrDefaultAsync(p => p.Id == request.ProjectId && p.UserId == userId, ct);

        if (project is null)
            return Result<DeliverableResponse>.Failure("Projet introuvable.");

        if (request.DueDate <= DateTime.UtcNow)
            return Result<DeliverableResponse>.Failure(
                "La date limite doit être dans le futur.");

        var deliverable = new ProjectDeliverable
        {
            LiberalProjectId = request.ProjectId,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim() ?? string.Empty,
            DueDate = request.DueDate,
            IsCompleted = false,
            Order = (project.Deliverables?.Count ?? 0) + 1
        };

        _db.ProjectDeliverables.Add(deliverable);
        await _db.SaveChangesAsync(ct);

        return Result<DeliverableResponse>.Success(MapDeliverable(deliverable));
    }

    public async Task<Result<bool>> CompleteDeliverableAsync(Guid deliverableId, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var deliverable = await _db.ProjectDeliverables
            .Include(d => d.LiberalProject)
            .FirstOrDefaultAsync(
                d => d.Id == deliverableId && d.LiberalProject!.UserId == userId, ct);

        if (deliverable is null)
            return Result<bool>.Failure("Livrable introuvable.");

        deliverable.IsCompleted = true;
        deliverable.CompletedDate = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var project = await _db.LiberalProjects
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        if (project is null)
            return Result<bool>.Failure("Projet introuvable.");

        _db.LiberalProjects.Remove(project);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    private static LiberalProjectResponse Map(LiberalProject p)
    {
        var deliverableCount = p.Deliverables?.Count ?? 0;
        var completedCount = p.Deliverables?.Count(d => d.IsCompleted) ?? 0;
        var progress = deliverableCount == 0
            ? 0
            : (int)(completedCount * 100.0 / deliverableCount);

        return new LiberalProjectResponse(
            p.Id,
            p.ProjectName,
            p.Description,
            p.ProjectType,
            p.ClientId,
            p.Client?.FullName ?? "Client supprimé",
            p.StartDate,
            p.EndDate,
            p.BudgetAmount,
            p.EstimatedHours,
            p.HourlyRate,
            p.TotalInvoiced,
            progress,
            p.Status,
            p.Notes,
            deliverableCount,
            completedCount,
            p.CreatedAt,
            p.UpdatedAt
        );
    }

    private static DeliverableResponse MapDeliverable(ProjectDeliverable d) => new(
        d.Id,
        d.LiberalProjectId,
        d.Title,
        d.Description,
        d.DueDate,
        d.IsCompleted,
        d.CompletedDate,
        d.Order,
        d.CreatedAt
    );

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}
