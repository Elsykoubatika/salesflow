using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Technical.DTOs;

public record CreateTechnicalInterventionRequest(
    [Required] Guid ClientId,
    [Required, MaxLength(200)] string Title,
    [Required, MaxLength(200)] string Location,
    [Required] DateTime StartTime,
    Guid? TechnicalQuoteId = null
);

public record UpdateTechnicalInterventionRequest(
    [Required, MaxLength(200)] string Title,
    [Required, MaxLength(200)] string Location,
    DateTime? EndTime = null,
    [MaxLength(1000)] string? Notes = null,
    [Range(0, 999_999_999)] decimal TotalAmount = 0
);

public record TechnicalInterventionResponse(
    Guid Id,
    string InterventionNumber,
    string Title,
    string Location,
    Guid ClientId,
    string ClientName,
    DateTime StartTime,
    DateTime? EndTime,
    decimal ActualHours,
    string Status,
    string? Notes,
    int ChecklistCount,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record TechnicalInterventionListResponse(
    IEnumerable<TechnicalInterventionResponse> Items,
    int Total,
    int InProgressCount,
    int Page,
    int PageSize
);

public record TechnicalChecklistItemResponse(
    Guid Id,
    string Title,
    bool IsCompleted,
    DateTime? CompletedAt,
    string Task
);
