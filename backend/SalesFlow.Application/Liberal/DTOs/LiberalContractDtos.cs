using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Liberal.DTOs;

public record CreateLiberalContractRequest(
    [Required] Guid ClientId,
    [Required, MaxLength(200)] string ContractName,
    [MaxLength(1000)] string? ServiceDescription,
    [Required] string PricingModel, // "Hourly", "Daily", "Project", "Retainer"
    [Range(0, 999_999_999)] decimal? Rate,
    [Required] DateTime StartDate,
    DateTime? EndDate,
    [Required] string EngagementType, // "Project", "Monthly", "Yearly", "Recurring"
    bool IsRecurring = false,
    string? RecurrencePattern = null,
    bool AutoRenew = false,
    [MaxLength(500)] string? Notes = null
);

public record UpdateLiberalContractRequest(
    [Required, MaxLength(200)] string ContractName,
    [MaxLength(1000)] string? ServiceDescription,
    [Required] string PricingModel,
    [Range(0, 999_999_999)] decimal? Rate,
    DateTime? StartDate,
    DateTime? EndDate,
    string? EngagementType,
    bool IsRecurring = false,
    string? RecurrencePattern = null,
    bool AutoRenew = false,
    [MaxLength(500)] string? Notes = null
);

public record LiberalContractResponse(
    Guid Id,
    string ContractNumber,
    string ContractName,
    string? ServiceDescription,
    Guid ClientId,
    string ClientName,
    string PricingModel,
    decimal? Rate,
    DateTime StartDate,
    DateTime? EndDate,
    string EngagementType,
    bool IsRecurring,
    string? RecurrencePattern,
    bool AutoRenew,
    string Status,
    DateTime? SignedDate,
    decimal TotalBilled,
    decimal TotalPaid,
    string? Notes,
    int InvoiceCount,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record LiberalContractListResponse(
    IEnumerable<LiberalContractResponse> Items,
    int Total,
    int ActiveCount,
    int Page,
    int PageSize
);

public record SignContractRequest(DateTime SignDate);

public record RenewContractRequest(
    [Required] string? RecurrencePattern,
    [Required] DateTime NextRenewalDate
);
