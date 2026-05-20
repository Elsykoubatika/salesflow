using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/liberal-contracts")]
[Authorize]
public class LiberalContractsController : ControllerBase
{
    private readonly ICurrentUser _currentUser;
    private readonly IAppDbContext _dbContext;

    public LiberalContractsController(ICurrentUser currentUser, IAppDbContext dbContext)
    {
        _currentUser = currentUser;
        _dbContext = dbContext;
    }

    [HttpGet]
    public async Task<ActionResult<List<dynamic>>> GetContracts([FromQuery] string? status)
    {
        var query = _dbContext.LiberalContracts
            .Where(c => c.UserId == _currentUser.UserId)
            .Include(c => c.Client)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status))
            query = query.Where(c => c.Status == status);

        var contracts = await query
            .OrderByDescending(c => c.StartDate)
            .Select(c => new
            {
                c.Id,
                c.ContractNumber,
                c.Client!.Name,
                c.ContractName,
                c.PricingModel,
                Rate = c.PricingModel == "Hourly" ? c.HourlyRate 
                     : c.PricingModel == "Daily" ? c.DailyRate 
                     : c.ProjectRate,
                c.Status,
                c.StartDate,
                c.EndDate,
                c.TotalBilled,
                c.TotalPaid,
                Remaining = c.TotalBilled - c.TotalPaid,
                IsRecurring = c.IsRecurring,
                NextRenewal = c.NextRenewalDate
            })
            .ToListAsync();

        return Ok(contracts);
    }

    [HttpPost]
    public async Task<ActionResult> CreateContract([FromBody] CreateLiberalContractRequest request)
    {
        var contract = new LiberalContract
        {
            UserId = _currentUser.UserId,
            ClientId = Guid.Parse(request.ClientId),
            ContractNumber = $"CT-{DateTime.Now:yyyy}-{new Random().Next(10000, 99999)}",
            ContractName = request.ContractName,
            ServiceDescription = request.ServiceDescription,
            PricingModel = request.PricingModel,
            HourlyRate = request.PricingModel == "Hourly" ? request.Rate : null,
            DailyRate = request.PricingModel == "Daily" ? request.Rate : null,
            ProjectRate = request.PricingModel == "Project" ? request.Rate : null,
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            EngagementType = request.EngagementType,
            Status = "Draft",
            IsRecurring = request.IsRecurring,
            RecurrencePattern = request.RecurrencePattern,
            AutoRenew = request.AutoRenew,
            NextRenewalDate = request.IsRecurring 
                ? CalculateNextRenewal(request.StartDate, request.RecurrencePattern)
                : null
        };

        _dbContext.LiberalContracts.Add(contract);
        await _dbContext.SaveChangesAsync();

        return CreatedAtAction(nameof(GetContracts), new { id = contract.Id }, contract);
    }

    [HttpPost("{id}/sign")]
    public async Task<ActionResult> SignContract(Guid id)
    {
        var contract = await _dbContext.LiberalContracts.FindAsync(id);
        if (contract == null || contract.UserId != _currentUser.UserId) return NotFound();

        contract.Status = "Signed";
        contract.SignedDate = DateTime.Now;

        // Create renewal reminder if recurring
        if (contract.IsRecurring && contract.NextRenewalDate.HasValue)
        {
            var reminder = new RenewalReminder
            {
                UserId = _currentUser.UserId,
                ContractId = id,
                ReminderDate = contract.NextRenewalDate.Value.AddDays(-30),
                ContractRenewalDate = contract.NextRenewalDate.Value,
                Status = "Pending",
                IsAutomated = true
            };
            _dbContext.RenewalReminders.Add(reminder);
        }

        await _dbContext.SaveChangesAsync();
        return Ok(contract);
    }

    [HttpPost("{id}/invoice")]
    public async Task<ActionResult> CreateInvoice(Guid id, [FromBody] CreateLiberalInvoiceRequest request)
    {
        var contract = await _dbContext.LiberalContracts.FindAsync(id);
        if (contract == null || contract.UserId != _currentUser.UserId) return NotFound();

        decimal baseAmount = contract.PricingModel switch
        {
            "Hourly" => (decimal)request.TotalHours * contract.HourlyRate.GetValueOrDefault(),
            "Daily" => request.TotalHours / 8 * contract.DailyRate.GetValueOrDefault(),
            "Project" => contract.ProjectRate.GetValueOrDefault(),
            _ => 0
        };

        var invoice = new LiberalInvoice
        {
            UserId = _currentUser.UserId,
            ContractId = id,
            ClientId = contract.ClientId,
            InvoiceNumber = $"FT-LIB-{DateTime.Now:yyyy}-{new Random().Next(10000, 99999)}",
            InvoiceDate = DateTime.Now,
            DueDate = DateTime.Now.AddDays(30),
            ServiceStartDate = request.StartDate,
            ServiceEndDate = request.EndDate,
            TotalHours = request.TotalHours,
            BaseAmount = baseAmount,
            ComplexityMultiplier = request.ComplexityMultiplier,
            TaxAmount = baseAmount * request.ComplexityMultiplier * 0.15m,
            AdvancePayment = request.AdvancePayment,
            Total = baseAmount * request.ComplexityMultiplier + (baseAmount * request.ComplexityMultiplier * 0.15m),
            DeliverableDetails = request.DeliverableDetails,
            Status = "Pending"
        };

        _dbContext.LiberalInvoices.Add(invoice);
        contract.TotalBilled += invoice.Total;
        await _dbContext.SaveChangesAsync();

        return CreatedAtAction(nameof(CreateInvoice), new { id = invoice.Id }, invoice);
    }

    private DateTime? CalculateNextRenewal(DateTime startDate, string? pattern)
    {
        return pattern switch
        {
            "Monthly" => startDate.AddMonths(1),
            "Quarterly" => startDate.AddMonths(3),
            "Yearly" => startDate.AddYears(1),
            _ => null
        };
    }
}

public record CreateLiberalContractRequest(
    string ClientId,
    string ContractName,
    string ServiceDescription,
    string PricingModel, // Hourly, Daily, Project
    decimal Rate,
    DateTime StartDate,
    DateTime? EndDate,
    string EngagementType, // Project, Monthly, Yearly, Recurring
    bool IsRecurring,
    string? RecurrencePattern,
    bool AutoRenew
);

public record CreateLiberalInvoiceRequest(
    DateTime StartDate,
    DateTime EndDate,
    decimal TotalHours,
    decimal ComplexityMultiplier,
    decimal AdvancePayment,
    string? DeliverableDetails
);
