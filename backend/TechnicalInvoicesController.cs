using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/technical-invoices")]
[Authorize]
public class TechnicalInvoicesController : ControllerBase
{
    private readonly ICurrentUser _currentUser;
    private readonly IAppDbContext _dbContext;
    private readonly IPdfService _pdfService;

    public TechnicalInvoicesController(ICurrentUser currentUser, IAppDbContext dbContext, IPdfService pdfService)
    {
        _currentUser = currentUser;
        _dbContext = dbContext;
        _pdfService = pdfService;
    }

    [HttpGet]
    public async Task<ActionResult<List<dynamic>>> GetInvoices([FromQuery] string? status)
    {
        var query = _dbContext.TechnicalInvoices
            .Where(i => i.UserId == _currentUser.UserId)
            .Include(i => i.Client)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
            query = query.Where(i => i.Status == status);

        var invoices = await query
            .OrderByDescending(i => i.InvoiceDate)
            .Select(i => new
            {
                i.Id,
                i.InvoiceNumber,
                i.Client!.Name,
                i.InvoiceDate,
                i.DueDate,
                i.Total,
                i.AmountPaid,
                Remaining = i.Total - i.AmountPaid,
                i.Status,
                DaysOverdue = i.DueDate < DateTime.Now && i.Status != "Paid" 
                    ? (DateTime.Now - i.DueDate).Days 
                    : 0
            })
            .ToListAsync();

        return Ok(invoices);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult> GetInvoice(Guid id)
    {
        var invoice = await _dbContext.TechnicalInvoices
            .Where(i => i.UserId == _currentUser.UserId && i.Id == id)
            .Include(i => i.Client)
            .Include(i => i.Payments)
            .Include(i => i.MaterialsUsed)
            .FirstOrDefaultAsync();

        if (invoice == null) return NotFound();
        return Ok(invoice);
    }

    [HttpPost]
    public async Task<ActionResult> CreateInvoice([FromBody] CreateTechnicalInvoiceRequest request)
    {
        var intervention = await _dbContext.TechnicalInterventions
            .FirstOrDefaultAsync(i => i.Id == Guid.Parse(request.InterventionId));
        
        if (intervention == null) return BadRequest("Intervention not found");

        var laborCost = intervention.ActualHours * request.HourlyRate;
        var total = laborCost + request.MaterialsCost;

        var invoice = new TechnicalInvoice
        {
            UserId = _currentUser.UserId,
            ClientId = intervention.ClientId,
            TechnicalInterventionId = intervention.Id,
            InvoiceNumber = $"FT-{DateTime.Now:yyyy}-{new Random().Next(1000, 9999)}",
            InvoiceDate = DateTime.Now,
            DueDate = DateTime.Now.AddDays(30),
            WorkStartDate = intervention.StartTime,
            WorkEndDate = intervention.EndTime ?? DateTime.Now,
            ServiceDescription = request.ServiceDescription,
            LocationOfWork = intervention.Location,
            HourlyRate = request.HourlyRate,
            ActualHours = intervention.ActualHours,
            MaterialsCost = request.MaterialsCost,
            AdvancePayment = request.AdvancePayment,
            SubTotal = laborCost + request.MaterialsCost,
            TaxAmount = (laborCost + request.MaterialsCost) * 0.15m, // 15% tax
            Total = total + ((laborCost + request.MaterialsCost) * 0.15m),
            Status = "Pending"
        };

        _dbContext.TechnicalInvoices.Add(invoice);
        await _dbContext.SaveChangesAsync();

        return CreatedAtAction(nameof(GetInvoice), new { id = invoice.Id }, invoice);
    }

    [HttpPost("{id}/record-payment")]
    public async Task<ActionResult> RecordPayment(Guid id, [FromBody] RecordPaymentRequest request)
    {
        var invoice = await _dbContext.TechnicalInvoices.FindAsync(id);
        if (invoice == null || invoice.UserId != _currentUser.UserId) return NotFound();

        var payment = new TechnicalPaymentRecord
        {
            TechnicalInvoiceId = id,
            Amount = request.Amount,
            PaymentDate = DateTime.Now,
            PaymentMethod = request.PaymentMethod,
            MobileMoneyOperator = request.MobileMoneyOperator,
            MobileMoneyReference = request.MobileMoneyReference,
            PhoneNumber = request.PhoneNumber,
            Status = "Completed",
            IsVerified = !string.IsNullOrEmpty(request.MobileMoneyReference)
        };

        invoice.AmountPaid += request.Amount;
        invoice.Status = invoice.AmountPaid >= invoice.Total ? "Paid" : "PartiallyPaid";

        _dbContext.TechnicalPaymentRecords.Add(payment);
        await _dbContext.SaveChangesAsync();

        return Ok(new { invoiceId = id, paymentId = payment.Id, invoice.Status });
    }

    [HttpPost("{id}/generate-pdf")]
    public async Task<ActionResult> GeneratePdf(Guid id)
    {
        var invoice = await _dbContext.TechnicalInvoices
            .Include(i => i.Client)
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == _currentUser.UserId);

        if (invoice == null) return NotFound();

        var pdfPath = await _pdfService.GenerateTechnicalInvoicePdf(invoice);
        invoice.PdfFilePath = pdfPath;

        await _dbContext.SaveChangesAsync();

        return Ok(new { pdfUrl = pdfPath, invoiceNumber = invoice.InvoiceNumber });
    }

    [HttpGet("{id}/download-pdf")]
    public async Task<ActionResult> DownloadPdf(Guid id)
    {
        var invoice = await _dbContext.TechnicalInvoices
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == _currentUser.UserId);

        if (invoice == null || string.IsNullOrEmpty(invoice.PdfFilePath)) return NotFound();

        var fileBytes = await System.IO.File.ReadAllBytesAsync(invoice.PdfFilePath);
        return File(fileBytes, "application/pdf", $"{invoice.InvoiceNumber}.pdf");
    }
}

public record CreateTechnicalInvoiceRequest(
    string InterventionId,
    string ServiceDescription,
    decimal HourlyRate,
    decimal MaterialsCost,
    decimal AdvancePayment
);

public record RecordPaymentRequest(
    decimal Amount,
    string PaymentMethod,
    string? MobileMoneyOperator,
    string? MobileMoneyReference,
    string? PhoneNumber
);
