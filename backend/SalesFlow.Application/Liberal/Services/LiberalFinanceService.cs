using Microsoft.EntityFrameworkCore;
using SalesFlow.Application.Common.Interfaces;
using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Common.Security;
using SalesFlow.Application.Liberal.DTOs;
using SalesFlow.Domain.Entities;

namespace SalesFlow.Application.Liberal.Services;

public class LiberalFinanceService : ILiberalFinanceService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;

    private const int MaxPageSize = 100;
    private const int DefaultPageSize = 20;

    public LiberalFinanceService(IAppDbContext db, ICurrentUser currentUser)
    {
        _db = db;
        _currentUser = currentUser;
    }

    // ===== ACCOUNTS =====

    public async Task<Result<FinanceAccountListResponse>> ListAccountsAsync(
        int page = 1,
        int pageSize = 20,
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

        var query = _db.FinanceAccounts
            .Where(a => a.UserId == userId)
            .Include(a => a.Transactions)
            .AsNoTracking();

        var total = await query.CountAsync(ct);
        var totalBalance = await query.SumAsync(a => a.CurrentBalance, ct);

        var items = await query
            .OrderByDescending(a => a.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(a => MapAccount(a))
            .ToListAsync(ct);

        return Result<FinanceAccountListResponse>.Success(
            new FinanceAccountListResponse(items, total, totalBalance, page, pageSize)
        );
    }

    public async Task<Result<FinanceAccountResponse>> GetAccountAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var account = await _db.FinanceAccounts
            .Where(a => a.Id == id && a.UserId == userId)
            .Include(a => a.Transactions)
            .AsNoTracking()
            .FirstOrDefaultAsync(ct);

        return account is null
            ? Result<FinanceAccountResponse>.Failure("Compte introuvable.")
            : Result<FinanceAccountResponse>.Success(MapAccount(account));
    }

    public async Task<Result<FinanceAccountResponse>> CreateAccountAsync(
        CreateFinanceAccountRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var account = new FinanceAccount
        {
            UserId = userId,
            AccountName = request.AccountName.Trim(),
            Description = request.Description?.Trim() ?? string.Empty,
            AccountType = request.AccountType,
            CurrentBalance = request.OpeningBalance,
            Currency = "XAF"
        };

        _db.FinanceAccounts.Add(account);
        await _db.SaveChangesAsync(ct);

        return await GetAccountAsync(account.Id, ct);
    }

    public async Task<Result<bool>> DeleteAccountAsync(Guid id, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var account = await _db.FinanceAccounts
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId, ct);

        if (account is null)
            return Result<bool>.Failure("Compte introuvable.");

        _db.FinanceAccounts.Remove(account);
        await _db.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    // ===== TRANSACTIONS =====

    public async Task<Result<FinanceTransactionResponse>> RecordTransactionAsync(
        CreateFinanceTransactionRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var account = await _db.FinanceAccounts
            .FirstOrDefaultAsync(a => a.Id == request.AccountId && a.UserId == userId, ct);

        if (account is null)
            return Result<FinanceTransactionResponse>.Failure("Compte introuvable.");

        var transaction = new FinanceTransaction
        {
            FinanceAccountId = request.AccountId,
            TransactionType = request.TransactionType,
            Category = request.Category?.Trim() ?? string.Empty,
            Amount = request.Amount,
            Description = request.Description?.Trim() ?? string.Empty,
            TransactionDate = request.TransactionDate,
            Status = "Completed"
        };

        // Mettre à jour le solde du compte
        if (request.TransactionType == "Income")
            account.CurrentBalance += request.Amount;
        else if (request.TransactionType == "Expense")
            account.CurrentBalance -= request.Amount;

        _db.FinanceTransactions.Add(transaction);
        await _db.SaveChangesAsync(ct);

        return Result<FinanceTransactionResponse>.Success(new FinanceTransactionResponse(
            transaction.Id,
            transaction.FinanceAccountId,
            transaction.TransactionType,
            transaction.Category,
            transaction.Amount,
            transaction.Description,
            transaction.TransactionDate,
            transaction.Status,
            transaction.CreatedAt
        ));
    }

    // ===== BUDGETS =====

    public async Task<Result<IEnumerable<BudgetResponse>>> ListBudgetsAsync(CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var budgets = await _db.FinanceBudgets
            .Where(b => b.FinanceAccount!.UserId == userId)
            .AsNoTracking()
            .OrderByDescending(b => b.StartDate)
            .Select(b => MapBudget(b))
            .ToListAsync(ct);

        return Result<IEnumerable<BudgetResponse>>.Success(budgets);
    }

    public async Task<Result<BudgetResponse>> CreateBudgetAsync(
        CreateBudgetRequest request,
        CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var account = await _db.FinanceAccounts
            .FirstOrDefaultAsync(a => a.Id == request.AccountId && a.UserId == userId, ct);

        if (account is null)
            return Result<BudgetResponse>.Failure("Compte introuvable.");

        if (request.EndDate <= request.StartDate)
            return Result<BudgetResponse>.Failure(
                "La date de fin doit être après la date de début.");

        var budget = new FinanceBudget
        {
            FinanceAccountId = request.AccountId,
            BudgetName = request.BudgetName.Trim(),
            Category = request.Category?.Trim() ?? string.Empty,
            PlannedAmount = request.PlannedAmount,
            SpentAmount = 0,
            Period = request.Period,
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            Status = "Active"
        };

        _db.FinanceBudgets.Add(budget);
        await _db.SaveChangesAsync(ct);

        return Result<BudgetResponse>.Success(MapBudget(budget));
    }

    // ===== ANALYTICS =====

    public async Task<Result<decimal>> GetMonthlyRevenueAsync(int year, int month, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var revenue = await _db.FinanceTransactions
            .Where(t => t.FinanceAccount!.UserId == userId &&
                       t.TransactionType == "Income" &&
                       t.TransactionDate.Year == year &&
                       t.TransactionDate.Month == month)
            .AsNoTracking()
            .SumAsync(t => t.Amount, ct);

        return Result<decimal>.Success(revenue);
    }

    public async Task<Result<decimal>> GetMonthlyExpensesAsync(int year, int month, CancellationToken ct = default)
    {
        var userId = RequireUserId();

        var expenses = await _db.FinanceTransactions
            .Where(t => t.FinanceAccount!.UserId == userId &&
                       t.TransactionType == "Expense" &&
                       t.TransactionDate.Year == year &&
                       t.TransactionDate.Month == month)
            .AsNoTracking()
            .SumAsync(t => t.Amount, ct);

        return Result<decimal>.Success(expenses);
    }

    // ===== HELPERS =====

    private static FinanceAccountResponse MapAccount(FinanceAccount a) => new(
        a.Id,
        a.AccountName,
        a.Description,
        a.AccountType,
        a.CurrentBalance,
        a.Currency,
        a.Transactions?.Count ?? 0,
        a.CreatedAt,
        a.UpdatedAt
    );

    private static BudgetResponse MapBudget(FinanceBudget b) => new(
        b.Id,
        b.FinanceAccountId,
        b.BudgetName,
        b.Category,
        b.PlannedAmount,
        b.SpentAmount,
        b.RemainingAmount,
        b.PercentageUsed,
        b.Period,
        b.StartDate,
        b.EndDate,
        b.Status,
        b.CreatedAt
    );

    private Guid RequireUserId() =>
        _currentUser.UserId ?? throw new InvalidOperationException("Utilisateur non authentifié.");
}
