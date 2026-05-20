using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/liberal/contracts")]
[Authorize]
public class LiberalContractsController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public LiberalContractsController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult> List([FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var query = _db.LiberalContracts
            .Where(c => c.UserId == userId)
            .Include(c => c.Invoices);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(c => c.SignedDate ?? c.CreatedOn)
            .Skip((page - 1) * 20)
            .Take(20)
            .Select(c => new
            {
                c.Id,
                c.ContractNumber,
                c.EngagementType,
                invoiceCount = c.Invoices.Count,
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult> GetById(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var contract = await _db.LiberalContracts
            .Where(c => c.Id == id && c.UserId == userId)
            .Include(c => c.Invoices)
            .FirstOrDefaultAsync();

        if (contract == null) return NotFound();

        return Ok(new
        {
            contract.Id,
            contract.ContractNumber,
            contract.EngagementType,
            contract.SignedDate,
            contract.Notes,
        });
    }

    [HttpPost]
    public async Task<ActionResult> Create([FromBody] CreateLiberalContractRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var contract = new LiberalContract
        {
            UserId = userId,
            ClientId = request.ClientId,
            ContractNumber = $"CTR-{DateTime.Now:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 6)}",
            EngagementType = request.EngagementType ?? string.Empty,
            Notes = request.Notes,
        };

        _db.LiberalContracts.Add(contract);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = contract.Id }, contract);
    }

    [HttpPatch("{id:guid}/sign")]
    public async Task<ActionResult> SignContract(Guid id)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var contract = await _db.LiberalContracts
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

        if (contract == null) return NotFound();

        contract.SignedDate = DateTime.UtcNow;
        await _db.SaveChangesAsync();

        return Ok(contract);
    }

    [HttpPatch("{id:guid}/renew")]
    public async Task<ActionResult> RenewContract(Guid id, [FromBody] RenewContractRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var contract = await _db.LiberalContracts
            .FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

        if (contract == null) return NotFound();

        contract.RecurrencePattern = request.RecurrencePattern;
        await _db.SaveChangesAsync();

        return Ok(contract);
    }
}

public record CreateLiberalContractRequest(
    Guid ClientId,
    string? EngagementType,
    string? Notes
);

public record RenewContractRequest(
    string? RecurrencePattern
);
