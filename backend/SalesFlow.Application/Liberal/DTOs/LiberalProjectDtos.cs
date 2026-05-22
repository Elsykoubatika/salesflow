using System.ComponentModel.DataAnnotations;

namespace SalesFlow.Application.Liberal.DTOs;

public record CreateLiberalProjectRequest(
    [Required] Guid ClientId,
    [Required, MaxLength(200)] string ProjectName,
    [MaxLength(1000)] string? Description,
    [MaxLength(100)] string? ProjectType,
    [Required] DateTime StartDate,
    [Required] DateTime EndDate,
    [Range(0, 999_999_999)] decimal BudgetAmount = 0,
    [Range(0, 100_000)] decimal EstimatedHours = 0,
    [Range(0, 999_999)] decimal HourlyRate = 0,
    [MaxLength(500)] string? Notes = null
);

public record UpdateLiberalProjectRequest(
    [Required, MaxLength(200)] string ProjectName,
    [MaxLength(1000)] string? Description,
    DateTime? EndDate,
    [Range(0, 999_999_999)] decimal BudgetAmount = 0,
    [Required] string Status = "Planning", // Planning, InProgress, Completed, Archived
    [MaxLength(500)] string? Notes = null
);

public record LiberalProjectResponse(
    Guid Id,
    string ProjectName,
    string? Description,
    string? ProjectType,
    Guid ClientId,
    string ClientName,
    DateTime StartDate,
    DateTime EndDate,
    decimal BudgetAmount,
    decimal EstimatedHours,
    decimal HourlyRate,
    decimal TotalInvoiced,
    int ProgressPercentage, // Calculé depuis les Deliverables
    string Status,
    string? Notes,
    int DeliverableCount,
    int CompletedDeliverables,
    DateTime CreatedAt,
    DateTime? UpdatedAt
);

public record LiberalProjectListResponse(
    IEnumerable<LiberalProjectResponse> Items,
    int Total,
    int ActiveCount,
    int Page,
    int PageSize
);

public record CreateDeliverableRequest(
    [Required] Guid ProjectId,
    [Required, MaxLength(200)] string Title,
    [MaxLength(500)] string? Description,
    [Required] DateTime DueDate
);

public record DeliverableResponse(
    Guid Id,
    Guid ProjectId,
    string Title,
    string? Description,
    DateTime DueDate,
    bool IsCompleted,
    DateTime? CompletedDate,
    int Order,
    DateTime CreatedAt
);
