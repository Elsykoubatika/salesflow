using System.ComponentModel.DataAnnotations;

public record CreateMaintenancePlanRequest(
    [Required] Guid ClientId,
    [Required, MaxLength(150)] string PlanName,
    [Required, MaxLength(150)] string AssetName,
    [MaxLength(100)] string? AssetModel,
    [MaxLength(500)] string? Description,
    [Required] string Frequency,
    [Range(0, 999_999)] decimal EstimatedCost,
    [Range(0, 999)] double EstimatedDuration,
    [Required] DateTime NextScheduledDate
);

public record MaintenancePlanResponse(
    Guid Id,
    string PlanName,
    string AssetName,
    string? AssetModel,
    Guid ClientId,
    string ClientName,
    string Frequency,
    decimal EstimatedCost,
    string Status,
    DateTime NextScheduledDate,
    int TaskCount,
    DateTime CreatedAt
);

public record MaintenanceTaskResponse(
    Guid Id,
    Guid MaintenancePlanId,
    string Title,
    string Status,
    DateTime DueDate,
    decimal EstimatedHours,
    bool IsCompleted,
    DateTime? CompletedAt
);
