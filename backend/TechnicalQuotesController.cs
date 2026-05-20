using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SalesFlow.Application.Technical.DTOs;
using SalesFlow.Application.Technical.Services;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/technical-quotes")]
[Authorize]
public class TechnicalQuotesController : ControllerBase
{
    private readonly ICurrentUser _currentUser;
    private readonly IAppDbContext _dbContext;
    private readonly ITechnicalCalculatorService _calculator;

    public TechnicalQuotesController(ICurrentUser currentUser, IAppDbContext dbContext, ITechnicalCalculatorService calculator)
    {
        _currentUser = currentUser;
        _dbContext = dbContext;
        _calculator = calculator;
    }

    [HttpGet]
    public async Task<ActionResult<List<TechnicalQuoteDto>>> GetQuotes()
    {
        var quotes = await _dbContext.TechnicalQuotes
            .Where(q => q.UserId == _currentUser.UserId)
            .Include(q => q.Client)
            .Select(q => new TechnicalQuoteDto(
                q.Id.ToString(),
                q.QuoteNumber,
                q.Title,
                q.Client!.Name,
                q.Status,
                q.MaterialsCost,
                q.LaborCost,
                q.Total,
                q.CreatedAt
            ))
            .ToListAsync();

        return Ok(quotes);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<dynamic>> GetQuote(Guid id)
    {
        var quote = await _dbContext.TechnicalQuotes
            .Where(q => q.UserId == _currentUser.UserId && q.Id == id)
            .Include(q => q.Client)
            .Include(q => q.Items)
            .FirstOrDefaultAsync();

        if (quote == null) return NotFound();
        return Ok(quote);
    }

    [HttpPost]
    public async Task<ActionResult> CreateQuote([FromBody] CreateTechnicalQuoteRequest request)
    {
        var client = await _dbContext.Clients.FirstOrDefaultAsync(c => c.Id == Guid.Parse(request.ClientId));
        if (client == null) return BadRequest("Client not found");

        var laborCost = request.EstimatedHours * request.HourlyRate;
        var materialsCost = request.Items.Sum(i => i.Quantity * i.UnitPrice);

        var quote = new TechnicalQuote
        {
            UserId = _currentUser.UserId,
            ClientId = Guid.Parse(request.ClientId),
            QuoteNumber = $"DT-{DateTime.Now:yyyy}-{new Random().Next(1000, 9999)}",
            Title = request.Title,
            ServiceLocation = request.ServiceLocation,
            EstimatedHours = request.EstimatedHours,
            HourlyRate = request.HourlyRate,
            MaterialsCost = materialsCost,
            LaborCost = laborCost,
            Total = laborCost + materialsCost,
            Items = request.Items.Select(i => new TechnicalQuoteItem
            {
                ItemName = i.ItemName,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                Unit = i.Unit
            }).ToList()
        };

        _dbContext.TechnicalQuotes.Add(quote);
        await _dbContext.SaveChangesAsync();

        return CreatedAtAction(nameof(GetQuote), new { id = quote.Id }, quote);
    }

    [HttpPost("{id}/calculate-cement")]
    public ActionResult CalculateCement(Guid id, [FromBody] decimal wallAreaSqMeters)
    {
        var result = _calculator.CalculateCementBags(wallAreaSqMeters);
        return Ok(result);
    }

    [HttpPost("{id}/calculate-outlets")]
    public ActionResult CalculateOutlets(Guid id, [FromBody] CalculateOutletsRequest request)
    {
        var result = _calculator.CalculateElectricalOutlets(request.Bedrooms, request.Bathrooms, request.Kitchens);
        return Ok(result);
    }

    [HttpPost("{id}/calculate-breakers")]
    public ActionResult CalculateBreakers(Guid id, [FromBody] CalculateBreakersRequest request)
    {
        var result = _calculator.CalculateCircuitBreakers(request.PowerLoadKW, request.BreakerType);
        return Ok(result);
    }

    [HttpPost("{id}/calculate-plumbing")]
    public ActionResult CalculatePlumbing(Guid id, [FromBody] CalculatePlumbingRequest request)
    {
        var result = _calculator.CalculatePlumbingPipes(request.Bathrooms, request.Kitchens);
        return Ok(result);
    }

    [HttpPut("{id}")]
    public async Task<ActionResult> UpdateQuote(Guid id, [FromBody] UpdateTechnicalQuoteRequest request)
    {
        var quote = await _dbContext.TechnicalQuotes.FindAsync(id);
        if (quote == null || quote.UserId != _currentUser.UserId) return NotFound();

        quote.Title = request.Title;
        quote.ServiceLocation = request.ServiceLocation;
        quote.EstimatedHours = request.EstimatedHours;
        quote.HourlyRate = request.HourlyRate;
        quote.Status = request.Status;

        await _dbContext.SaveChangesAsync();
        return Ok(quote);
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteQuote(Guid id)
    {
        var quote = await _dbContext.TechnicalQuotes.FindAsync(id);
        if (quote == null || quote.UserId != _currentUser.UserId) return NotFound();

        _dbContext.TechnicalQuotes.Remove(quote);
        await _dbContext.SaveChangesAsync();
        return Ok();
    }
}

public record CalculateOutletsRequest(int Bedrooms, int Bathrooms, int Kitchens);
public record CalculateBreakersRequest(decimal PowerLoadKW, string BreakerType);
public record CalculatePlumbingRequest(int Bathrooms, int Kitchens);
public record UpdateTechnicalQuoteRequest(string Title, string ServiceLocation, decimal EstimatedHours, decimal HourlyRate, string Status);
