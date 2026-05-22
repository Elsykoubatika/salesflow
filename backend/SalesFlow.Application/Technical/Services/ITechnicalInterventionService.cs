using SalesFlow.Application.Common.Models;
using SalesFlow.Application.Technical.DTOs;

namespace SalesFlow.Application.Technical.Services;

public interface ITechnicalInterventionService
{
    Task<Result<TechnicalInterventionListResponse>> ListAsync(int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default);
    Task<Result<TechnicalInterventionResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Result<TechnicalInterventionResponse>> CreateAsync(CreateTechnicalInterventionRequest request, CancellationToken ct = default);
    Task<Result<TechnicalInterventionResponse>> UpdateAsync(Guid id, UpdateTechnicalInterventionRequest request, CancellationToken ct = default);
    Task<Result<TechnicalInterventionResponse>> CompleteAsync(Guid id, CancellationToken ct = default);
    Task<Result<TechnicalChecklistItemResponse>> AddChecklistItemAsync(Guid interventionId, string title, string task, CancellationToken ct = default);
    Task<Result<bool>> CompleteChecklistItemAsync(Guid checklistItemId, CancellationToken ct = default);
    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}