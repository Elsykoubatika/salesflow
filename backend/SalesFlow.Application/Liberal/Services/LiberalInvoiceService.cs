using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Liberal.DTOs;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Liberal.Services;

public class LiberalInvoiceService : ILiberalInvoiceService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public LiberalInvoiceService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<LiberalInvoiceListResponse>> ListAsync(
        int page = 1,
        int pageSize = 20,
        string? status = null,
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

        var query = _db.LiberalInvoices
            .Where(i => i.UserId == userId)
            .Include(i => i.Contract)
            .Include(i => i.Client)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(i => i.Status == status);

        var total = await query.CountAsync(ct);
        var overdueCount = await query
            .Where(i => i.Status == "Overdue" || (i.Status != "Paid" && i.DueDate < DateTime.UtcNow))
            .CountAsync(ct);

        var items = await query
            .OrderByDescending(i => i.InvoiceDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(i => Map(i))
            .ToListAsync(ct);

        return Result<LiberalInvoiceListResponse>.Success(
            new LiberalInvoiceListResponse(items, total, overdueCount, page, pageSize)
        );
    }

    public async Task<Result<LiberalInvoiceResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var invoice = await _db.LiberalInvoices
            .Where(i => i.Id == id && i.UserId == userId)
            .Include(i => i.Contract)
            .Include(i => i.Client)
            .AsNoTracking()
            .FirstOrDefaultAsync(ct);

        return invoice is null
            ? Result<LiberalInvoiceResponse>.Failure("Facture introuvable.")
            : Result<LiberalInvoiceResponse>.Success(Map(invoice));
    }

    public async Task<Result<LiberalInvoiceResponse>> CreateAsync(
        CreateLiberalInvoiceRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var contract = await _db.LiberalContracts
            .Include(c => c.Client)
            .FirstOrDefaultAsync(c => c.Id == request.ContractId && c.UserId == userId, ct);

        if (contract is null)
            return Result<LiberalInvoiceResponse>.Failure("Contrat introuvable.");

        var baseAmount = CalculateBaseAmount(contract, request.TotalHours);
        var subTotal = baseAmount * request.ComplexityMultiplier;
        var taxAmount = subTotal * 0.19m; // 19% TVA
        var total = subTotal + taxAmount - request.AdvancePayment;

        var invoice = new LiberalInvoice
        {
            UserId = userId,
            ContractId = request.ContractId,
            ClientId = contract.ClientId,
            InvoiceNumber = GenerateInvoiceNumber(),
            InvoiceDate = DateTime.UtcNow,
            DueDate = DateTime.UtcNow.AddDays(30),
            ServiceStartDate = request.ServiceStartDate,
            ServiceEndDate = request.ServiceEndDate,
            TotalHours = request.TotalHours,
            BaseAmount = baseAmount,
            ComplexityMultiplier = request.ComplexityMultiplier,
            TaxAmount = taxAmount,
            AdvancePayment = request.AdvancePayment,
            Total = Math.Max(0, total),
            Status = "Draft"
        };

        _db.LiberalInvoices.Add(invoice);
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(invoice.Id, ct);
    }

    public async Task<Result<LiberalInvoiceResponse>> UpdateAsync(
        Guid id,
        UpdateLiberalInvoiceRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var invoice = await _db.LiberalInvoices
            .Include(i => i.Contract)
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (invoice is null)
            return Result<LiberalInvoiceResponse>.Failure("Facture introuvable.");

        if (invoice.Status != "Draft")
            return Result<LiberalInvoiceResponse>.Failure(
                "Seul un brouillon peut être modifié.");

        var baseAmount = CalculateBaseAmount(invoice.Contract!, request.TotalHours);
        var subTotal = baseAmount * request.ComplexityMultiplier;
        var taxAmount = subTotal * 0.19m;
        var total = subTotal + taxAmount - request.AdvancePayment;

        invoice.TotalHours = request.TotalHours;
        invoice.BaseAmount = baseAmount;
        invoice.ComplexityMultiplier = request.ComplexityMultiplier;
        invoice.TaxAmount = taxAmount;
        invoice.AdvancePayment = request.AdvancePayment;
        invoice.Total = Math.Max(0, total);

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<bool>> SendAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var invoice = await _db.LiberalInvoices
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (invoice is null)
            return Result<bool>.Failure("Facture introuvable.");

        if (invoice.Status != "Draft")
            return Result<bool>.Failure("Seul un brouillon peut être envoyé.");

        invoice.Status = "Sent";
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> MarkPaidAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var invoice = await _db.LiberalInvoices
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (invoice is null)
            return Result<bool>.Failure("Facture introuvable.");

        invoice.Status = "Paid";
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var invoice = await _db.LiberalInvoices
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        if (invoice is null)
            return Result<bool>.Failure("Facture introuvable.");

        if (invoice.Status != "Draft")
            return Result<bool>.Failure("Seul un brouillon peut être supprimé.");

        _db.LiberalInvoices.Remove(invoice);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    private static decimal CalculateBaseAmount(LiberalContract contract, decimal totalHours)
    {
        return contract.PricingModel switch
        {
            "Hourly" => contract.HourlyRate.GetValueOrDefault() * totalHours,
            "Daily" => contract.DailyRate.GetValueOrDefault() * (totalHours / 8),
            "Project" => contract.ProjectRate.GetValueOrDefault(),
            "Retainer" => contract.MonthlyRetainer.GetValueOrDefault(),
            _ => 0
        };
    }

    private static LiberalInvoiceResponse Map(LiberalInvoice i) => new(
        i.Id,
        i.InvoiceNumber,
        i.ContractId,
        i.Contract?.ContractName ?? "Contrat supprimé",
        i.ClientId,
        i.Client?.FullName ?? "Client supprimé",
        i.InvoiceDate,
        i.DueDate,
        i.ServiceStartDate,
        i.ServiceEndDate,
        i.TotalHours,
        i.ComplexityMultiplier,
        i.SubTotal,
        i.TaxAmount,
        i.AdvancePayment,
        i.Total,
        i.DueDate < DateTime.UtcNow && i.Status != "Paid" ? "Overdue" : i.Status,
        i.CreatedAt,
        i.UpdatedAt
    );

    private static string GenerateInvoiceNumber()
        => $"INV-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6).ToUpper()}";

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}
