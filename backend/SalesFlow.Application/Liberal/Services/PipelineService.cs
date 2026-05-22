using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Liberal.DTOs;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Liberal.Services;

public class PipelineService : IPipelineService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public PipelineService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<ProspectListResponse>> ListProspectsAsync(
        int page = 1,
        int pageSize = 20,
        string? stage = null,
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

        var query = _db.ProspectContacts
            .Where(p => p.UserId == userId)
            .Include(p => p.Events)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(stage))
            query = query.Where(p => p.Stage == stage);

        var total = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(p => p.Probability)
            .ThenByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => Map(p))
            .ToListAsync(ct);

        return Result<ProspectListResponse>.Success(
            new ProspectListResponse(items, total, page, pageSize)
        );
    }

    public async Task<Result<ProspectContactResponse>> GetProspectByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var prospect = await _db.ProspectContacts
            .Where(p => p.Id == id && p.UserId == userId)
            .Include(p => p.Events)
            .AsNoTracking()
            .FirstOrDefaultAsync(ct);

        return prospect is null
            ? Result<ProspectContactResponse>.Failure("Prospect introuvable.")
            : Result<ProspectContactResponse>.Success(Map(prospect));
    }

    public async Task<Result<ProspectContactResponse>> CreateProspectAsync(
        CreateProspectContactRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var prospect = new ProspectContact
        {
            UserId = userId,
            CompanyName = request.CompanyName.Trim(),
            ContactPerson = request.ContactPerson.Trim(),
            PhoneNumber = request.PhoneNumber?.Trim() ?? string.Empty,
            Email = request.Email?.Trim().ToLowerInvariant() ?? string.Empty,
            Source = request.Source?.Trim(),
            EstimatedValue = request.EstimatedValue,
            Stage = "Prospect",
            Probability = 20m,
            FirstContactDate = DateTime.UtcNow,
            Notes = request.Notes?.Trim()
        };

        _db.ProspectContacts.Add(prospect);
        await _db.SaveChangesAsync(ct);

        return await GetProspectByIdAsync(prospect.Id, ct);
    }

    public async Task<Result<ProspectContactResponse>> UpdateProspectAsync(
        Guid id,
        UpdateProspectContactRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var prospect = await _db.ProspectContacts
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        if (prospect is null)
            return Result<ProspectContactResponse>.Failure("Prospect introuvable.");

        prospect.CompanyName = request.CompanyName.Trim();
        prospect.ContactPerson = request.ContactPerson.Trim();
        prospect.PhoneNumber = request.PhoneNumber?.Trim() ?? string.Empty;
        prospect.Email = request.Email?.Trim().ToLowerInvariant() ?? string.Empty;
        prospect.EstimatedValue = request.EstimatedValue;
        prospect.Notes = request.Notes?.Trim();

        await _db.SaveChangesAsync(ct);

        return await GetProspectByIdAsync(id, ct);
    }

    public async Task<Result<ProspectContactResponse>> UpdateProspectStageAsync(
        Guid id,
        UpdateProspectStageRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var prospect = await _db.ProspectContacts
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        if (prospect is null)
            return Result<ProspectContactResponse>.Failure("Prospect introuvable.");

        prospect.Stage = request.Stage;
        prospect.Probability = CalculateProbability(request.Stage);
        prospect.LastContactDate = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);

        return await GetProspectByIdAsync(id, ct);
    }

    public async Task<Result<PipelineEventResponse>> LogEventAsync(
        Guid prospectId,
        CreatePipelineEventRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var prospect = await _db.ProspectContacts
            .FirstOrDefaultAsync(p => p.Id == prospectId && p.UserId == userId, ct);

        if (prospect is null)
            return Result<PipelineEventResponse>.Failure("Prospect introuvable.");

        var pipelineEvent = new PipelineEvent
        {
            ProspectContactId = prospectId,
            EventType = request.EventType.Trim(),
            EventDate = request.EventDate,
            Notes = request.Notes?.Trim(),
            IsRenewalEvent = request.IsRenewalEvent
        };

        _db.PipelineEvents.Add(pipelineEvent);

        // Le suivi NextFollowUp est stocké sur le prospect
        prospect.LastContactDate = request.EventDate;
        if (request.NextFollowUp.HasValue)
            prospect.NextFollowUpDate = request.NextFollowUp;

        await _db.SaveChangesAsync(ct);

        return Result<PipelineEventResponse>.Success(new PipelineEventResponse(
            pipelineEvent.Id,
            pipelineEvent.ProspectContactId,
            pipelineEvent.EventType,
            pipelineEvent.EventDate,
            pipelineEvent.Notes,
            pipelineEvent.IsRenewalEvent,
            pipelineEvent.CreatedAt
        ));
    }

    public async Task<Result<bool>> DeleteProspectAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var prospect = await _db.ProspectContacts
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId, ct);

        if (prospect is null)
            return Result<bool>.Failure("Prospect introuvable.");

        _db.ProspectContacts.Remove(prospect);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    private static ProspectContactResponse Map(ProspectContact p) => new(
        p.Id,
        p.CompanyName,
        p.ContactPerson,
        p.PhoneNumber,
        p.Email,
        p.Source,
        p.EstimatedValue,
        p.Stage,
        p.Probability,
        p.NextFollowUpDate,
        p.Notes,
        p.Events?.Count ?? 0,
        p.CreatedAt,
        p.UpdatedAt
    );

    private static decimal CalculateProbability(string stage) => stage switch
    {
        "Prospect" => 20m,
        "Discussion" => 40m,
        "Proposal" => 60m,
        "Negotiation" => 80m,
        "Signed" => 100m,
        "Lost" => 0m,
        _ => 20m
    };

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}
