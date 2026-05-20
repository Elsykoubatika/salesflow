using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/technical/invoices")]
[Authorize]
public class TechnicalInvoicesController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public TechnicalInvoicesController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult> List([FromQuery] string? status = null, [FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        // ✅ FIX: Explicitly type as IQueryable to allow appending .Where later without casting issues
        IQueryable<TechnicalInvoice> query = _db.TechnicalInvoices
            .Where(i => i.UserId == userId)
            .Include(i => i.Client);

        if (!string.IsNullOrEmpty(status))
            query = query.Where(i => i.Status == status);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(i => i.InvoiceDate)
            .Skip((page - 1) * 20)
            .Take(20)
            .Select(i => new
            {
                i.Id,
                i.InvoiceNumber,
                clientName = i.Client!.FullName,
                i.Status,
                i.Total,
                amountDue = i.Total - i.AdvancePayment - i.OtherDeductions,
                i.InvoiceDate,
                i.DueDate,
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult> GetById(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var invoice = await _db.TechnicalInvoices
            .Where(i => i.Id == id && i.UserId == userId)
            .Include(i => i.Client)
            .FirstOrDefaultAsync();

        if (invoice == null) return NotFound();

        return Ok(new
        {
            invoice.Id,
            invoice.InvoiceNumber,
            clientName = invoice.Client!.FullName,
            invoice.ServiceDescription,
            invoice.LaborCost,
            invoice.ActualHours,
            invoice.MaterialsCost,
            invoice.Total,
            amountDue = invoice.Total - invoice.AdvancePayment - invoice.OtherDeductions,
            invoice.AdvancePayment,
            invoice.Status,
            invoice.InvoiceDate,
            invoice.DueDate,
            invoice.PaidDate,
            invoice.Currency,
            invoice.Notes,
        });
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateTechnicalInvoiceRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var laborTotal = (decimal)(request.ActualHours ?? 0d) * (request.HourlyRateXAF ?? 50_000m);
        var total = laborTotal + (request.MaterialsCost ?? 0m);

        var invoice = new TechnicalInvoice
        {
            UserId = userId,
            ClientId = request.ClientId,
            InvoiceNumber = $"FAC-{DateTime.Now:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6)}",
            ServiceDescription = request.Description ?? string.Empty,
            ActualHours = (decimal)(request.ActualHours ?? 0d),
            HourlyRate = request.HourlyRateXAF ?? 50_000m,
            MaterialsCost = request.MaterialsCost ?? 0m,
            AdvancePayment = request.AdvancePayment ?? 0m,
            TaxAmount = 0m,
            Total = total,
            Status = "Draft",
            InvoiceDate = DateTime.UtcNow,
            DueDate = DateTime.UtcNow.AddDays(30),
            WorkStartDate = DateTime.UtcNow,
            WorkEndDate = DateTime.UtcNow,
            LocationOfWork = string.Empty,
            Notes = request.Notes,
            Currency = "XAF",
        };

        _db.TechnicalInvoices.Add(invoice);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = invoice.Id }, invoice);
    }

    [HttpPost("{id:guid}/payment")]
    public async Task<ActionResult> RecordPayment(Guid id, [FromBody] RecordPaymentRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var invoice = await _db.TechnicalInvoices
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (invoice == null) return NotFound();
        if (request.AmountXAF <= 0) return BadRequest(new { error = "Le montant doit être positif" });

        // ✅ FIX: Removed '??' because invoice.AmountPaid is a regular non-nullable decimal
        invoice.AmountPaid += request.AmountXAF;
        invoice.PaidDate = request.PaidAt ?? DateTime.UtcNow;
        invoice.Status = invoice.AmountPaid >= invoice.Total ? "Paid" : "PartiallyPaid";

        var payment = new TechnicalPaymentRecord
        {
            TechnicalInvoiceId = id,
            Amount = request.AmountXAF,
            PaymentDate = request.PaidAt ?? DateTime.UtcNow,
            PaymentMethod = request.PaymentMethod ?? string.Empty,
            MobileMoneyReference = request.Reference,
            Notes = request.Notes,
        };

        _db.TechnicalPaymentRecords.Add(payment);
        await _db.SaveChangesAsync();

        // ✅ FIX: Removed '??' here as well
        var amountDue = invoice.Total - invoice.AmountPaid;
        return Ok(new
        {
            invoice.Id,
            amountPaid = request.AmountXAF,
            remainingDue = amountDue,
            status = invoice.Status,
        });
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult> UpdateStatus(Guid id, [FromBody] UpdateInvoiceStatusRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var invoice = await _db.TechnicalInvoices
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (invoice == null) return NotFound();

        invoice.Status = request.Status;
        await _db.SaveChangesAsync();
        return Ok(invoice);
    }
}

public record CreateTechnicalInvoiceRequest(Guid ClientId, string Description, double? ActualHours, decimal? HourlyRateXAF, decimal? MaterialsCost, decimal? AdvancePayment, string? Notes);
public record RecordPaymentRequest(decimal AmountXAF, string? PaymentMethod, string? Reference, DateTime? PaidAt, string? Notes);
public record UpdateInvoiceStatusRequest(string Status);