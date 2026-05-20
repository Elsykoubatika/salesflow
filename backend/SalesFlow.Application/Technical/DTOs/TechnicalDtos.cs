namespace SalesFlow.Application.Technical.DTOs;

public record TechnicalQuoteDto(
    string Id,
    string QuoteNumber,
    string Title,
    string ClientName,
    string Status,
    decimal MaterialsCost,
    decimal LaborCost,
    decimal Total,
    DateTime CreatedAt
);

public record CreateTechnicalQuoteRequest(
    string ClientId,
    string Title,
    string ServiceLocation,
    decimal EstimatedHours,
    decimal HourlyRate,
    List<TechnicalQuoteItemRequest> Items
);

public record TechnicalQuoteItemRequest(
    string ItemName,
    decimal Quantity,
    decimal UnitPrice,
    string Unit
);

public record TechnicalInterventionDto(
    string Id,
    string InterventionNumber,
    string Title,
    string ClientName,
    string Status,
    DateTime StartTime,
    DateTime? EndTime,
    decimal ActualHours,
    decimal TotalAmount
);

public record ProjectDto(
    string Id,
    string ProjectName,
    string ProjectType,
    string Status,
    DateTime StartDate,
    DateTime EndDate,
    decimal BudgetAmount,
    decimal TotalInvoiced,
    int TaskCount,
    int CompletedTasks
);

public record FinanceAccountDto(
    string Id,
    string AccountName,
    string AccountType,
    decimal CurrentBalance,
    int TransactionCount
);

public record FinanceTransactionDto(
    string Id,
    string Category,
    string TransactionType,
    decimal Amount,
    string Description,
    DateTime TransactionDate,
    string Status
);
