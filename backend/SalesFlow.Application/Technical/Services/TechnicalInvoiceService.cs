using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace SalesFlow.Application.Technical.Services;

public class TechnicalInvoiceService : ITechnicalInvoiceService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public TechnicalInvoiceService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    public async Task<Result<TechnicalInvoiceListResponse>> ListAsync(
    int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        page = page < 1 ? 1 : page;
        pageSize = pageSize switch { < 1 => DefaultPageSize, > MaxPageSize => MaxPageSize, _ => pageSize };

        var query = _db.TechnicalInvoices
            .Where(i => i.UserId == userId)
            .Include(i => i.Client)
            .AsNoTracking();

        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(i => i.Status == status);

        var total = await query.CountAsync(ct);
        var overdueCount = await query.Where(i => i.DueDate < DateTime.UtcNow && i.Status != "Paid").CountAsync(ct);

        var items = await query
            .OrderByDescending(i => i.InvoiceDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(i => MapInvoice(i))
            .ToListAsync(ct);

        return Result<TechnicalInvoiceListResponse>.Success(
            new TechnicalInvoiceListResponse(items, total, overdueCount, page, pageSize)
        );
    }

    public async Task<Result<TechnicalInvoiceResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var invoice = await _db.TechnicalInvoices.AsNoTracking()
            .Include(i => i.Client)
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);

        return invoice is null
            ? Result<TechnicalInvoiceResponse>.Failure("Facture introuvable.")
            : Result<TechnicalInvoiceResponse>.Success(MapInvoice(invoice));
    }

    public async Task<Result<TechnicalInvoiceResponse>> CreateAsync(CreateTechnicalInvoiceRequest request, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var client = await _db.Clients.FirstOrDefaultAsync(c => c.Id == request.ClientId && c.UserId == userId, ct);
        if (client is null)
            return Result<TechnicalInvoiceResponse>.Failure("Client introuvable.");

        decimal laborCost = request.ActualHours * request.HourlyRate;
        decimal subTotal = laborCost + request.MaterialsCost;
        decimal taxAmount = subTotal * 0.19m;
        decimal total = subTotal + taxAmount;
        decimal amountDue = total - request.AdvancePayment;

        var invoice = new TechnicalInvoice
        {
            UserId = userId,
            ClientId = request.ClientId,
            InvoiceNumber = GenerateInvoiceNumber(),
            InvoiceDate = DateTime.UtcNow,
            DueDate = DateTime.UtcNow.AddDays(30),
            WorkStartDate = request.WorkStartDate,
            WorkEndDate = request.WorkEndDate,
            ServiceDescription = request.ServiceDescription.Trim(),
            LocationOfWork = request.LocationOfWork.Trim(),
            HourlyRate = request.HourlyRate,
            ActualHours = request.ActualHours,
            MaterialsCost = request.MaterialsCost,
            TaxAmount = taxAmount,
            AdvancePayment = request.AdvancePayment,
            Total = total,
            Currency = "XAF",
            Status = "Pending",
            TechnicalInterventionId = request.TechnicalInterventionId,
            TechnicalQuoteId = request.TechnicalQuoteId
        };

        _db.TechnicalInvoices.Add(invoice);
        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(invoice.Id, ct);
    }

    public async Task<Result<bool>> SendAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var invoice = await _db.TechnicalInvoices.FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);
        if (invoice is null)
            return Result<bool>.Failure("Facture introuvable.");

        invoice.Status = "Sent";
        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> MarkPaidAsync(Guid id, decimal amountPaid, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var invoice = await _db.TechnicalInvoices.FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);
        if (invoice is null)
            return Result<bool>.Failure("Facture introuvable.");

        invoice.AmountPaid = amountPaid;
        invoice.PaidDate = DateTime.UtcNow;
        invoice.Status = amountPaid >= invoice.Total ? "Paid" : "PartiallyPaid";

        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();
        var invoice = await _db.TechnicalInvoices.FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId, ct);
        if (invoice is null)
            return Result<bool>.Failure("Facture introuvable.");
        if (invoice.Status != "Pending")
            return Result<bool>.Failure("Seule une facture en attente peut être supprimée.");

        _db.TechnicalInvoices.Remove(invoice);
        await _db.SaveChangesAsync(ct);
        return Result<bool>.Success(true);
    }

    private static TechnicalInvoiceResponse MapInvoice(TechnicalInvoice i) => new(
        i.Id, i.InvoiceNumber, i.ClientId, i.Client?.FullName ?? "Client supprimé",
        i.InvoiceDate, i.DueDate, i.HourlyRate, i.ActualHours,
        i.LaborCost, i.MaterialsCost, i.SubTotal, i.TaxAmount,
        i.AdvancePayment, i.Total, i.AmountDue,
        i.DueDate < DateTime.UtcNow && i.Status != "Paid" ? "Overdue" : i.Status,
        i.CreatedAt, i.UpdatedAt
    );

    private static string GenerateInvoiceNumber() => $"INV-TECH-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6).ToUpper()}";

    private Guid RequireUserId() => _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}