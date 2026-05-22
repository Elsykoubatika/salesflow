using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Liberal.DTOs;

public record CreateLiberalInvoiceRequest(
    [Required] Guid ContractId,
    [Required] DateTime ServiceStartDate,
    [Required] DateTime ServiceEndDate,
    [Range(0, 10_000)] decimal TotalHours,
    [Range(0.5, 5)] decimal ComplexityMultiplier = 1m,
    [Range(0, 999_999_999)] decimal AdvancePayment = 0,
    [MaxLength(500)] string? DeliverableDetails = null
);

public record UpdateLiberalInvoiceRequest(
    [Range(0, 10_000)] decimal TotalHours,
    [Range(0.5, 5)] decimal ComplexityMultiplier = 1m,
    [Range(0, 999_999_999)] decimal AdvancePayment = 0,
    [MaxLength(500)] string? DeliverableDetails = null
);

public record LiberalInvoiceResponse(
    Guid Id,
    string InvoiceNumber,
    Guid ContractId,
    string ContractName,
    Guid ClientId,
    string ClientName,
    DateTime InvoiceDate,
    DateTime DueDate,
    DateTime ServiceStartDate,
    DateTime ServiceEndDate,
    decimal TotalHours,
    decimal ComplexityMultiplier,
    decimal SubTotal,
    decimal TaxAmount,
    decimal AdvancePayment,
    decimal Total,
    string Status,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record LiberalInvoiceListResponse(
    IEnumerable<LiberalInvoiceResponse> Items,
    int Total,
    int OverdueCount,
    int Page,
    int PageSize
);
