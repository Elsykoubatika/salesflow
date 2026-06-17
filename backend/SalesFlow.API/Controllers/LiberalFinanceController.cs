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

    // Valeurs acceptées pour TransactionType — utilisées dans la validation
    private static readonly string[] ValidTransactionTypes =
        { "Debit", "Credit", "Income", "Expense", "Transfer" };

    public LiberalFinanceController(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    // ─── ACCOUNTS ────────────────────────────────────────────────────────────

    [HttpGet("accounts")]
    public async Task<ActionResult> ListAccounts([FromQuery] int page = 1)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var query = _db.FinanceAccounts.Where(a => a.UserId == userId);

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
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié");

        if (string.IsNullOrWhiteSpace(request.AccountName))
            return BadRequest(new { error = "Le nom du compte est requis." });

        var account = new FinanceAccount
        {
            UserId = userId,
            AccountName = request.AccountName.Trim(),
            CurrentBalance = request.InitialBalance ?? 0m,
            AccountType = request.AccountType ?? string.Empty,
        };

        _db.FinanceAccounts.Add(account);
        await _db.SaveChangesAsync();

        return CreatedAtAction(nameof(ListAccounts), new { id = account.Id }, account);
    }

    // ─── TRANSACTIONS ────────────────────────────────────────────────────────
    // Une seule méthode — validation stricte, supporte les anciens et nouveaux noms

    [HttpPost("accounts/{id:guid}/transaction")]
    public async Task<ActionResult> AddTransaction(
        Guid id,
        [FromBody] AddTransactionRequest request)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié");

        // ─── Validation stricte ─────────────────────────────────────────────
        if (string.IsNullOrWhiteSpace(request.TransactionType))
            return BadRequest(new { error = "Type de transaction requis." });

        if (!ValidTransactionTypes.Contains(request.TransactionType))
        {
            return BadRequest(new
            {
                error = $"Type de transaction invalide. " +
                        $"Valeurs acceptées : {string.Join(", ", ValidTransactionTypes)}."
            });
        }

        var amount = request.Amount ?? 0m;
        if (amount <= 0)
            return BadRequest(new { error = "Le montant doit être strictement positif." });

        // ─── Vérification du compte ─────────────────────────────────────────
        var account = await _db.FinanceAccounts
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (account == null)
            return NotFound(new { error = "Compte introuvable." });

        // ─── Détermination du sens du mouvement ─────────────────────────────
        // "Credit" et "Income"      → entrée (+)
        // "Debit", "Expense", "Transfer" → sortie (-)
        var isCredit = request.TransactionType is "Credit" or "Income";
        var isDebit = request.TransactionType is "Debit" or "Expense" or "Transfer";

        // ─── Vérification du solde pour les sorties ─────────────────────────
        if (isDebit && account.CurrentBalance < amount)
        {
            return BadRequest(new
            {
                error = $"Solde insuffisant. " +
                        $"Solde actuel : {account.CurrentBalance:N0} XAF, " +
                        $"montant demandé : {amount:N0} XAF."
            });
        }

        // ─── Mise à jour atomique du solde + création de la transaction ─────
        if (isCredit)
            account.CurrentBalance += amount;
        else if (isDebit)
            account.CurrentBalance -= amount;

        account.UpdatedAt = DateTime.UtcNow;

        var transaction = new FinanceTransaction
        {
            FinanceAccountId = id,
            TransactionType = request.TransactionType,
            Amount = amount,
            TransactionDate = request.TransactionDate ?? DateTime.UtcNow,
            Description = request.Description ?? string.Empty,
        };

        _db.FinanceTransactions.Add(transaction);
        await _db.SaveChangesAsync();

        return Ok(new
        {
            transaction.Id,
            newBalance = account.CurrentBalance,
            transaction.TransactionType,
            previousBalance = isCredit
                ? account.CurrentBalance - amount
                : account.CurrentBalance + amount,
            amount,
        });
    }

    // ─── BUDGET ──────────────────────────────────────────────────────────────

    [HttpPost("accounts/{id:guid}/budget")]
    public async Task<ActionResult> SetBudget(Guid id, [FromBody] SetBudgetRequest request)
    {
        var userId = _currentUser.UserId
            ?? throw new InvalidOperationException("Utilisateur non authentifié");

        var account = await _db.FinanceAccounts
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (account == null)
            return NotFound(new { error = "Compte introuvable." });

        var startDate = request.StartDate ?? DateTime.UtcNow;
        var endDate = request.EndDate ?? DateTime.UtcNow.AddMonths(1);

        if (endDate <= startDate)
            return BadRequest(new { error = "La date de fin doit être après la date de début." });

        var budget = new FinanceBudget
        {
            FinanceAccountId = id,
            PlannedAmount = request.PlannedAmount ?? 0m,
            Period = request.Period ?? string.Empty,
            StartDate = startDate,
            EndDate = endDate,
        };

        _db.FinanceBudgets.Add(budget);
        await _db.SaveChangesAsync();

        return Ok(budget);
    }
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
public record CreateFinanceAccountRequest(
    string? AccountName,
    decimal? InitialBalance,
    string? AccountType);

public record AddTransactionRequest(
    string? TransactionType,
    decimal? Amount,
    DateTime? TransactionDate,
    string? Description);

public record SetBudgetRequest(
    decimal? PlannedAmount,
    string? Period,
    DateTime? StartDate,
    DateTime? EndDate);