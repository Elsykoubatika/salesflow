using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Liberal.DTOs;

namespace SalesFlow.Application.Liberal.Services;

public interface ILiberalFinanceService
{
    // Accounts
    Task<Result<FinanceAccountListResponse>> ListAccountsAsync(
        int page = 1,
        int pageSize = 20,
        CancellationToken ct = default
    );

    Task<Result<FinanceAccountResponse>> GetAccountAsync(Guid id, CancellationToken ct = default);

    Task<Result<FinanceAccountResponse>> CreateAccountAsync(
        CreateFinanceAccountRequest request,
        CancellationToken ct = default
    );

    Task<Result<bool>> DeleteAccountAsync(Guid id, CancellationToken ct = default);

    // Transactions
    Task<Result<FinanceTransactionResponse>> RecordTransactionAsync(
        CreateFinanceTransactionRequest request,
        CancellationToken ct = default
    );

    // Budgets
    Task<Result<IEnumerable<BudgetResponse>>> ListBudgetsAsync(CancellationToken ct = default);

    Task<Result<BudgetResponse>> CreateBudgetAsync(
        CreateBudgetRequest request,
        CancellationToken ct = default
    );

    Task<Result<decimal>> GetMonthlyRevenueAsync(int year, int month, CancellationToken ct = default);

    Task<Result<decimal>> GetMonthlyExpensesAsync(int year, int month, CancellationToken ct = default);
}
