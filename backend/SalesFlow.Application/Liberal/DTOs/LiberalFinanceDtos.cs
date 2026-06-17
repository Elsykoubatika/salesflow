using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Liberal.DTOs;

public record CreateFinanceAccountRequest(
    [Required, MaxLength(100)] string AccountName,
    [MaxLength(500)] string? Description,
    [Required] string AccountType, // Personal, Family, Business
    [Range(0, 999_999_999)] decimal OpeningBalance = 0 // Solde initial -> CurrentBalance
);

public record CreateFinanceTransactionRequest(
    [Required] Guid AccountId, // -> FinanceAccountId
    [Required] string TransactionType, // Income, Expense, Transfer
    [Range(0, 999_999_999)] decimal Amount,
    [MaxLength(100)] string? Category,
    [MaxLength(200)] string? Description,
    [Required] DateTime TransactionDate
);

public record CreateFinanceTransactionRequestBody(
    [Required] string TransactionType,
    [Range(0.01, 999_999_999)] decimal Amount,
    [MaxLength(100)] string? Category,
    [MaxLength(200)] string? Description,
    [Required] DateTime TransactionDate
);

public record CreateBudgetRequest(
    [Required] Guid AccountId, // -> FinanceAccountId
    [Required, MaxLength(100)] string BudgetName,
    [MaxLength(100)] string? Category,
    [Range(0, 999_999_999)] decimal PlannedAmount,
    [Required] string Period, // Weekly, Monthly, Yearly
    [Required] DateTime StartDate,
    [Required] DateTime EndDate
);

public record FinanceAccountResponse(
    Guid Id,
    string AccountName,
    string? Description,
    string AccountType,
    decimal CurrentBalance,
    string Currency,
    int TransactionCount,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record FinanceAccountListResponse(
    IEnumerable<FinanceAccountResponse> Items,
    int Total,
    decimal TotalBalance,
    int Page,
    int PageSize
);

public record FinanceTransactionResponse(
    Guid Id,
    Guid AccountId,
    string TransactionType,
    string? Category,
    decimal Amount,
    string? Description,
    DateTime TransactionDate,
    string Status,
    DateTime CreatedAt
);

public record BudgetResponse(
    Guid Id,
    Guid AccountId,
    string BudgetName,
    string? Category,
    decimal PlannedAmount,
    decimal SpentAmount,
    decimal RemainingAmount,
    decimal PercentageUsed,
    string Period,
    DateTime StartDate,
    DateTime EndDate,
    string Status,
    DateTime CreatedAt
);
