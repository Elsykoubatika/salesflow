using SalesFlow.Application.Common.Models;

namespace SalesFlow.Application.Technical.Services;

public interface ITechnicalMaintenanceService
{
    Task<Result<IEnumerable<MaintenancePlanResponse>>> ListPlansAsync(bool activeOnly = true, CancellationToken ct = default);
    Task<Result<MaintenancePlanResponse>> GetPlanByIdAsync(Guid id, CancellationToken ct = default);
    Task<Result<MaintenancePlanResponse>> CreatePlanAsync(CreateMaintenancePlanRequest request, CancellationToken ct = default);
    Task<Result<MaintenanceTaskResponse>> AddTaskAsync(Guid planId, string title, DateTime dueDate, decimal estimatedHours, CancellationToken ct = default);
    Task<Result<bool>> CompleteTaskAsync(Guid taskId, CancellationToken ct = default);
    Task<Result<bool>> DeletePlanAsync(Guid id, CancellationToken ct = default);
}