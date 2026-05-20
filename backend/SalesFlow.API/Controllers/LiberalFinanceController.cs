using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Security;
using SalesFlow.Domain.Entities;

namespace SalesFlow.API.Controllers;

[ApiController]
[Route("api/liberal/finance")]
[Authorize]
public class LiberalFinanceController : ControllerBase
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    public LiberalFinanceController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    [HttpGet("accounts")]
    public async Task<ActionResult> ListAccounts([FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var query = _db.FinanceAccounts
            .Where(a => a.UserId == userId);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(a => a.CreatedOn)
            .Skip((page - 1) * 20)
            .Take(20)
            .Select(a => new
            {
                a.Id,
                a.AccountName,
                a.CurrentBalance,
                a.AccountType,
            })
            .ToListAsync();

        return Ok(new { items, total });
    }

    [HttpPost("accounts")]
    public async Task<ActionResult> CreateAccount([FromBody] CreateFinanceAccountRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var account = new FinanceAccount
        {
            UserId = userId,
            AccountName = request.AccountName ?? string.Empty,
            CurrentBalance = request.InitialBalance ?? 0m,
            AccountType = request.AccountType ?? string.Empty,
        };

        _db.FinanceAccounts.Add(account);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(ListAccounts), new { id = account.Id }, account);
    }

    [HttpPost("accounts/{id:guid}/transaction")]
    public async Task<ActionResult> AddTransaction(Guid id, [FromBody] AddTransactionRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var account = await _db.FinanceAccounts
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (account == null) return NotFound();

        if (request.TransactionType == "Debit")
            account.CurrentBalance -= (request.Amount ?? 0m);
        else if (request.TransactionType == "Credit")
            account.CurrentBalance += (request.Amount ?? 0m);

        // ✅ FIX: Cast DateTime? to DateTime
        var transactionDate = request.TransactionDate ?? DateTime.UtcNow;

        var transaction = new FinanceTransaction
        {
            FinanceAccountId = id,
            TransactionType = request.TransactionType ?? string.Empty,
            Amount = request.Amount ?? 0m,
            TransactionDate = transactionDate,
            Description = request.Description ?? string.Empty,
        };

        _db.FinanceTransactions.Add(transaction);
        await _db.SaveChangesAsync();

        return Ok(new
        {
            transaction.Id,
            newBalance = account.CurrentBalance,
            transaction.TransactionType,
        });
    }

    [HttpPost("accounts/{id:guid}/budget")]
    public async Task<ActionResult> SetBudget(Guid id, [FromBody] SetBudgetRequest request)
    {
        var userId = _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié");
        var account = await _db.FinanceAccounts
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (account == null) return NotFound();

        var budget = new FinanceBudget
        {
            FinanceAccountId = id,
            PlannedAmount = request.PlannedAmount ?? 0m,
            Period = request.Period ?? string.Empty,
            StartDate = request.StartDate ?? DateTime.UtcNow,
            EndDate = request.EndDate ?? DateTime.UtcNow.AddMonths(1),
        };

        _db.FinanceBudgets.Add(budget);
        await _db.SaveChangesAsync();

        return Ok(budget);
    }
}

public record CreateFinanceAccountRequest(string? AccountName, decimal? InitialBalance, string? AccountType);
public record AddTransactionRequest(string? TransactionType, decimal? Amount, DateTime? TransactionDate, string? Description);
public record SetBudgetRequest(decimal? PlannedAmount, string? Period, DateTime? StartDate, DateTime? EndDate);
