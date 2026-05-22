using System.ComponentModel.DataAnnotations;

public record CreateTechnicalInvoiceRequest(
    [Required] Guid ClientId,
    [Required] DateTime WorkStartDate,
    [Required] DateTime WorkEndDate,
    [Required, MaxLength(500)] string ServiceDescription,
    [Required, MaxLength(200)] string LocationOfWork,
    [Range(0, 999_999)] decimal HourlyRate,
    [Range(0, 10_000)] decimal ActualHours,
    [Range(0, 999_999_999)] decimal MaterialsCost = 0,
    [Range(0, 999_999_999)] decimal AdvancePayment = 0,
    Guid? TechnicalInterventionId = null,
    Guid? TechnicalQuoteId = null
);

public record TechnicalInvoiceResponse(
    Guid Id,
    string InvoiceNumber,
    Guid ClientId,
    string ClientName,
    DateTime InvoiceDate,
    DateTime DueDate,
    decimal HourlyRate,
    decimal ActualHours,
    decimal LaborCost,
    decimal MaterialsCost,
    decimal SubTotal,
    decimal TaxAmount,
    decimal AdvancePayment,
    decimal Total,
    decimal AmountDue,
    string Status,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record TechnicalInvoiceListResponse(
    IEnumerable<TechnicalInvoiceResponse> Items,
    int Total,
    int OverdueCount,
    int Page,
    int PageSize
);
