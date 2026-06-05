using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Liberal.DTOs;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Liberal.Services;

public class LiberalContractService : ILiberalContractService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public LiberalContractService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<LiberalContractListResponse>> ListAsync(
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

        var query = _db.LiberalContracts
            .Where(c => c.UserId == userId)
            .Include(c => c.Client)
            .Include(c => c.Invoices)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(c => c.Status == status);

        if (activeOnly)
            query = query.Where(c => c.Status == "Active");

        var total = await query.CountAsync(ct);
        var activeCount = await _db.LiberalContracts.AsNoTracking()
            .Where(c => c.UserId == userId && c.Status == "Active")
            .CountAsync(ct);

        var items = await query
            .OrderByDescending(c => c.SignedDate ?? c.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(c => Map(c))
            .ToListAsync(ct);

        return Result<LiberalContractListResponse>.Success(
            new LiberalContractListResponse(items, total, activeCount, page, pageSize)
        );
    }

    public async Task<Result<LiberalContractResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var contract = await _db.LiberalContracts
            .Where(c => c.Id == id && c.UserId == userId)
            .Include(c => c.Client)
            .Include(c => c.Invoices)
            .AsNoTracking()
            .FirstOrDefaultAsync(ct);

        return contract is null
            ? Result<LiberalContractResponse>.Failure("Contrat introuvable.")
            : Result<LiberalContractResponse>.Success(Map(contract));
    }

    public async Task<Result<LiberalContractResponse>> CreateAsync(
        CreateLiberalContractRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var client = await _db.Clients.FirstOrDefaultAsync(
            c => c.Id == request.ClientId && c.UserId == userId, ct);
        if (client is null)
            return Result<LiberalContractResponse>.Failure("Client introuvable.");

        if (request.EndDate.HasValue && request.EndDate <= request.StartDate)
            return Result<LiberalContractResponse>.Failure(
                "La date de fin doit être après la date de début.");

        if (request.IsRecurring && string.IsNullOrWhiteSpace(request.RecurrencePattern))
            return Result<LiberalContractResponse>.Failure(
                "Motif de récurrence requis pour contrat récurrent.");

        var contract = new LiberalContract
        {
            UserId = userId,
            ClientId = request.ClientId,
            ContractNumber = GenerateContractNumber(),
            ContractName = request.ContractName.Trim(),
            ServiceDescription = request.ServiceDescription?.Trim() ?? string.Empty,
            PricingModel = request.PricingModel,
            HourlyRate = request.PricingModel == "Hourly" ? request.Rate : null,
            DailyRate = request.PricingModel == "Daily" ? request.Rate : null,
            ProjectRate = request.PricingModel == "Project" ? request.Rate : null,
            MonthlyRetainer = request.PricingModel == "Retainer" ? request.Rate : null,
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            EngagementType = request.EngagementType,
            IsRecurring = request.IsRecurring,
            RecurrencePattern = request.RecurrencePattern,
            AutoRenew = request.AutoRenew,
            Status = "Draft",
            Notes = request.Notes?.Trim()
        };

        _db.LiberalContracts.Add(contract);
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(contract.Id, ct);
    }

    public async Task<Result<LiberalContractResponse>> UpdateAsync(
        Guid id,
        UpdateLiberalContractRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var contract = await _db.LiberalContracts
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId, ct);

        if (contract is null)
            return Result<LiberalContractResponse>.Failure("Contrat introuvable.");

        if (contract.Status != "Draft")
            return Result<LiberalContractResponse>.Failure(
                "Seul un brouillon peut être modifié.");

        if (request.EndDate.HasValue && request.StartDate.HasValue
            && request.EndDate <= request.StartDate)
            return Result<LiberalContractResponse>.Failure(
                "La date de fin doit être après la date de début.");

        contract.ContractName = request.ContractName.Trim();
        contract.ServiceDescription = request.ServiceDescription?.Trim() ?? string.Empty;
        contract.PricingModel = request.PricingModel;
        contract.HourlyRate = request.PricingModel == "Hourly" ? request.Rate : null;
        contract.DailyRate = request.PricingModel == "Daily" ? request.Rate : null;
        contract.ProjectRate = request.PricingModel == "Project" ? request.Rate : null;
        contract.MonthlyRetainer = request.PricingModel == "Retainer" ? request.Rate : null;
        if (request.StartDate.HasValue)
            contract.StartDate = request.StartDate.Value;
        contract.EndDate = request.EndDate;
        if (!string.IsNullOrWhiteSpace(request.EngagementType))
            contract.EngagementType = request.EngagementType;
        contract.IsRecurring = request.IsRecurring;
        contract.RecurrencePattern = request.RecurrencePattern;
        contract.AutoRenew = request.AutoRenew;
        contract.Notes = request.Notes?.Trim();

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<LiberalContractResponse>> SignAsync(
        Guid id,
        SignContractRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var contract = await _db.LiberalContracts
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId, ct);

        if (contract is null)
            return Result<LiberalContractResponse>.Failure("Contrat introuvable.");

        if (contract.Status != "Draft" && contract.Status != "Proposed")
            return Result<LiberalContractResponse>.Failure(
                "Seul un brouillon ou devis peut être signé.");

        contract.Status = "Signed";
        contract.SignedDate = request.SignDate;

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<LiberalContractResponse>> RenewAsync(
        Guid id,
        RenewContractRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var contract = await _db.LiberalContracts
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId, ct);

        if (contract is null)
            return Result<LiberalContractResponse>.Failure("Contrat introuvable.");

        if (!contract.IsRecurring)
            return Result<LiberalContractResponse>.Failure(
                "Seul un contrat récurrent peut être renouvelé.");

        contract.RecurrencePattern = request.RecurrencePattern;
        contract.NextRenewalDate = request.NextRenewalDate;

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var contract = await _db.LiberalContracts
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId, ct);

        if (contract is null)
            return Result<bool>.Failure("Contrat introuvable.");

        if (contract.Status != "Draft")
            return Result<bool>.Failure("Seul un brouillon peut être supprimé.");

        _db.LiberalContracts.Remove(contract);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    private static LiberalContractResponse Map(LiberalContract c) => new(
        c.Id,
        c.ContractNumber,
        c.ContractName,
        c.ServiceDescription,
        c.ClientId,
        c.Client?.FullName ?? "Client supprimé",
        c.PricingModel,
        c.HourlyRate ?? c.DailyRate ?? c.ProjectRate ?? c.MonthlyRetainer,
        c.StartDate,
        c.EndDate,
        c.EngagementType,
        c.IsRecurring,
        c.RecurrencePattern,
        c.AutoRenew,
        c.Status,
        c.SignedDate,
        c.TotalBilled,
        c.TotalPaid,
        c.Notes,
        c.Invoices?.Count ?? 0,
        c.CreatedAt,
        c.UpdatedAt
    );

    private static string GenerateContractNumber()
        => $"CTR-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6).ToUpper()}";

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}
