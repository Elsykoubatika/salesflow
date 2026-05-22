using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Query;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Technical.DTOs;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Technical.Services;

public class TechnicalInterventionService : ITechnicalInterventionService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public TechnicalInterventionService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<TechnicalInterventionListResponse>> ListAsync(
    int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        page = page < 1 ? 1 : page;
        pageSize = pageSize switch { < 1 => DefaultPageSize, > MaxPageSize => MaxPageSize, _ => pageSize };

        var query = _db.TechnicalInterventions
            .Where(i => i.UserId == userId)
            .Include(i => i.Client)
            .Include(i => i.ChecklistItems)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(i => i.Status == status);

        var total = await query.CountAsync(ct);
        var inProgressCount = await query.Where(i => i.Status == "InProgress").CountAsync(ct);

        var items = await query
            .OrderBy(i => i.Status == "InProgress" ? 0 : 1)
            .ThenByDescending(i => i.StartTime)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(i => MapIntervention(i))
            .ToListAsync(ct);

        return Result<TechnicalInterventionListResponse>.Success(
            new TechnicalInterventionListResponse(items, total, inProgressCount, page, pageSize)
        );
    }

    public async Task<Result<TechnicalInterventionResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var intervention = await _db.TechnicalInterventions.AsNoTracking()
            .Include(i => i.Client)
            .Include(i => i.ChecklistItems)
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        return intervention is null
            ? Result<TechnicalInterventionResponse>.Failure("Intervention introuvable.")
            : Result<TechnicalInterventionResponse>.Success(MapIntervention(intervention));
    }

    public async Task<Result<TechnicalInterventionResponse>> CreateAsync(CreateTechnicalInterventionRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var client = await _db.Clients.FirstOrDefaultAsync(c => c.Id == request.ClientId && c.UserId == userId, ct);
        if (client is null)
            return Result<TechnicalInterventionResponse>.Failure("Client introuvable.");

        if (request.StartTime < DateTime.UtcNow)
            return Result<TechnicalInterventionResponse>.Failure("La date de début doit être dans le futur.");

        var intervention = new TechnicalIntervention
        {
            UserId = userId,
            ClientId = request.ClientId,
            InterventionNumber = GenerateInterventionNumber(),
            Title = request.Title.Trim(),
            Location = request.Location.Trim(),
            StartTime = request.StartTime,
            TechnicalQuoteId = request.TechnicalQuoteId,
            Status = "InProgress"
        };

        _db.TechnicalInterventions.Add(intervention);
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(intervention.Id, ct);
    }

    public async Task<Result<TechnicalInterventionResponse>> UpdateAsync(Guid id, UpdateTechnicalInterventionRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var intervention = await _db.TechnicalInterventions.FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);
        if (intervention is null)
            return Result<TechnicalInterventionResponse>.Failure("Intervention introuvable.");

        intervention.Title = request.Title.Trim();
        intervention.Location = request.Location.Trim();
        intervention.EndTime = request.EndTime;
        intervention.Notes = request.Notes?.Trim() ?? string.Empty;
        intervention.TotalAmount = request.TotalAmount;

        await _db.SaveChangesAsync(ct);
        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<TechnicalInterventionResponse>> CompleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var intervention = await _db.TechnicalInterventions.FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);
        if (intervention is null)
            return Result<TechnicalInterventionResponse>.Failure("Intervention introuvable.");

        intervention.Status = "Completed";
        intervention.EndTime ??= DateTime.UtcNow;
        intervention.CompletedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);
        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<TechnicalChecklistItemResponse>> AddChecklistItemAsync(Guid interventionId, string title, string task, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var intervention = await _db.TechnicalInterventions
            .FirstOrDefaultAsync(i => i.Id == interventionId && i.UserId == userId, ct);

        if (intervention is null)
            return Result<TechnicalChecklistItemResponse>.Failure("Intervention introuvable.");

        var item = new TechnicalChecklistItem
        {
            TechnicalInterventionId = interventionId,
            Title = title.Trim(),
            Task = task.Trim(),
            IsCompleted = false
        };

        _db.TechnicalChecklistItems.Add(item);
        await _db.SaveChangesAsync(ct);

        return Result<TechnicalChecklistItemResponse>.Success(new TechnicalChecklistItemResponse(
            item.Id, item.Title, item.IsCompleted, item.CompletedAt, item.Task
        ));
    }

    public async Task<Result<bool>> CompleteChecklistItemAsync(Guid checklistItemId, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var item = await _db.TechnicalChecklistItems
            .Include(c => c.TechnicalIntervention)
            .FirstOrDefaultAsync(c => c.Id == checklistItemId && c.TechnicalIntervention!.UserId == userId, ct);

        if (item is null)
            return Result<bool>.Failure("Élément de checklist introuvable.");

        item.IsCompleted = true;
        item.CompletedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var intervention = await _db.TechnicalInterventions.FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);
        if (intervention is null)
            return Result<bool>.Failure("Intervention introuvable.");
        if (intervention.Status == "Completed")
            return Result<bool>.Failure("Une intervention complétée ne peut pas être supprimée.");

        _db.TechnicalInterventions.Remove(intervention);
        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    private static TechnicalInterventionResponse MapIntervention(TechnicalIntervention i) => new(
        i.Id, i.InterventionNumber, i.Title, i.Location, i.ClientId, i.Client?.FullName ?? "Client supprimé",
        i.StartTime, i.EndTime, i.ActualHours, i.Status, i.Notes,
        i.ChecklistItems?.Count ?? 0, i.CreatedAt, i.UpdatedAt
    );

    private static string GenerateInterventionNumber() => $"INT-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6).ToUpper()}";

    private Guid RequireUserId() => _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}